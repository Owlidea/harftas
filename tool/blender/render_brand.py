# Renders brand art from the game's own 3D tiles.
#
#   blender -b --factory-startup -P tool/blender/render_brand.py -- <repo_root> [name ...]
#
# Output:
#   assets/branding/app_icon_ios_1024.png   opaque icon (H tile over K tile on teal grid)
#   assets/branding/android_fg.png          same tiles, transparent, inside the adaptive safe zone
#   assets/branding/android_bg.png          teal grid background only
#   assets/branding/splash_mark.png         single H tile, transparent
#   docs/magaza-gorselleri-v6/logo.png      HARF / KOMBO wordmark, transparent
#   docs/magaza-gorselleri-v6/one-cikan-gorsel.png   1024x500 Google Play feature graphic
# (android_mono.png stays the flat code-drawn silhouette: tool/icon/render_icon_test.dart)
import bpy, bmesh, sys, os, math, random, zlib, struct
import numpy as np
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1:]
ROOT, ONLY = argv[0], argv[1:]
FONT = os.path.join(ROOT, "assets/fonts/Nunito-ExtraBold.ttf")
TMP = os.path.join(bpy.app.tempdir, "brand")
_font = None
SCORES = dict(H=5, A=1, R=1, F=7, K=1, O=2, M=2, B=3, E=1, L=1, T=1, N=1)


def lin(hex_):
    """sRGB hex -> linear RGB tuple."""
    out = []
    for i in (0, 2, 4):
        c = int(hex_[i:i + 2], 16) / 255
        out.append(c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4)
    return tuple(out)


IVORY = dict(face=lin("FCF8EE"), edge=lin("D9CDB2"), ink=lin("17213A"), score=lin("5C6377"))
TEAL = dict(face=lin("139088"), edge=lin("0A4F4C"), ink=lin("FFFFFF"), score=lin("D5ECEA"))


def write_png(path, rgba):
    a = (np.clip(rgba, 0, 1) * 255 + 0.5).astype(np.uint8)
    h, w, ch_n = a.shape
    raw = b"".join(b"\x00" + a[y].tobytes() for y in range(h))
    ch = lambda t, d: struct.pack(">I", len(d)) + t + d + struct.pack(">I", zlib.crc32(t + d) & 0xFFFFFFFF)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n" + ch(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6 if ch_n == 4 else 2, 0, 0, 0))
                + ch(b"IDAT", zlib.compress(raw, 9)) + ch(b"IEND", b""))
    print("WROTE", path)


def read_png(path):
    img = bpy.data.images.load(path)
    img.colorspace_settings.name = 'Non-Color'
    w, h = img.size
    px = np.array(img.pixels[:], dtype=np.float32).reshape(h, w, 4)[::-1]
    bpy.data.images.remove(img)
    return px


def reset(w, h, samples=256):
    global _font
    _font = None
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    sc.render.engine = 'CYCLES'
    try:
        prefs = bpy.context.preferences.addons['cycles'].preferences
        prefs.compute_device_type = 'METAL'
        prefs.get_devices()
        for d in prefs.devices:
            d.use = True
        sc.cycles.device = 'GPU'
    except Exception as e:
        print("GPU unavailable:", e)
    sc.cycles.samples = samples
    sc.cycles.use_denoising = True
    sc.render.resolution_x, sc.render.resolution_y = w, h
    sc.render.film_transparent = True
    sc.render.image_settings.file_format = 'PNG'
    sc.render.image_settings.color_mode = 'RGBA'
    sc.view_settings.view_transform = 'Standard'
    sc.view_settings.look = 'None'
    world = bpy.data.worlds.new("w")
    sc.world = world
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs[1].default_value = 0.42
    return sc


def mat(name, color, rough=0.38, coat=0.25, sss=0.0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (*color, 1)
    b.inputs["Roughness"].default_value = rough
    b.inputs["Coat Weight"].default_value = coat
    b.inputs["Coat Roughness"].default_value = 0.15
    b.inputs["Subsurface Weight"].default_value = sss
    return m


def slab(name, w, d, z0, z1, radius, top_round, material):
    mesh = bpy.data.meshes.new(name)
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1)
    for v in bm.verts:
        v.co.x *= w
        v.co.y *= d
        v.co.z = z0 if v.co.z < 0 else z1
    vert = [e for e in bm.edges if abs(e.verts[0].co.z - e.verts[1].co.z) > 1e-4]
    bmesh.ops.bevel(bm, geom=vert, offset=radius, segments=24, profile=0.5, affect='EDGES')
    for z, r in ((z1, top_round), (z0, 0.025)):
        bm.normal_update()
        ring = [e for e in bm.edges if all(abs(v.co.z - z) < 1e-4 for v in e.verts) and len(e.link_faces) == 2
                and any(abs(f.normal.z) < 0.5 for f in e.link_faces)]
        if r > 0 and ring:
            bmesh.ops.bevel(bm, geom=ring, offset=r, segments=12, profile=0.5, affect='EDGES')
    bm.to_mesh(mesh)
    bm.free()
    for p in mesh.polygons:
        p.use_smooth = True
    mesh.materials.append(material)
    ob = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(ob)
    return ob


