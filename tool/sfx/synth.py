"""Harftaş ses efektleri — tamamen prosedürel sentez (lisans gerektirmez).

Çalıştırma:
    python3 -m venv .venv && .venv/bin/pip install numpy scipy
    .venv/bin/python tool/sfx/synth.py out_dir      # WAV üretir
    tool/sfx/build.sh                               # WAV -> assets/audio/*.ogg

Ses dili ("taş + cam + parıltı"):
  * Gövde: taş/seramik tıkırtısı — uyumsuz (inharmonik) mod oranlarıyla sönümlü sinüsler.
  * Ödül: cam-marimba tınısı — çubuk mod oranları (1 : 3.93 : 9.54) ile hızlı sönüm.
  * Parıltı: yüksek, kısa çanlar + hafif gürültü "ışıltısı".
Hepsi Do majör pentatonik (C D E G A); kombo/seri yükseldikçe nota yükselir.
Sık çalan sesler (pick, drop, button) için _2.._4 varyasyonları üretilir.
"""

import os
import sys

import numpy as np
from scipy.io import wavfile
from scipy.signal import butter, sosfilt

SR = 44100
RNG = np.random.default_rng(7)


# ------------------------------------------------------------------ helpers
def t_axis(dur):
    return np.arange(int(SR * dur)) / SR


def note(name):
    """'C5' -> Hz (A4 = 440)."""
    names = {'C': -9, 'D': -7, 'E': -5, 'F': -4, 'G': -2, 'A': 0, 'B': 2}
    semis = names[name[0]] + (1 if '#' in name else 0)
    octave = int(name[-1])
    return 440.0 * 2 ** ((semis + 12 * (octave - 4)) / 12)


def lp(x, hz, order=2):
    return sosfilt(butter(order, min(hz, SR / 2 - 100), 'low', fs=SR, output='sos'), x)


def hp(x, hz, order=2):
    return sosfilt(butter(order, hz, 'high', fs=SR, output='sos'), x)


def bp(x, lo, hi, order=2):
    return sosfilt(butter(order, [lo, min(hi, SR / 2 - 100)], 'band', fs=SR, output='sos'), x)


def mix(*xs):
    """Sum arrays of different lengths (zero-padded)."""
    out = np.zeros(max(len(x) for x in xs))
    for x in xs:
        out[: len(x)] += x
    return out


def place(buf, x, at):
    i = int(at * SR)
    end = min(len(buf), i + len(x))
    buf[i:end] += x[: end - i]
    return buf


def canvas(dur):
    return np.zeros(int(SR * dur))


def modal(f0, ratios, amps, decays, dur, jitter=0.0):
    """Sum of exponentially decaying sines (modal synthesis)."""
    t = t_axis(dur)
    out = np.zeros_like(t)
    for r, a, d in zip(ratios, amps, decays):
        f = f0 * r * (1 + jitter * RNG.uniform(-1, 1))
        ph = RNG.uniform(0, 2 * np.pi)
        out += a * np.sin(2 * np.pi * f * t + ph) * np.exp(-t / d)
    # 1.5 ms attack ramp to avoid clicks
    n = int(0.0015 * SR)
    out[:n] *= np.linspace(0, 1, n)
    return out


def noise_burst(dur, lo, hi, decay):
    t = t_axis(dur)
    return bp(RNG.standard_normal(len(t)), lo, hi) * np.exp(-t / decay)


# Instrument voices -------------------------------------------------------
STONE = ([1.0, 2.32, 4.25, 6.63], [1.0, 0.55, 0.30, 0.15])
MARIMBA = ([1.0, 3.93, 9.54], [1.0, 0.35, 0.12])
GLASS = ([1.0, 2.76, 5.40, 8.93], [1.0, 0.45, 0.22, 0.10])
BELL = ([1.0, 2.0, 2.76, 4.07, 5.43], [1.0, 0.6, 0.45, 0.25, 0.12])


def stone_tap(f0, dur=0.18, bright=1.0, decay=0.035):
    r, a = STONE
    x = modal(f0, r, a, [decay, decay * 0.6, decay * 0.4, decay * 0.3], dur, jitter=0.01)
    click = noise_burst(dur, 2500, 9000 * bright, 0.004) * 0.35
    return x + click


def marimba(f0, dur=0.7, decay=0.28):
    r, a = MARIMBA
    return modal(f0, r, a, [decay, decay * 0.25, decay * 0.08], dur)


def glass(f0, dur=0.9, decay=0.35):
    r, a = GLASS
    return modal(f0, r, a, [decay, decay * 0.5, decay * 0.3, decay * 0.2], dur)


def bell(f0, dur=1.2, decay=0.5):
    r, a = BELL
    return modal(f0, r, a, [decay, decay * 0.7, decay * 0.5, decay * 0.3, decay * 0.2], dur)


