# Renders the one-shot celebration animations as sprite sheets.
#
#   blender -b --factory-startup -P tool/blender/render_anims.py -- <repo_root> [name ...]
#
# Output: assets/anim/<name>.webp sprite sheets (a grid of square frames; the
# last frame is always empty) plus assets/anim/anims.json with each sheet's
# grid and frame rate, read by lib/ui/game/fx_art.dart. Run ONE Blender at a
# time: two GPU renders at once run the Metal device out of memory.
# Needs `cwebp` on PATH (brew install webp).
import bpy, sys, os, math, random, subprocess, zlib, struct, json
import numpy as np
from mathutils import Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import render_icons as R

ROOT, ONLY = R.ROOT, R.ONLY
COLS, ROWS, CELL, FPS = 6, 6, 320, 30
FRAMES = COLS * ROWS
TMP = os.path.join(bpy.app.tempdir, "anims")


def clamp01(x):
    return max(0.0, min(1.0, x))


def pop(t, start, grow=0.18, end=0.80, out=0.18):
    """0 -> overshoot -> 1, hold, -> 0. t in 0..1."""
    if t <= start or t >= end + out:
        return 0.0
    if t < start + grow:
        u = (t - start) / grow
        c = 1.70158 * 1.4
        return max(0.0, 1 + (c + 1) * (u - 1) ** 3 + c * (u - 1) ** 2)
    if t > end:
        u = (t - end) / out
        return max(0.0, 1 - u * u)
    return 1.0


class Actor:
    def __init__(self, ob, fn):
        self.ob, self.fn = ob, fn

    def apply(self, t):
        loc, rot, scale = self.fn(t)
        self.ob.location = loc
        self.ob.rotation_euler = rot
        s = max(scale, 0.0)
        self.ob.scale = (s, s, s)
        self.ob.hide_render = s < 1e-3


def holder(objs):
    bpy.ops.object.empty_add(location=(0, 0, 0))
    e = bpy.context.object
    for o in objs:
        o.parent = e
    return e


def mini_tile(color, edge):
    top = R.box(R.mat("t", color, 0.3, coat=0.5, sss=0.05), (0.62, 0.16, 0.62), (0, -0.03, 0), bevel=0.07)
    base = R.box(R.mat("e", edge, 0.4), (0.62, 0.14, 0.62), (0, 0.06, -0.03), bevel=0.07)
    return holder([top, base])


def spark(color, size=0.22):
    pts = []
    for i in range(8):
        r = size if i % 2 == 0 else size * 0.32
        a = math.radians(90 + i * 45)
        pts.append((r * math.cos(a), r * math.sin(a)))
    m = R.mat("spark", color, 0.2, coat=1.0)
    m.node_tree.nodes["Principled BSDF"].inputs["Emission Color"].default_value = (*color, 1)
    m.node_tree.nodes["Principled BSDF"].inputs["Emission Strength"].default_value = 1.2
    return holder([R.emblem("spark", R.fillet(pts, 0.012, 3), m, depth=0.02, puff=0.02)])


def ring(color):
    m = R.mat("ring", color, 0.25, coat=0.6)
    return R.prim("torus", m, major_radius=1.0, minor_radius=0.022, location=(0, 0, 0),
                  rotation=(math.radians(90), 0, 0), major_segments=96, minor_segments=12)


def burst(actors, make, n, rnd, start=0.06, speed=(1.5, 2.2), gravity=1.4, spin=5.0, y=0.5, life=0.75):
    for i in range(n):
        a = math.radians(i * 360 / n + rnd.uniform(-12, 12))
        v = rnd.uniform(*speed)
        sx, sy, sz = (rnd.uniform(-spin, spin) for _ in range(3))
        delay = start + rnd.uniform(0, 0.05)
        depth = y + rnd.uniform(-0.3, 0.3)
        size = rnd.uniform(0.75, 1.1)
        ob = make(i)

        def fn(t, a=a, v=v, sx=sx, sy=sy, sz=sz, delay=delay, depth=depth, size=size):
            u = clamp01((t - delay) / life)
            d = v * (1 - (1 - u) ** 2.2)            # fast out, easing
            x = math.cos(a) * d
            z = math.sin(a) * d + 0.35 * u - gravity * u * u * 0.6
            s = size * pop(t, delay, grow=0.10, end=delay + life * 0.62, out=life * 0.38)
            return (x, depth, z), (sx * u, sy * u, sz * u), s
        actors.append(Actor(ob, fn))


