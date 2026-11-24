# Renders the promo sting: logo tiles drop in and settle, tagline pops, loose
# tiles drift in the background.
#
#   blender -b --factory-startup -P tool/blender/render_video.py -- <repo_root> [frame_step]
#
# Output: docs/magaza-gorselleri-v6/tanitim.mp4 (1080x1920, 30 fps, 8 s).
# Frames are rendered with a transparent film and composited over the teal
# gradient by ffmpeg (needs ffmpeg on PATH).
import bpy, sys, os, math, random, subprocess
import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import render_brand as B

ROOT = B.ROOT
STEP = int(B.ONLY[0]) if B.ONLY else 1     # >1 renders every Nth frame (quick preview)
W, H, FPS, SECONDS = 1080, 1920, 30, 8
FRAMES = FPS * SECONDS
TMP = os.path.join(bpy.app.tempdir, "video")
OUT_DIR = os.path.join(ROOT, "docs/magaza-gorselleri-v6")


def bounce(u):
    """Ease-out bounce, 0..1."""
    if u <= 0:
        return 0.0
    if u >= 1:
        return 1.0
    n, d = 7.5625, 2.75
    if u < 1 / d:
        return n * u * u
    if u < 2 / d:
        u -= 1.5 / d
        return n * u * u + 0.75
    if u < 2.5 / d:
        u -= 2.25 / d
        return n * u * u + 0.9375
    u -= 2.625 / d
    return n * u * u + 0.984375


def pop(u):
    if u <= 0:
        return 0.0
    if u >= 1:
        return 1.0
    c = 1.70158 * 1.3
    return 1 + (c + 1) * (u - 1) ** 3 + c * (u - 1) ** 2