def label(body, size, material, x, y, z):
    global _font
    bpy.ops.object.text_add(location=(x, y, z))
    t = bpy.context.object
    t.data.body = body
    if _font is None:
        _font = bpy.data.fonts.load(FONT)
    t.data.font = _font
    t.data.size = size
    t.data.align_x = 'CENTER'
    t.data.align_y = 'CENTER'
    t.data.extrude = 0.006
    t.data.materials.append(material)
    return t


def letter_tile(letter, colors, with_score=True):
    """Game tile (2 x 2 units, lying in XY, face up) with letter and score. Returns the parent empty."""
    h, base = 0.60, 0.30
    parts = [
        slab("cap", 2, 2, base, h, 0.36, 0.13, mat("face", colors["face"], sss=0.04)),
        slab("base", 2, 2, 0, base + 0.01, 0.36, 0, mat("edge", colors["edge"], rough=0.5, coat=0.1)),
        label(letter, 1.42, mat("ink", colors["ink"], rough=0.6, coat=0.0), 0, 0.02, h),
    ]
    if with_score:
        parts.append(label(str(SCORES.get(letter, 1)), 0.44, mat("score", colors["score"], rough=0.6, coat=0.0), 0.63, -0.62, h))
    bpy.ops.object.empty_add(location=(0, 0, 0))
    e = bpy.context.object
    for p in parts:
        p.parent = e
    return e


def aim(ob, target):
    ob.rotation_euler = (Vector(target) - ob.location).to_track_quat('-Z', 'Y').to_euler()


def light(loc, energy, size, target=(0, 0, 0), color=(1, 1, 1)):
    bpy.ops.object.light_add(type='AREA', location=loc)
    l = bpy.context.object
    l.data.energy, l.data.size, l.data.color = energy, size, color
    aim(l, target)
    return l


def top_camera(sc, scale, tilt=16):
    t = math.radians(tilt)
    bpy.ops.object.camera_add(location=(0, -math.sin(t) * 20, math.cos(t) * 20), rotation=(t, 0, 0))
    cam = bpy.context.object
    cam.data.type = 'ORTHO'
    cam.data.ortho_scale = scale
    sc.camera = cam
    return cam


def floor():
    bpy.ops.mesh.primitive_plane_add(size=80, location=(0, 0, 0))
    bpy.context.object.is_shadow_catcher = True


def render(sc, name):
    os.makedirs(TMP, exist_ok=True)
    path = os.path.join(TMP, name + ".png")
    sc.render.filepath = path
    bpy.ops.render.render(write_still=True)
    return read_png(path)


def teal_bg(w, h, grid=8, grid_alpha=0.08):
    """Diagonal teal gradient with a faint board grid (matches the old icon)."""
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    t = np.clip((xx / w + yy / h) / 2, 0, 1)[..., None]
    a, b, c = (np.array([int(s[i:i + 2], 16) / 255 for i in (0, 2, 4)], dtype=np.float32)
               for s in ("15908A", "0E6F6B", "0A4F4C"))
    rgb = np.where(t < 0.5, a + (b - a) * (t * 2), b + (c - b) * (t * 2 - 1))
    if grid:
        step = w / grid
        lw = max(w * 0.004, 1)
        gx = np.abs((xx + step / 2) % step - step / 2) < lw / 2
        gy = np.abs((yy + step / 2) % step - step / 2) < lw / 2
        on = gx | gy
        rgb = rgb + (1 - rgb) * (on[..., None] * grid_alpha)
    return rgb


def over(bg, px):
    a = px[..., 3:4]
    return bg * (1 - a) + px[..., :3] * a


def icon_tiles(sc, scale):
    """H in front, K peeking out behind. Returns nothing; scene is ready."""
    top_camera(sc, scale, tilt=14)
    k = letter_tile("K", TEAL)
    k.location = (0.62, 0.74, 0)
    k.rotation_euler = (0, 0, math.radians(-13))
    k.scale = (0.84, 0.84, 0.84)
    hh = letter_tile("H", IVORY)
    hh.location = (-0.36, -0.34, 0.5)
    hh.rotation_euler = (0, 0, math.radians(6))
    floor()
    light((-4, 5, 12), 1750, 9)
    light((6, -6, 7), 330, 10, color=(0.9, 0.97, 1.0))