def ring_actor(actors, color, start, life=0.45, radius=2.0):
    ob = ring(color)

    def fn(t):
        u = clamp01((t - start) / life)
        if u <= 0 or u >= 1:
            return (0, 0.6, 0), (math.radians(90), 0, 0), 0.0
        return (0, 0.6, 0), (math.radians(90), 0, 0), 0.2 + radius * (1 - (1 - u) ** 2)
    a = Actor(ob, fn)
    # Thin out while expanding instead of fading.
    base = a.apply

    def apply(t):
        base(t)
        u = clamp01((t - start) / life)
        ob.scale.z = ob.scale.x * max(1 - u, 0.05)   # local Z = torus thickness axis
    a.apply = apply
    actors.append(a)


def sparkles(actors, rnd, n, color, radius=(0.9, 1.9), window=(0.15, 0.7)):
    for i in range(n):
        a = rnd.uniform(0, 2 * math.pi)
        r = rnd.uniform(*radius)
        t0 = rnd.uniform(*window)
        size = rnd.uniform(0.6, 1.3)
        ob = spark(color)

        def fn(t, a=a, r=r, t0=t0, size=size):
            u = (t - t0) / 0.22
            s = math.sin(math.pi * u) * size if 0 < u < 1 else 0.0
            return (math.cos(a) * r, -0.4, math.sin(a) * r), (0, u * 1.5, 0), s
        actors.append(Actor(ob, fn))


def scene_board_clear(sc):
    R.studio(sc, 5.4, tilt=6)
    rnd = random.Random(11)
    actors = []
    palette = [(R.IVORY, R.CREAM), (R.MINT, R.TEAL), (R.IVORY, R.CREAM), (R.TEAL, (0.01, 0.2, 0.19))]
    burst(actors, lambda i: mini_tile(*palette[i % len(palette)]), 14, rnd)
    ring_actor(actors, R.MINT, 0.05)
    ring_actor(actors, R.GOLD_LIGHT, 0.16, radius=1.6)
    sparkles(actors, rnd, 10, R.GOLD_LIGHT)
    return actors


def scene_new_record(sc):
    R.studio(sc, 4.6, tilt=6)
    rnd = random.Random(5)
    actors = []
    gold = R.mat("gold", R.GOLD, 0.25, coat=0.8)
    pts = [(-0.82, -0.55), (0.82, -0.55), (1.0, 0.50), (0.48, 0.02), (0.0, 0.82), (-0.48, 0.02), (-1.0, 0.50)]
    parts = [R.emblem("crown", R.fillet(pts, 0.09), gold, depth=0.14, puff=0.11),
             R.box(R.mat("gold2", R.GOLD_LIGHT, 0.25, coat=0.8), (1.90, 0.46, 0.34), (0, 0, -0.60), bevel=0.13)]
    for x, z in ((1.0, 0.56), (0.0, 0.90), (-1.0, 0.56)):
        parts.append(R.prim("uv_sphere", gold, radius=0.16, location=(x, 0, z)))
    gem = R.mat("gem", R.MINT, 0.12, coat=1.0)
    for x in (-0.55, 0.0, 0.55):
        parts.append(R.prim("uv_sphere", gem, radius=0.15, location=(x, -0.20, -0.60)))
    crown = holder(parts)

    def crown_fn(t):
        s = pop(t, 0.10, grow=0.22, end=0.82, out=0.14) * 1.05
        wob = math.sin(t * 14) * 0.10 * (1 - clamp01((t - 0.1) / 0.5))
        return (0, 0, 0.05 + 0.08 * math.sin(t * math.pi)), (0, wob, math.radians(-8) + wob), s
    actors.append(Actor(crown, crown_fn))

    def star(i):
        s = R.emblem("star", R.fillet(R.star_points(0.26, 0.125), 0.04, 4),
                     R.mat("sg", R.GOLD_LIGHT if i % 2 else R.MINT, 0.25, coat=0.8), depth=0.04, puff=0.04)
        return holder([s])
    burst(actors, star, 12, rnd, start=0.12, speed=(1.6, 2.2), gravity=1.0, spin=3.0, y=0.6, life=0.7)
    ring_actor(actors, R.GOLD_LIGHT, 0.10, radius=1.75)
    sparkles(actors, rnd, 8, R.IVORY)
    return actors