def sparkle(dur, density=40, lo='C7', hi='C8', level=0.12, start_decay=0.5):
    """Random high pentatonic pings fading out = "ışıltı"."""
    out = canvas(dur)
    pent = [n + str(o) for o in (6, 7, 8) for n in 'CDEGA']
    pool = [p for p in pent if note(lo) <= note(p) <= note(hi)]
    count = int(density * dur)
    for k in range(count):
        at = RNG.uniform(0, dur * 0.8)
        amp = level * np.exp(-at / (dur * start_decay)) * RNG.uniform(0.5, 1)
        place(out, glass(note(RNG.choice(pool)), dur=0.25, decay=0.06) * amp, at)
    return out


def whoosh(dur, f_from, f_to, level=0.5):
    """Filtered noise sweep (band moves from f_from to f_to)."""
    n = int(SR * dur)
    src = RNG.standard_normal(n)
    out = np.zeros(n)
    hop = 512
    for i in range(0, n, hop):
        frac = i / n
        fc = f_from * (f_to / f_from) ** frac
        seg = src[max(0, i - 2048): i + hop]
        y = bp(seg, fc * 0.7, fc * 1.4)[-min(hop, n - i):]
        out[i:i + len(y)] = y
    env = np.sin(np.pi * np.linspace(0, 1, n)) ** 1.5
    return out * env * level


def reverb(x, wet=0.18, size=0.9):
    """Small bright room: exponentially decaying filtered noise IR."""
    n = int(SR * size)
    t = np.arange(n) / SR
    ir = RNG.standard_normal(n) * np.exp(-t / (size / 5))
    ir = lp(hp(ir, 300), 7000)
    ir[: int(0.008 * SR)] = 0  # predelay
    ir /= np.sqrt(np.sum(ir ** 2))
    from scipy.signal import fftconvolve
    tail = fftconvolve(x, ir)
    y = np.zeros(len(x) + n)
    y[: len(x)] += x
    y[: len(tail)] += wet * tail[: len(y)]
    # trim trailing near-silence
    thr = np.max(np.abs(y)) * 10 ** (-48 / 20)
    idx = np.where(np.abs(y) > thr)[0]
    return y[: idx[-1] + 1] if len(idx) else y


def finish(x, peak_db=-1.0, fade_ms=12):
    x = x - np.mean(x)
    n = int(fade_ms / 1000 * SR)
    if 0 < n < len(x):
        x[-n:] *= np.linspace(1, 0, n) ** 2
    pk = np.max(np.abs(x)) or 1
    return x / pk * 10 ** (peak_db / 20)


# ------------------------------------------------------------------ sounds
def s_pick(v):
    f = [1250, 1330, 1180, 1400][v]
    x = stone_tap(f, dur=0.09, bright=1.2, decay=0.012) * 0.8
    x = mix(x, lp(noise_burst(0.09, 300, 2000, 0.01), 3000) * 0.3)
    return finish(reverb(x, 0.08, 0.4), -3)


def s_drop(v):
    f = [330, 352, 311, 370][v]
    body = lp(stone_tap(f, dur=0.25, decay=0.05, bright=0.6), 3500)
    thump = modal(f / 2.6, [1.0], [1.0], [0.035], 0.25) * 1.1
    tick = lp(stone_tap(f * 3.1, dur=0.06, decay=0.006), 6000) * 0.18
    return finish(reverb(mix(body, thump, tick), 0.10, 0.6), -1.5)


def s_invalid():
    out = canvas(0.36)
    for i, f in enumerate([210, 180]):
        x = lp(stone_tap(f, dur=0.16, decay=0.03, bright=0.5), 1200)
        place(out, x * (1 - 0.25 * i), i * 0.11)
    return finish(reverb(out, 0.08, 0.4), -3)


def s_button(v):
    f = [2100, 2250, 1980, 2350][v]
    x = modal(f, [1.0, 2.4], [1.0, 0.3], [0.010, 0.006], 0.06)
    x += noise_burst(0.06, 3000, 12000, 0.002) * 0.25
    return finish(x, -4)


def chord_arp(notes, gap, voice, dur, level=1.0, rev=0.2, sp=0.0):
    out = canvas(dur)
    for i, n in enumerate(notes):
        place(out, voice(note(n)) * level * (0.85 + 0.15 * (i == len(notes) - 1)), i * gap)
    if sp:
        place(out, sparkle(dur * 0.8, level=sp), gap * (len(notes) - 1))
    return finish(reverb(out, rev, 1.2))


def s_word_s():
    return chord_arp(['E5', 'G5'], 0.07, lambda f: mix(marimba(f, 0.6, 0.22), glass(f * 2, 0.5, 0.12) * 0.25), 0.8)


