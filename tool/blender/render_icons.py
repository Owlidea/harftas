# Renders the 3D artwork icons and streak medals.
#
#   blender -b --factory-startup -P tool/blender/render_icons.py -- <repo_root> [name ...]
#
# Output (transparent PNG, SIZE px square):
#   assets/images/art/{star,crown,flame,lock,gift}.png
#   assets/images/badges/streak_{7,30,100}.png
import bpy, sys, math, os
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1:]
ROOT = argv[0]
ONLY = argv[1:]
SIZE = 512
SAMPLES = 192
FONT = os.path.join(ROOT, "assets/fonts/Nunito-ExtraBold.ttf")

CREAM = (0.86, 0.72, 0.48)
IVORY = (0.90, 0.80, 0.62)
TEAL = (0.02, 0.36, 0.34)
MINT = (0.16, 0.70, 0.65)
GOLD = (1.00, 0.52, 0.05)
GOLD_LIGHT = (1.00, 0.70, 0.16)
BRONZE = (0.70, 0.36, 0.16)
BRONZE_LIGHT = (0.88, 0.55, 0.30)
SILVER = (0.68, 0.72, 0.78)
SILVER_LIGHT = (0.88, 0.90, 0.93)
NAVY = (0.02, 0.03, 0.08)
FLAME = (1.00, 0.25, 0.03)
FLAME_IN = (1.00, 0.62, 0.08)


def reset():
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
    sc.cycles.samples = SAMPLES
    sc.cycles.use_denoising = True
    sc.render.resolution_x = sc.render.resolution_y = SIZE
    sc.render.film_transparent = True
    sc.render.image_settings.file_format = 'PNG'
    sc.render.image_settings.color_mode = 'RGBA'
    sc.view_settings.view_transform = 'Standard'
    sc.view_settings.look = 'None'
    w = bpy.data.worlds.new("w")
    sc.world = w
    w.use_nodes = True
    w.node_tree.nodes["Background"].inputs[1].default_value = 0.38
    return sc


def aim(ob, target=(0, 0, 0)):
    d = Vector(target) - ob.location
    ob.rotation_euler = d.to_track_quat('-Z', 'Y').to_euler()


def studio(sc, scale=2.6, tilt=8, target=(0, 0, 0)):
    t = math.radians(tilt)
    bpy.ops.object.camera_add(location=(0, -10 * math.cos(t), 10 * math.sin(t)))
    cam = bpy.context.object
    cam.location += Vector(target)
    aim(cam, target)
    cam.data.type = 'ORTHO'
    cam.data.ortho_scale = scale
    sc.camera = cam
    for loc, energy, size, color in (
        ((-3.5, -5.0, 5.0), 650, 5.0, (1.0, 0.98, 0.95)),   # key
        ((4.5, -4.0, 1.0), 160, 6.0, (0.90, 0.97, 1.0)),    # fill
        ((1.5, 4.0, 5.0), 500, 4.0, (1.0, 1.0, 1.0)),       # rim
    ):
        bpy.ops.object.light_add(type='AREA', location=loc)
        l = bpy.context.object
        l.data.energy = energy
        l.data.size = size
        l.data.color = color
        aim(l)