def scene_level_up(sc):
    R.studio(sc, 4.6, tilt=6)
    rnd = random.Random(3)
    actors = []
    big = holder([R.emblem("star", R.fillet(R.star_points(1.05, 0.50), 0.16),
                           R.mat("gold", R.GOLD, 0.25, coat=0.8), depth=0.16, puff=0.14)])

    def big_fn(t):
        s = pop(t, 0.08, grow=0.24, end=0.82, out=0.14)
        turn = (1 - clamp01((t - 0.08) / 0.34)) ** 2 * math.pi * 1.5
        return (0, 0, 0.1 * math.sin(t * math.pi)), (0, turn, math.radians(-8)), s
    actors.append(Actor(big, big_fn))
    # Rising chevrons on both sides.
    chev = [(-0.34, -0.20), (0.0, 0.14), (0.34, -0.20), (0.34, -0.02), (0.0, 0.32), (-0.34, -0.02)]
    for i, (x, delay) in enumerate(((-1.55, 0.18), (1.55, 0.24), (-1.55, 0.36), (1.55, 0.42))):
        ob = holder([R.emblem("chev", R.fillet(chev, 0.05, 4), R.mat("mint", R.MINT, 0.25, coat=0.8), depth=0.05, puff=0.05)])

        def fn(t, x=x, delay=delay):
            u = clamp01((t - delay) / 0.4)
            s = math.sin(math.pi * u) ** 0.6 if 0 < u < 1 else 0.0
            return (x, 0.2, -0.9 + 1.9 * u), (0, 0, 0), s
        actors.append(Actor(ob, fn))
    ring_actor(actors, R.MINT, 0.08, radius=1.75)
    sparkles(actors, rnd, 10, R.GOLD_LIGHT)
    return actors


def write_png(path, rgba):
    a = (np.clip(rgba, 0, 1) * 255 + 0.5).astype(np.uint8)
    h, w, _ = a.shape
    raw = b"".join(b"\x00" + a[y].tobytes() for y in range(h))
    ch = lambda t, d: struct.pack(">I", len(d)) + t + d + struct.pack(">I", zlib.crc32(t + d) & 0xFFFFFFFF)
    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n" + ch(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0))
                + ch(b"IDAT", zlib.compress(raw, 6)) + ch(b"IEND", b""))


def read_png(path):
    img = bpy.data.images.load(path)
    img.colorspace_settings.name = 'Non-Color'
    w, h = img.size
    px = np.array(img.pixels[:], dtype=np.float32).reshape(h, w, 4)[::-1]
    bpy.data.images.remove(img)
    return px


# ---------------------------------------------------------------- board fx
# Small sheets drawn inside the board painter (lib/ui/game/fx_art.dart). The
# camera looks straight at the XZ plane, which reads as top-down on the board.

SHARD = (0.95, 0.90, 0.78)
SHARD_EDGE = (0.80, 0.70, 0.52)


def scene_tile_pop(sc):
    """A letter tile bursting into chunky shards. Frame = 2.6 x the tile."""
    R.studio(sc, 4.6, tilt=0)
    rnd = random.Random(4)
    actors = []

    def shard(i):
        w = rnd.uniform(0.34, 0.58)
        h = w * rnd.uniform(0.7, 1.0)
        top = R.box(R.mat("t", SHARD, 0.35, coat=0.4), (w, 0.16, h), (0, -0.03, 0), bevel=0.06)
        base = R.box(R.mat("e", SHARD_EDGE, 0.45), (w, 0.14, h), (0, 0.06, -0.03), bevel=0.06)
        return holder([top, base])
    burst(actors, shard, 9, rnd, start=-0.04, speed=(0.9, 1.7), gravity=0.6, spin=4.0, y=0.4, life=0.98)
    sparkles(actors, rnd, 5, R.GOLD_LIGHT, radius=(0.5, 1.6), window=(0.05, 0.6))
    return actors


