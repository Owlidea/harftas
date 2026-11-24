# Renders the one-shot celebration animations as sprite sheets.
#
#   blender -b --factory-startup -P tool/blender/render_anims.py -- <repo_root> [name ...]
#
# Output: assets/anim/{new_record,board_clear,level_up}.webp, a COLS x ROWS grid
# of CELL px frames played at FPS (first and last frame are empty). The grid
# constants are mirrored in lib/ui/components/sprite_anim.dart.
# Needs `cwebp` on PATH (brew install webp).
import bpy, sys, os, math, random, subprocess, zlib, struct
import numpy as np

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


def main():
    os.makedirs(TMP, exist_ok=True)
    out_dir = os.path.join(ROOT, "assets/anim")
    os.makedirs(out_dir, exist_ok=True)
    for name, build in (("board_clear", scene_board_clear), ("new_record", scene_new_record), ("level_up", scene_level_up)):
        if ONLY and name not in ONLY:
            continue
        sc = R.reset()
        sc.cycles.samples = 48
        sc.render.resolution_x = sc.render.resolution_y = CELL
        actors = build(sc)
        # Bake the procedural motion to keyframes and render as one animation:
        # a single render session keeps the GPU kernels loaded between frames.
        for f in range(FRAMES):
            t = f / (FRAMES - 1)
            for a in actors:
                a.apply(t)
                for prop in ("location", "rotation_euler", "scale", "hide_render"):
                    a.ob.keyframe_insert(prop, frame=f + 1)
        sc.frame_start, sc.frame_end = 1, FRAMES
        sc.render.use_persistent_data = True
        sc.render.filepath = os.path.join(TMP, f"{name}_")
        bpy.ops.render.render(animation=True)
        sheet = np.zeros((ROWS * CELL, COLS * CELL, 4), dtype=np.float32)
        for f in range(1, FRAMES - 1):   # first and last stay empty by contract
            r, c = divmod(f, COLS)
            sheet[r * CELL:(r + 1) * CELL, c * CELL:(c + 1) * CELL] = read_png(os.path.join(TMP, f"{name}_{f + 1:04d}.png"))
        png = os.path.join(TMP, f"{name}.png")
        write_png(png, sheet)
        subprocess.run(["cwebp", "-quiet", "-q", "86", "-alpha_q", "90", "-m", "6", png, "-o",
                        os.path.join(out_dir, f"{name}.webp")], check=True)
        # Keep a PNG copy for review tools.
        print("WROTE", name, png)
    print("DONE")


if __name__ == "__main__":
    main()