def s_word_m():
    return chord_arp(['C5', 'E5', 'G5'], 0.065, lambda f: mix(marimba(f, 0.7, 0.25), glass(f * 2, 0.6, 0.15) * 0.3), 1.0, sp=0.05)


def s_word_l():
    return chord_arp(['C5', 'E5', 'G5', 'C6'], 0.06, lambda f: mix(marimba(f, 0.8, 0.3), glass(f * 2, 0.7, 0.2) * 0.35), 1.3, sp=0.09)


def s_combo(level):
    roots = {1: ['G5', 'C6'], 2: ['A5', 'D6'], 3: ['C6', 'E6', 'G6']}[level]
    out = canvas(1.4)
    for i, n in enumerate(roots):
        place(out, mix(bell(note(n), 1.1, 0.35) * 0.7, glass(note(n), 0.8, 0.25) * 0.5), i * 0.05)
    place(out, sparkle(1.0, density=30 + 15 * level, level=0.08 + 0.03 * level), 0.03)
    place(out, whoosh(0.35, 1500, 6000, 0.12 * level), 0)
    return finish(reverb(out, 0.25, 1.4))


def s_streak_up():
    out = canvas(0.9)
    for i, n in enumerate(['C6', 'D6', 'E6', 'G6', 'A6']):
        place(out, glass(note(n), 0.5, 0.12) * (0.6 + 0.1 * i), i * 0.045)
    return finish(reverb(out, 0.22, 1.0))


def s_board_clear():
    out = canvas(2.4)
    place(out, whoosh(0.8, 300, 9000, 0.35), 0)
    seq = ['C5', 'E5', 'G5', 'C6', 'E6', 'G6', 'C7']
    for i, n in enumerate(seq):
        place(out, mix(marimba(note(n), 0.8, 0.3) * 0.6, bell(note(n), 1.0, 0.4) * 0.4), 0.05 + i * 0.06)
    for n in ['C5', 'E5', 'G5', 'C6']:
        place(out, bell(note(n), 1.8, 0.8) * 0.35, 0.5)
    place(out, sparkle(1.8, density=60, level=0.12), 0.45)
    return finish(reverb(out, 0.3, 1.8))


def s_new_record():
    out = canvas(2.4)
    stab = sum(bell(note(n), 1.6, 0.6) for n in ['C5', 'G5', 'E6']) / 2
    place(out, stab * 0.8, 0)
    for i, n in enumerate(['G5', 'C6', 'E6', 'G6', 'C7']):
        place(out, glass(note(n), 0.6, 0.18) * 0.6, 0.18 + i * 0.07)
    place(out, sum(bell(note(n), 1.6, 0.7) for n in ['C6', 'E6', 'G6']) / 2.4, 0.6)
    place(out, sparkle(1.6, density=55, level=0.12), 0.5)
    return finish(reverb(out, 0.3, 1.8))


def s_game_over():
    out = canvas(1.6)
    for i, n in enumerate(['G5', 'E5', 'C5']):
        place(out, marimba(note(n), 0.9, 0.35) * (0.9 - 0.1 * i), i * 0.16)
    place(out, sum(glass(note(n), 1.2, 0.5) for n in ['C4', 'G4', 'E5']) * 0.18, 0.32)
    return finish(reverb(out, 0.3, 1.6), -2)


def s_level_up():
    out = canvas(1.8)
    seq = ['C5', 'E5', 'G5', 'A5', 'C6', 'E6', 'G6', 'C7']
    for i, n in enumerate(seq):
        place(out, mix(glass(note(n), 0.6, 0.18) * 0.55, marimba(note(n), 0.5, 0.18) * 0.4), i * 0.05)
    place(out, sum(bell(note(n), 1.4, 0.6) for n in ['C6', 'G6', 'E7']) / 2.5, 0.42)
    place(out, sparkle(1.2, density=45, level=0.1), 0.4)
    return finish(reverb(out, 0.28, 1.6))


def s_mission_done():
    out = canvas(1.2)
    place(out, bell(note('E6'), 0.9, 0.35) * 0.8, 0)
    place(out, bell(note('A6'), 1.0, 0.45) * 0.8, 0.12)
    place(out, sparkle(0.7, density=25, level=0.07), 0.12)
    return finish(reverb(out, 0.25, 1.3))


def s_pu_refresh():
    out = canvas(0.8)
    place(out, whoosh(0.45, 600, 5000, 0.6), 0)
    for i in range(5):
        place(out, stone_tap(900 + 140 * i, 0.08, decay=0.01) * 0.35, 0.18 + i * 0.045)
    place(out, glass(note('G6'), 0.4, 0.1) * 0.4, 0.42)
    return finish(reverb(out, 0.18, 0.9))