def scene_hammer(sc):
    """Mallet swings in from the upper right and strikes the centre. Frame = 3.2 x the tile."""
    R.studio(sc, 5.12, tilt=0)
    rnd = random.Random(6)
    actors = []
    cream = R.mat("cream", R.CREAM, 0.32, coat=0.6, sss=0.1)
    teal = R.mat("teal", R.TEAL, 0.25, coat=0.8)
    length = 2.05
    parts = [
        R.prim("cylinder", teal, radius=0.11, depth=length, location=(length / 2, 0, 0), rotation=(0, math.radians(90), 0)),
        R.prim("uv_sphere", teal, radius=0.15, location=(0, 0, 0)),
        R.prim("cylinder", cream, radius=0.42, depth=0.96, location=(length, 0, 0), vertices=64),
    ]
    for z in (-0.40, 0.40):
        parts.append(R.prim("torus", teal, major_radius=0.42, minor_radius=0.055, location=(length, 0, z),
                            major_segments=64, minor_segments=16))
    hammer = holder(parts)
    pivot = (1.5, -1.4)
    hit = math.radians(137)
    raised = hit - math.radians(62)
    hit_t = 0.35

    def fn(t):
        if t < hit_t:
            ang = raised + (hit - raised) * ((t / hit_t) ** 2.2)
        elif t < 0.55:
            ang = hit - math.radians(22) * math.sin((t - hit_t) / 0.2 * math.pi / 2)
        else:
            ang = hit - math.radians(22)
        return (pivot[0], 0, pivot[1]), (0, -ang, 0), pop(t, -0.04, grow=0.12, end=0.62, out=0.2)
    actors.append(Actor(hammer, fn))
    burst(actors, lambda i: spark(R.GOLD_LIGHT, 0.2), 8, rnd, start=hit_t, speed=(1.0, 1.6), gravity=0.3,
          spin=2.0, y=-0.6, life=0.5)
    ring_actor(actors, R.GOLD_LIGHT, hit_t, life=0.35, radius=1.5)
    return actors


def scene_joker(sc):
    """Four-point star pops and turns, with a ring and sparkles."""
    R.studio(sc, 4.6, tilt=0)
    rnd = random.Random(9)
    actors = []
    pts = []
    for i in range(8):
        r = 1.0 if i % 2 == 0 else 0.36
        a = math.radians(90 + i * 45)
        pts.append((r * math.cos(a), r * math.sin(a)))
    star = holder([R.emblem("star4", R.fillet(pts, 0.07), R.mat("mint", R.MINT, 0.2, coat=1.0), depth=0.12, puff=0.12)])

    def fn(t):
        turn = (1 - clamp01(t / 0.5)) ** 2 * math.pi
        return (0, 0, 0), (0, turn, 0), pop(t, -0.03, grow=0.22, end=0.58, out=0.3) * 0.95
    actors.append(Actor(star, fn))
    ring_actor(actors, R.MINT, 0.05, life=0.5, radius=1.7)
    sparkles(actors, rnd, 7, R.GOLD_LIGHT, radius=(0.9, 1.9), window=(0.1, 0.65))
    return actors


def scene_combo_burst(sc):
    """Radial rays and stars; the centre stays clear for the multiplier numeral."""
    R.studio(sc, 4.6, tilt=0)
    rnd = random.Random(12)
    actors = []
    gold = R.mat("gold", R.GOLD, 0.25, coat=0.8)
    n = 12
    for i in range(n):
        a = math.radians(i * 360 / n)
        long = 0.55 if i % 2 == 0 else 0.36
        ray = holder([R.emblem("ray", R.fillet([(0, 0.10), (long, 0), (0, -0.10), (-long, 0)], 0.03, 3), gold,
                               depth=0.04, puff=0.04)])

        def fn(t, a=a, i=i):
            u = clamp01((t - 0.02 - (i % 2) * 0.04) / 0.62)
            d = 0.95 + 0.95 * (1 - (1 - u) ** 2.5)
            s = math.sin(math.pi * u) ** 0.6 if 0 < u < 1 else 0.0
            return (math.cos(a) * d, 0.2, math.sin(a) * d), (0, -a, 0), s
        actors.append(Actor(ray, fn))

    def star(i):
        return holder([R.emblem("star", R.fillet(R.star_points(0.22, 0.105), 0.035, 4),
                                R.mat("sg", R.GOLD_LIGHT if i % 2 else R.MINT, 0.25, coat=0.8), depth=0.04, puff=0.04)])
    burst(actors, star, 8, rnd, start=0.05, speed=(1.5, 2.0), gravity=0.8, spin=3.0, y=-0.3, life=0.78)
    ring_actor(actors, R.GOLD_LIGHT, 0.0, life=0.45, radius=1.9)
    return actors