def mat(name, color, rough=0.28, metallic=0.0, coat=0.5, sss=0.0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (*color, 1)
    b.inputs["Roughness"].default_value = rough
    b.inputs["Metallic"].default_value = metallic
    b.inputs["Coat Weight"].default_value = coat
    b.inputs["Coat Roughness"].default_value = 0.1
    b.inputs["Subsurface Weight"].default_value = sss
    return m


def fillet(pts, radius, n=8):
    """Rounds every corner of a closed polygon."""
    out = []
    k = len(pts)
    for i in range(k):
        p0, p1, p2 = Vector(pts[i - 1]), Vector(pts[i]), Vector(pts[(i + 1) % k])
        a, b = (p0 - p1), (p2 - p1)
        r = min(radius, a.length * 0.45, b.length * 0.45)
        s, e = p1 + a.normalized() * r, p1 + b.normalized() * r
        for j in range(n + 1):
            u = j / n
            out.append(tuple((1 - u) ** 2 * s + 2 * u * (1 - u) * p1 + u * u * e))
    return out


def emblem(name, pts, material, depth=0.16, puff=0.10, y=0.0, smooth=False):
    """Extruded, round-edged 2D shape standing upright and facing the camera."""
    cu = bpy.data.curves.new(name, 'CURVE')
    cu.dimensions = '2D'
    cu.fill_mode = 'BOTH'
    cu.extrude = depth
    cu.bevel_depth = puff
    cu.bevel_resolution = 8
    cu.resolution_u = 24
    if smooth:
        sp = cu.splines.new('BEZIER')
        sp.bezier_points.add(len(pts) - 1)
        for bp, p in zip(sp.bezier_points, pts):
            sharp = len(p) > 2
            bp.co = (p[0], p[1], 0)
            bp.handle_left_type = bp.handle_right_type = 'VECTOR' if sharp else 'AUTO'
    else:
        sp = cu.splines.new('POLY')
        sp.points.add(len(pts) - 1)
        for sp_p, p in zip(sp.points, pts):
            sp_p.co = (p[0], p[1], 0, 1)
    sp.use_cyclic_u = True
    ob = bpy.data.objects.new(name, cu)
    bpy.context.collection.objects.link(ob)
    ob.rotation_euler = (math.radians(90), 0, 0)
    ob.location.y = y
    cu.materials.append(material)
    return ob


def prim(kind, material, smooth=True, **kw):
    getattr(bpy.ops.mesh, f"primitive_{kind}_add")(**kw)
    ob = bpy.context.object
    ob.data.materials.append(material)
    if smooth:
        bpy.ops.object.shade_smooth()
    return ob


def box(material, size, location, bevel=0.06, rotation=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(size=1, location=location, rotation=rotation)
    ob = bpy.context.object
    ob.scale = size
    bpy.ops.object.transform_apply(scale=True)
    b = ob.modifiers.new("b", 'BEVEL')
    b.width = bevel
    b.segments = 8
    ob.data.materials.append(material)
    bpy.ops.object.shade_smooth()
    return ob


def text(body, size, material, location, extrude=0.05):
    bpy.ops.object.text_add(location=location, rotation=(math.radians(90), 0, 0))
    t = bpy.context.object
    t.data.body = body
    t.data.font = bpy.data.fonts.load(FONT)
    t.data.size = size
    t.data.align_x = 'CENTER'
    t.data.align_y = 'CENTER'
    t.data.extrude = extrude
    t.data.bevel_depth = 0.012
    t.data.bevel_resolution = 4
    t.data.materials.append(material)
    return t


def group(objs, rot_z=0.0, rot_x=0.0, scale=1.0):
    bpy.ops.object.empty_add(location=(0, 0, 0))
    e = bpy.context.object
    for o in objs:
        o.parent = e
    e.rotation_euler = (math.radians(rot_x), 0, math.radians(rot_z))
    e.scale = (scale, scale, scale)
    return e


def star_points(outer=1.0, inner=0.48, n=5, phase=90):
    pts = []
    for i in range(n * 2):
        r = outer if i % 2 == 0 else inner
        a = math.radians(phase + i * 180 / n)
        pts.append((r * math.cos(a), r * math.sin(a)))
    return pts


FLAME_OUTLINE = [(0.0, -1.0), (0.62, -0.66), (0.74, -0.08), (0.50, 0.38), (0.30, 0.20),
                 (0.22, 0.62), (-0.10, 1.04, 1), (-0.22, 0.52), (-0.50, 0.18), (-0.74, -0.30), (-0.56, -0.74)]
FLAME_INNER = [(0.02, -0.90), (0.34, -0.72), (0.40, -0.38), (0.24, -0.08), (0.06, 0.24, 1), (-0.14, -0.10), (-0.36, -0.42), (-0.30, -0.74)]


def icon_star(sc):
    studio(sc, 2.5)
    s = emblem("star", fillet(star_points(), 0.16), mat("gold", GOLD, 0.25, coat=0.8), depth=0.16, puff=0.14)
    group([s], rot_z=-10)


def icon_flame(sc):
    studio(sc, 2.5)
    a = emblem("flame", FLAME_OUTLINE, mat("flame", FLAME, 0.3, coat=0.7), depth=0.16, puff=0.13, smooth=True)
    b = emblem("inner", FLAME_INNER, mat("flame_in", FLAME_IN, 0.3, coat=0.7), depth=0.10, puff=0.08, y=-0.22, smooth=True)
    group([a, b], rot_z=-8, scale=0.86)


def icon_crown(sc):
    studio(sc, 2.6, target=(0, 0, 0.05))
    gold = mat("gold", GOLD, 0.25, coat=0.8)
    pts = [(-0.82, -0.55), (0.82, -0.55), (1.0, 0.50), (0.48, 0.02), (0.0, 0.82), (-0.48, 0.02), (-1.0, 0.50)]
    body = emblem("crown", fillet(pts, 0.09), gold, depth=0.14, puff=0.11)
    band = box(mat("gold2", GOLD_LIGHT, 0.25, coat=0.8), (1.90, 0.46, 0.34), (0, 0, -0.60), bevel=0.13)
    objs = [body, band]
    for x, z in ((1.0, 0.56), (0.0, 0.90), (-1.0, 0.56)):
        objs.append(prim("uv_sphere", gold, radius=0.16, location=(x, 0, z)))
    gem = mat("gem", MINT, 0.12, coat=1.0)
    for x in (-0.55, 0.0, 0.55):
        objs.append(prim("uv_sphere", gem, radius=0.15, location=(x, -0.20, -0.60)))
    group(objs, rot_z=-10, scale=0.92)


def icon_lock(sc):
    studio(sc, 2.6)
    body = box(mat("cream", CREAM, 0.32, coat=0.6, sss=0.1), (1.5, 0.5, 1.15), (0, 0, -0.38), bevel=0.2)
    sh = prim("torus", mat("teal", TEAL, 0.25, coat=0.8), major_radius=0.46, minor_radius=0.13,
              location=(0, 0, 0.34), rotation=(math.radians(90), 0, 0), major_segments=64, minor_segments=24)
    dark = mat("navy", NAVY, 0.3)
    hole = prim("cylinder", dark, radius=0.17, depth=0.1, location=(0, -0.25, -0.30), rotation=(math.radians(90), 0, 0))
    slot = box(dark, (0.14, 0.1, 0.34), (0, -0.25, -0.50), bevel=0.03)
    group([body, sh, hole, slot], rot_z=-10)


def icon_gift(sc):
    studio(sc, 2.9, tilt=24, target=(0, 0, 0.02))
    cream = mat("cream", IVORY, 0.35, coat=0.5, sss=0.1)
    teal = mat("teal", TEAL, 0.25, coat=0.8)
    objs = [
        box(cream, (1.30, 1.30, 0.95), (0, 0, -0.42), bevel=0.09),
        box(cream, (1.46, 1.46, 0.30), (0, 0, 0.20), bevel=0.08),
        box(teal, (0.30, 1.48, 1.27), (0, 0, -0.27), bevel=0.05),
        box(teal, (1.48, 0.30, 1.27), (0, 0, -0.27), bevel=0.05),
    ]
    for sx in (-1, 1):
        loop = prim("torus", teal, major_radius=0.24, minor_radius=0.085, location=(sx * 0.36, 0, 0.54),
                    rotation=(math.radians(90), math.radians(sx * 40), 0), major_segments=48, minor_segments=20)
        loop.scale = (1.35, 0.7, 1.0)
        objs.append(loop)
    objs.append(prim("uv_sphere", teal, radius=0.15, location=(0, 0, 0.44)))
    group(objs, rot_z=32)


def medal(days, base, light):
    def build(sc):
        studio(sc, 2.36, tilt=5)
        m_base = mat("base", base, 0.28, metallic=0.85, coat=0.3)
        m_light = mat("light", light, 0.32, metallic=0.85, coat=0.3)
        rot = (math.radians(90), 0, 0)
        objs = [
            prim("cylinder", m_base, radius=1.0, depth=0.20, location=(0, 0, 0), rotation=rot, vertices=96),
            prim("torus", m_base, major_radius=0.93, minor_radius=0.075, location=(0, -0.10, 0), rotation=rot,
                 major_segments=96, minor_segments=20),
            prim("cylinder", m_light, radius=0.84, depth=0.06, location=(0, -0.09, 0), rotation=rot, vertices=96),
        ]
        # Bead ring.
        for i in range(28):
            a = math.radians(i * 360 / 28)
            objs.append(prim("uv_sphere", m_base, radius=0.028, location=(0.76 * math.cos(a), -0.12, 0.76 * math.sin(a)),
                             segments=12, ring_count=8))
        fl = emblem("flame", FLAME_OUTLINE, mat("flame", FLAME, 0.3, coat=0.7), depth=0.04, puff=0.04, y=-0.16, smooth=True)
        fi = emblem("flame_in", FLAME_INNER, mat("flame_in", FLAME_IN, 0.3, coat=0.7), depth=0.03, puff=0.03, y=-0.23, smooth=True)
        for f in (fl, fi):
            f.scale = (0.30, 0.30, 0.30)
            f.location.z = 0.38
        s = str(days)
        size = {1: 0.86, 2: 0.76, 3: 0.60}[len(s)]
        num = text(s, size, mat("ink", NAVY, 0.3, coat=0.6), (0, -0.14, -0.22), extrude=0.035)
        objs += [fl, fi, num]
        group(objs, rot_z=-9)
    return build


JOBS = {
    "art/star": icon_star,
    "art/flame": icon_flame,
    "art/crown": icon_crown,
    "art/lock": icon_lock,
    "art/gift": icon_gift,
    "badges/streak_7": medal(7, BRONZE, BRONZE_LIGHT),
    "badges/streak_30": medal(30, SILVER, SILVER_LIGHT),
    "badges/streak_100": medal(100, GOLD, GOLD_LIGHT),
}

for name, fn in JOBS.items():
    if ONLY and not any(o in name for o in ONLY):
        continue
    sc = reset()
    fn(sc)
    out = os.path.join(ROOT, "assets/images", name + ".png")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    sc.render.filepath = out
    bpy.ops.render.render(write_still=True)
    print("WROTE", out)
print("DONE")