def job_icon():
    sc = reset(1024, 1024)
    icon_tiles(sc, 4.7)
    px = render(sc, "icon")
    write_png(os.path.join(ROOT, "assets/branding/app_icon_ios_1024.png"), over(teal_bg(1024, 1024), px))
    write_png(os.path.join(ROOT, "assets/branding/android_bg.png"), teal_bg(1024, 1024))


def job_android_fg():
    sc = reset(1024, 1024)
    icon_tiles(sc, 7.4)      # adaptive icons crop to the central ~61%
    write_png(os.path.join(ROOT, "assets/branding/android_fg.png"), render(sc, "android_fg"))


def job_splash():
    sc = reset(1024, 1024)
    top_camera(sc, 4.9, tilt=14)
    letter_tile("H", IVORY)
    floor()
    light((-4, 5, 12), 1750, 9)
    light((6, -6, 7), 330, 10, color=(0.9, 0.97, 1.0))
    write_png(os.path.join(ROOT, "assets/branding/splash_mark.png"), render(sc, "splash"))


def wordmark(gap=2.16):
    """HARF over KOMBO, lying in XY, centred on the origin. Returns tiles."""
    tiles = []
    for word, colors, y in (("HARF", IVORY, 1.1), ("KOMBO", TEAL, -1.1)):
        x0 = -(len(word) - 1) * gap / 2
        for i, ch in enumerate(word):
            t = letter_tile(ch, colors)
            t.location = (x0 + i * gap, y, 0)
            tiles.append(t)
    return tiles


def job_logo():
    sc = reset(2400, 1100)
    top_camera(sc, 11.6, tilt=14)
    wordmark()
    floor()
    light((-5, 6, 14), 3500, 12)
    light((8, -7, 8), 600, 12, color=(0.9, 0.97, 1.0))
    write_png(os.path.join(ROOT, "docs/magaza-gorselleri-v6/logo.png"), render(sc, "logo"))


def job_feature():
    """1024x500: wordmark standing up, loose tiles drifting around it out of focus."""
    W, H = 1024, 500
    sc = reset(W * 2, H * 2, samples=384)
    bpy.ops.object.empty_add(location=(0, 0, 0))
    rig = bpy.context.object
    for t in wordmark():
        t.parent = rig
    rig.rotation_euler = (math.radians(78), 0, 0)      # stand up, leaning back a little
    rig.location = (0, 0, 0.45)
    rnd = random.Random(21)
    spots = [(-8.0, 6, 3.3), (-5.2, 12, -3.9), (8.1, 5, 3.4), (7.2, -8, -2.9), (5.6, 13, -3.8),
             (-3.4, 14, 4.1), (3.0, 15, 4.0), (-8.6, 10, 0.2), (8.8, 11, 0.4), (0.4, -10, -3.6)]
    for i, (x, y, z) in enumerate(spots):
        t = letter_tile("EKLTNAR"[i % 7], IVORY if i % 3 else TEAL)
        t.location = (x, y, z)
        t.rotation_euler = (math.radians(78 + rnd.uniform(-35, 35)), math.radians(rnd.uniform(-40, 40)),
                            math.radians(rnd.uniform(-30, 30)))
        s = rnd.uniform(0.5, 0.8)
        t.scale = (s, s, s)
    bpy.ops.object.camera_add(location=(0, -30, 1.2))
    cam = bpy.context.object
    aim(cam, (0, 0, 0.9))
    cam.data.lens = 58
    cam.data.sensor_fit = 'HORIZONTAL'
    cam.data.dof.use_dof = True
    cam.data.dof.focus_distance = 30
    cam.data.dof.aperture_fstop = 0.16
    sc.camera = cam
    light((-8, -14, 12), 3600, 14)
    light((10, -12, -2), 1100, 14, color=(0.85, 0.97, 1.0))
    light((0, 10, 10), 1500, 10)
    px = render(sc, "feature")
    # Downsample 2x for clean edges.
    px = px.reshape(H, 2, W, 2, 4).mean(axis=(1, 3))
    bg = teal_bg(W, H, grid=0)
    # Vignette toward the corners so the wordmark carries the frame.
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    v = 1 - 0.38 * np.clip(((xx / W - 0.5) ** 2 + (yy / H - 0.5) ** 2) * 2.2, 0, 1)
    write_png(os.path.join(ROOT, "docs/magaza-gorselleri-v6/one-cikan-gorsel.png"), over(bg * v[..., None], px))


JOBS = dict(icon=job_icon, android_fg=job_android_fg, splash=job_splash, logo=job_logo, feature=job_feature)

if __name__ == "__main__":
    for name, fn in JOBS.items():
        if ONLY and name not in ONLY:
            continue
        fn()
    print("DONE")