def arc_arrow(material, start_deg, end_deg, radius=1.0, tube=0.13):
    cu = bpy.data.curves.new("arc", 'CURVE')
    cu.dimensions = '3D'
    cu.bevel_depth = tube
    cu.bevel_resolution = 8
    cu.use_fill_caps = True
    sp = cu.splines.new('POLY')
    steps = 32
    sp.points.add(steps)
    for k in range(steps + 1):
        a = math.radians(start_deg + (end_deg - start_deg) * k / steps)
        sp.points[k].co = (radius * math.cos(a), 0, radius * math.sin(a), 1)
    cu.materials.append(material)
    arc = bpy.data.objects.new("arc", cu)
    bpy.context.collection.objects.link(arc)
    a = math.radians(end_deg)
    tangent = Vector((-math.sin(a), 0, math.cos(a)))
    depth = tube * 4.4
    tip = Vector((radius * math.cos(a), 0, radius * math.sin(a))) + tangent * (depth * 0.35)
    head = R.prim("cone", material, radius1=tube * 2.5, radius2=0, depth=depth, location=tuple(tip), vertices=48)
    head.rotation_euler = Vector((0, 0, 1)).rotation_difference(tangent).to_euler()
    return [arc, head]


def scene_refresh(sc):
    """Two arrows chasing each other through a full turn (played over the hand tray)."""
    R.studio(sc, 3.4, tilt=0)
    rnd = random.Random(15)
    actors = []
    parts = arc_arrow(R.mat("mint", R.MINT, 0.22, coat=0.9), 25, 150) + arc_arrow(R.mat("cream", R.CREAM, 0.3, coat=0.6), 205, 330)
    arrows = holder(parts)

    def fn(t):
        u = clamp01((t - 0.03) / 0.8)
        ease = u * u * (3 - 2 * u)
        return (0, 0, 0), (0, 2 * math.pi * ease, 0), pop(t, 0.0, grow=0.2, end=0.72, out=0.22) * 0.95
    actors.append(Actor(arrows, fn))
    sparkles(actors, rnd, 6, R.GOLD_LIGHT, radius=(0.3, 1.4), window=(0.25, 0.75))
    return actors


def scene_gift_open(sc):
    """Reward: the box pops in, the lid flies off, stars pour out."""
    R.studio(sc, 3.9, tilt=24, target=(0, 0, 0.35))
    rnd = random.Random(31)
    actors = []
    cream = R.mat("cream", R.IVORY, 0.35, coat=0.5, sss=0.1)
    teal = R.mat("teal", R.TEAL, 0.25, coat=0.8)
    base = holder([
        R.box(cream, (1.30, 1.30, 0.95), (0, 0, -0.42), bevel=0.09),
        R.box(teal, (0.30, 1.34, 0.99), (0, 0, -0.42), bevel=0.05),
        R.box(teal, (1.34, 0.30, 0.99), (0, 0, -0.42), bevel=0.05),
    ])
    tie = [(-0.62, 0.30), (-0.10, 0.07), (0.10, 0.07), (0.62, 0.30), (0.62, -0.30), (0.10, -0.07), (-0.10, -0.07), (-0.62, -0.30)]
    bow = R.emblem("bow", R.fillet(tie, 0.10), teal, depth=0.07, puff=0.09)
    bow.location = (0, 0, 0.57)
    bow.rotation_euler = (math.radians(90), 0, math.radians(-32))
    lid = holder([
        R.box(cream, (1.46, 1.46, 0.30), (0, 0, 0.20), bevel=0.08),
        R.box(teal, (0.31, 1.48, 0.32), (0, 0, 0.20), bevel=0.05),
        R.box(teal, (1.48, 0.31, 0.32), (0, 0, 0.20), bevel=0.05),
        bow,
        R.prim("uv_sphere", teal, radius=0.25, location=(0, 0, 0.57)),
    ])
    root = holder([base, lid])
    turn = math.radians(32)

    def root_fn(t):
        hop = 0.10 * math.sin(clamp01(t / 0.3) * math.pi)
        return (0, 0, -0.15 + hop), (0, 0, turn), pop(t, 0.0, grow=0.16, end=0.84, out=0.14)
    actors.append(Actor(root, root_fn))

    def lid_fn(t):
        u = clamp01((t - 0.30) / 0.30)
        e = 1 - (1 - u) ** 2.4
        return (0, 0.30 * e, 1.05 * e), (math.radians(-46) * e, 0, 0), 1.0
    actors.append(Actor(lid, lid_fn))

    def star(i):
        return holder([R.emblem("star", R.fillet(R.star_points(0.24, 0.115), 0.04, 4),
                                R.mat("sg", R.GOLD_LIGHT if i % 2 else R.MINT, 0.25, coat=0.8), depth=0.04, puff=0.04)])
    burst(actors, star, 9, rnd, start=0.34, speed=(1.0, 1.7), gravity=-1.1, spin=3.0, y=-0.9, life=0.55)
    sparkles(actors, rnd, 8, R.GOLD_LIGHT, radius=(0.7, 1.7), window=(0.36, 0.80))
    return actors