def main():
    os.makedirs(TMP, exist_ok=True)
    os.makedirs(OUT_DIR, exist_ok=True)
    sc = B.reset(W, H, samples=40)
    rnd = random.Random(8)
    actors = []   # (object, fn(t seconds) -> (loc, rot, scale))

    bpy.ops.object.empty_add(location=(0, 0, 3.2))
    rig = bpy.context.object
    rig.rotation_euler = (math.radians(80), 0, 0)
    for i, tile in enumerate(B.wordmark()):
        tile.parent = rig
        home = tuple(tile.location)
        delay = 0.25 + i * 0.16
        spin = (rnd.uniform(-1.6, 1.6), rnd.uniform(-1.2, 1.2), rnd.uniform(-0.9, 0.9))

        def fn(t, home=home, delay=delay, spin=spin):
            u = (t - delay) / 0.95
            b = bounce(u)
            k = max(0.0, 1 - min(max(u, 0.0), 1.0) * 1.6) ** 2
            # Local +Y is "up" on screen once the rig stands up.
            return ((home[0], home[1] + 22 * (1 - b), home[2]), (spin[0] * k, spin[1] * k, spin[2] * k), 1.0 if u > -0.2 else 0.0)
        actors.append((tile, fn))

    # Tagline.
    cream = bpy.data.materials.new("cream")
    cream.use_nodes = True
    nt = cream.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (*B.lin("FCF8EE"), 1)
    bsdf.inputs["Emission Color"].default_value = (*B.lin("FCF8EE"), 1)
    bsdf.inputs["Emission Strength"].default_value = 1.0
    tag = B.label("Blokları diz,\nkelimeyi patlat", 1.05, cream, 0, 0, 0)
    tag.data.space_line = 1.05
    tag.rotation_euler = (math.radians(90), 0, 0)

    def tag_fn(t):
        return ((0, 0, -3.4), (math.radians(90), 0, 0), pop((t - 2.6) / 0.45))
    actors.append((tag, tag_fn))

    # Demo word that pops below the tagline.
    for i, ch in enumerate("KAR"):
        tile = B.letter_tile(ch, B.IVORY)
        x = (i - 1) * 2.2

        def fn(t, x=x, i=i):
            s_in = pop((t - 3.5 - i * 0.12) / 0.35)
            out = min(max((t - 5.6 - i * 0.06) / 0.25, 0.0), 1.0)
            s = s_in * (1 + 0.25 * math.sin(math.pi * out)) * (1 - out ** 3)
            return ((x, 0, -8.6 + 0.5 * out), (math.radians(80), 0, 0), 0.92 * s)
        actors.append((tile, fn))

    # Loose tiles drifting behind.
    for i in range(12):
        tile = B.letter_tile("EKLTNARİMO"[i % 10], B.IVORY if i % 3 else B.TEAL, with_score=False)
        x = rnd.uniform(-7.5, 7.5)
        y = rnd.uniform(7, 20)
        z = rnd.uniform(-13, 13)
        if abs(z - 3) < 4 and abs(x) < 6:
            z += 9 if z > 3 else -9
        r0 = (math.radians(80 + rnd.uniform(-40, 40)), math.radians(rnd.uniform(-45, 45)), math.radians(rnd.uniform(-35, 35)))
        dr = (rnd.uniform(-0.12, 0.12), rnd.uniform(-0.12, 0.12), rnd.uniform(-0.1, 0.1))
        ph = rnd.uniform(0, 6.28)
        s = rnd.uniform(0.6, 0.95)

        def fn(t, x=x, y=y, z=z, r0=r0, dr=dr, ph=ph, s=s):
            return ((x + 0.25 * math.sin(t * 0.5 + ph), y, z + 0.5 * math.sin(t * 0.4 + ph) + 0.12 * t),
                    (r0[0] + dr[0] * t, r0[1] + dr[1] * t, r0[2] + dr[2] * t), s * min(1.0, t / 0.4 + 0.0))
        actors.append((tile, fn))

    bpy.ops.object.camera_add(location=(0, -46, 0))
    cam = bpy.context.object
    cam.rotation_euler = (math.radians(90), 0, 0)
    cam.data.lens = 118
    cam.data.sensor_fit = 'HORIZONTAL'
    cam.data.dof.use_dof = True
    cam.data.dof.aperture_fstop = 0.25
    sc.camera = cam
    actors.append((cam, lambda t: ((0, -46 + 3.0 * (t / SECONDS), 0), (math.radians(90), 0, 0), 1.0)))

    B.light((-9, -16, 16), 5200, 16)
    B.light((11, -14, -6), 1500, 16, color=(0.85, 0.97, 1.0))
    B.light((0, 10, 14), 2600, 12)

    for f in range(1, FRAMES + 1):
        t = (f - 1) / FPS
        for ob, fn in actors:
            loc, rot, s = fn(t)
            ob.location, ob.rotation_euler, ob.scale = loc, rot, (s, s, s)
            for prop in ("location", "rotation_euler", "scale"):
                ob.keyframe_insert(prop, frame=f)
        cam.data.dof.focus_distance = -cam.location.y
        cam.data.dof.keyframe_insert("focus_distance", frame=f)
    sc.frame_start, sc.frame_end, sc.frame_step = 1, FRAMES, STEP
    sc.render.fps = FPS
    sc.render.use_persistent_data = True
    sc.render.filepath = os.path.join(TMP, "f_")
    bpy.ops.render.render(animation=True)

    bg = os.path.join(TMP, "bg.png")
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    v = 1 - 0.42 * np.clip(((xx / W - 0.5) ** 2 + (yy / H - 0.45) ** 2) * 2.4, 0, 1)
    B.write_png(bg, B.teal_bg(W, H, grid=0) * v[..., None])
    if STEP == 1:
        out = os.path.join(OUT_DIR, "tanitim.mp4")
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-loop", "1", "-i", bg, "-framerate", str(FPS),
                        "-i", os.path.join(TMP, "f_%04d.png"), "-filter_complex", "[0][1]overlay=shortest=1,format=yuv420p",
                        "-c:v", "libx264", "-crf", "17", "-preset", "slow", "-r", str(FPS), out], check=True)
        print("WROTE", out)
    print("FRAMES", TMP)
    print("DONE")


if __name__ == "__main__":
    main()