def s_pu_joker():
    out = canvas(1.2)
    place(out, whoosh(0.6, 1500, 7000, 0.2), 0)
    place(out, lp(sparkle(0.9, density=45, lo='E6', hi='E7', level=0.12, start_decay=1.0), 9000), 0)
    place(out, bell(note('E6'), 1.0, 0.4) * 0.45 + bell(note('G6'), 1.0, 0.4) * 0.3, 0.32)
    return finish(reverb(out, 0.3, 1.4))


def s_pu_hammer():
    out = canvas(0.7)
    place(out, modal(85, [1.0, 1.6], [1.0, 0.4], [0.07, 0.04], 0.4), 0)
    place(out, stone_tap(240, 0.3, decay=0.06), 0)
    place(out, noise_burst(0.35, 800, 6000, 0.05) * 0.6, 0.005)
    for i in range(6):  # debris
        place(out, stone_tap(RNG.uniform(1500, 3200), 0.05, decay=0.006) * 0.2, 0.06 + RNG.uniform(0, 0.2))
    return finish(reverb(out, 0.12, 0.7), -1)


# ------------------------------------------------------------------ music
def s_music():
    """Calm 16-bar loop, 92 bpm: marimba arpeggios + soft pad + light pulse.
    Built so the tail of the last bar wraps into the first (seamless loop)."""
    bpm = 92
    beat = 60 / bpm
    bars = 16
    total = bars * 4 * beat
    n = int(total * SR)
    out = np.zeros(n + SR * 2)
    prog = [['C4', 'E4', 'G4', 'D5'], ['A3', 'C4', 'E4', 'G4'], ['F3', 'A3', 'C4', 'E4'], ['G3', 'B3', 'D4', 'A4']]
    pent = ['C5', 'D5', 'E5', 'G5', 'A5', 'C6', 'D6', 'E6']
    for bar in range(bars):
        chord = prog[bar % 4]
        t0 = bar * 4 * beat
        # pad: detuned sines with slow swell
        tt = t_axis(4 * beat + 1.0)
        pad = np.zeros_like(tt)
        for c in chord:
            f = note(c)
            for det in (-0.004, 0.004):
                pad += np.sin(2 * np.pi * f * (1 + det) * tt)
        env = np.minimum(1, tt / 1.2) * np.exp(-np.maximum(0, tt - 4 * beat) / 0.4)
        place(out, lp(pad * env, 1800) * 0.035, t0)
        # marimba arpeggio 8ths
        for k in range(8):
            if bar % 4 == 3 and k in (6, 7):
                continue
            nn = chord[(k * 3) % 4]
            f = note(nn) * (2 if k % 2 else 1)
            place(out, marimba(f, 0.7, 0.22) * (0.18 if k % 2 else 0.24), t0 + k * beat / 2)
        # occasional melody pings
        if bar % 2 == 1:
            for k in (0, 3, 5):
                place(out, glass(note(pent[(bar * 3 + k) % len(pent)]), 0.8, 0.25) * 0.1, t0 + k * beat / 2 + 2 * beat)
        # soft pulse (felt kick) on beats 1 and 3
        for b in (0, 2):
            place(out, modal(58, [1.0], [1.0], [0.12], 0.4) * 0.22, t0 + b * beat)
    out = reverb(out, 0.25, 2.0)
    # wrap tail into head for seamless loop
    head, tail = out[:n].copy(), out[n:]
    head[: len(tail)] += tail[: n]
    return finish(head, -3, fade_ms=0)


# ------------------------------------------------------------------ main
def main(out_dir):
    os.makedirs(out_dir, exist_ok=True)
    jobs = {
        'invalid': s_invalid,
        'word_s': s_word_s,
        'word_m': s_word_m,
        'word_l': s_word_l,
        'combo_1': lambda: s_combo(1),
        'combo_2': lambda: s_combo(2),
        'combo_3': lambda: s_combo(3),
        'streak_up': s_streak_up,
        'board_clear': s_board_clear,
        'new_record': s_new_record,
        'game_over': s_game_over,
        'level_up': s_level_up,
        'mission_done': s_mission_done,
        'pu_refresh': s_pu_refresh,
        'pu_joker': s_pu_joker,
        'pu_hammer': s_pu_hammer,
        'music_loop': s_music,
    }
    for base, fn in (('pick', s_pick), ('drop', s_drop), ('button', s_button)):
        for v in range(4):
            jobs[base if v == 0 else f'{base}_{v + 1}'] = (lambda fn=fn, v=v: fn(v))
    for name, fn in jobs.items():
        x = fn()
        wavfile.write(os.path.join(out_dir, name + '.wav'), SR, (x * 32767).astype(np.int16))
        print(f'{name:14s} {len(x) / SR:5.2f}s')


if __name__ == '__main__':
    main(sys.argv[1] if len(sys.argv) > 1 else 'build/sfx_wav')