def scene_sparkle_burst(sc):
    """Generic flourish behind a reward (medal, unlock): ring, stars, sparkles; empty centre."""
    R.studio(sc, 4.6, tilt=0)
    rnd = random.Random(21)
    actors = []

    def star(i):
        return holder([R.emblem("star", R.fillet(R.star_points(0.24, 0.115), 0.04, 4),
                                R.mat("sg", R.GOLD_LIGHT if i % 2 else R.MINT, 0.25, coat=0.8), depth=0.04, puff=0.04)])
    burst(actors, star, 12, rnd, start=0.02, speed=(1.5, 2.1), gravity=0.7, spin=3.0, y=0.4, life=0.82)
    ring_actor(actors, R.GOLD_LIGHT, 0.0, life=0.5, radius=1.9)
    ring_actor(actors, R.MINT, 0.14, life=0.5, radius=1.5)
    sparkles(actors, rnd, 10, R.GOLD_LIGHT, radius=(1.0, 2.0), window=(0.1, 0.72))
    return actors


def scene_flame_loop(sc):
    """Seamless one-second flicker for the streak flame (t wraps around)."""
    R.studio(sc, 2.5)
    actors = []
    two_pi = 2 * math.pi
    outer = holder([R.emblem("flame", R.FLAME_OUTLINE, R.mat("flame", R.FLAME, 0.3, coat=0.7), depth=0.16, puff=0.13,
                             smooth=True)])
    inner = holder([R.emblem("inner", R.FLAME_INNER, R.mat("flame_in", R.FLAME_IN, 0.3, coat=0.7), depth=0.10,
                             puff=0.08, y=-0.22, smooth=True)])

    def outer_fn(t):
        return ((0.02 * math.sin(two_pi * t), 0, -0.04 + 0.02 * math.sin(two_pi * 2 * t)),
                (0, math.radians(4.5) * math.sin(two_pi * t), math.radians(-8)),
                0.84 * (1 + 0.035 * math.sin(two_pi * 2 * t + 0.6)))
    actors.append(Actor(outer, outer_fn))

    def inner_fn(t):
        return ((0.03 * math.sin(two_pi * t + 1.4), 0, -0.04 + 0.05 * math.sin(two_pi * 2 * t + 2.0)),
                (0, math.radians(-7) * math.sin(two_pi * t + 0.9), math.radians(-8)),
                0.84 * (1 + 0.07 * math.sin(two_pi * 3 * t)))
    actors.append(Actor(inner, inner_fn))
    # Embers drifting up; each one's own phase keeps the loop seamless.
    for i, (x, phase) in enumerate(((-0.45, 0.0), (0.38, 0.37), (-0.05, 0.68))):
        ember = spark(R.FLAME_IN, 0.12)

        def fn(t, x=x, phase=phase):
            u = (t + phase) % 1.0
            return (x + 0.12 * math.sin(two_pi * u), -0.3, 0.25 + 0.85 * u), (0, u * 2.0, 0), math.sin(math.pi * u) ** 0.8
        actors.append(Actor(ember, fn))
    return actors


def combo_numeral(body):
    def build(sc):
        R.studio(sc, 2.3, tilt=0)
        back = R.text(body, 1.35, R.mat("back", (0.01, 0.20, 0.19), 0.3, coat=0.6), (0.06, 0.14, -0.07), extrude=0.10)
        front = R.text(body, 1.35, R.mat("gold", R.GOLD, 0.22, coat=0.9), (0, 0, 0), extrude=0.06)
        R.group([back, front], rot_z=-9)
        return []
    return build


# name -> (builder, cols, rows, cell px, fps, first frame empty?)
SHEETS = {
    "board_clear": (scene_board_clear, 6, 6, 320, 30, True),
    "new_record": (scene_new_record, 6, 6, 320, 30, True),
    "level_up": (scene_level_up, 6, 6, 320, 30, True),
    "tile_pop": (scene_tile_pop, 4, 4, 192, 30, False),
    "hammer": (scene_hammer, 5, 4, 256, 30, False),
    "joker": (scene_joker, 4, 4, 192, 30, False),
    "combo_burst": (scene_combo_burst, 5, 4, 256, 30, False),
    "refresh": (scene_refresh, 5, 4, 256, 30, True),
    "gift_open": (scene_gift_open, 6, 5, 256, 30, True),
    "sparkle_burst": (scene_sparkle_burst, 5, 5, 256, 30, False),
    # Loops: every frame is drawn and time wraps (no empty frame).
    "flame_loop": (scene_flame_loop, 6, 4, 160, 24, False, True),
}
# name -> (list of still builders, cell px): one frame per builder, laid out in a row.
ATLASES = {
    "combo_nums": ([combo_numeral(t) for t in ("×2", "×3", "×4", "×5")], 256),
}


def to_webp(png, name, quality=86):
    out = os.path.join(ROOT, "assets/anim", f"{name}.webp")
    subprocess.run(["cwebp", "-quiet", "-q", str(quality), "-alpha_q", "92", "-m", "6", png, "-o", out], check=True)
    return out


def save_meta(name, cols, rows, fps):
    path = os.path.join(ROOT, "assets/anim/anims.json")
    meta = json.load(open(path)) if os.path.exists(path) else {}
    meta[name] = {"cols": cols, "rows": rows, "fps": fps}
    with open(path, "w") as f:
        json.dump(meta, f, indent=2, sort_keys=True)
        f.write("\n")


def render_sheet(name, build, cols, rows, cell, fps, first_empty, loop=False):
    frames = cols * rows
    sc = R.reset()
    sc.cycles.samples = 48
    sc.render.resolution_x = sc.render.resolution_y = cell
    actors = build(sc)
    # Bake the procedural motion to keyframes and render as one animation:
    # a single render session keeps the GPU kernels loaded between frames.
    for f in range(frames):
        t = f / frames if loop else f / (frames - 1)
        for a in actors:
            a.apply(t)
            for prop in ("location", "rotation_euler", "scale", "hide_render"):
                a.ob.keyframe_insert(prop, frame=f + 1)
    sc.frame_start, sc.frame_end = 1, frames
    sc.render.use_persistent_data = True
    sc.render.filepath = os.path.join(TMP, f"{name}_")
    bpy.ops.render.render(animation=True)
    sheet = np.zeros((rows * cell, cols * cell, 4), dtype=np.float32)
    # One-shots leave the last frame empty by contract; loops use every frame.
    for f in range(1 if first_empty else 0, frames if loop else frames - 1):
        r, c = divmod(f, cols)
        sheet[r * cell:(r + 1) * cell, c * cell:(c + 1) * cell] = read_png(os.path.join(TMP, f"{name}_{f + 1:04d}.png"))
    png = os.path.join(TMP, f"{name}.png")
    write_png(png, sheet)
    to_webp(png, name)
    save_meta(name, cols, rows, fps)
    print("WROTE", name, png)


def render_atlas(name, builders, cell):
    sheet = np.zeros((cell, cell * len(builders), 4), dtype=np.float32)
    for i, build in enumerate(builders):
        sc = R.reset()
        sc.cycles.samples = 128
        sc.render.resolution_x = sc.render.resolution_y = cell
        build(sc)
        path = os.path.join(TMP, f"{name}_{i}.png")
        sc.render.filepath = path
        bpy.ops.render.render(write_still=True)
        sheet[:, i * cell:(i + 1) * cell] = read_png(path)
    png = os.path.join(TMP, f"{name}.png")
    write_png(png, sheet)
    to_webp(png, name, quality=92)
    save_meta(name, len(builders), 1, 0)
    print("WROTE", name, png)


def main():
    os.makedirs(TMP, exist_ok=True)
    os.makedirs(os.path.join(ROOT, "assets/anim"), exist_ok=True)
    for name, spec in SHEETS.items():
        if ONLY and name not in ONLY:
            continue
        render_sheet(name, *spec)
    for name, (builders, cell) in ATLASES.items():
        if ONLY and name not in ONLY:
            continue
        render_atlas(name, builders, cell)
    print("DONE")


if __name__ == "__main__":
    main()
