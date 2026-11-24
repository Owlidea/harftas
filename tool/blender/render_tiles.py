# Renders the tintable 3D tile layers used by lib/ui/game/tile_art.dart.
#
#   tool/blender/build.sh            (or)
#   blender -b --factory-startup -P tool/blender/render_tiles.py -- <out_dir> [style ...]
#
# Per tile style it writes assets/images/tiles/tile_<style>.png: a 4-cell
# horizontal atlas (shadow | edge | face | gloss), each cell CELL px square.
#   shadow  black, alpha = contact/drop shadow
#   edge    grey shading of the tile base, tinted in code with Palette.tileEdge
#   face    grey shading of the top plate, tinted in code with Palette.tile
#   gloss   white, alpha = highlights (drawn untinted on top)
# and tiles.json with the tile's bounding box inside a cell (fractions) and
# the visible side depth, so code can map a logical tile rect onto the art.
import bpy, bmesh, sys, math, os, json, zlib, struct
import numpy as np

argv = sys.argv[sys.argv.index("--") + 1:]
OUT = argv[0]
ONLY = argv[1:]
CELL = 384          # px per atlas cell
TILE = 256          # px the tile silhouette spans inside a cell
TILT = math.radians(14)
SAMPLES = 160
TMP = os.path.join(bpy.app.tempdir, "tiles")

STYLES = {
    # radius: corner radius / tile width, h: total height, base: base slab
    # height (0 = single piece), round: top edge rounding, rim: raised border.
    "classic": dict(radius=0.18, h=0.60, base=0.30, round=0.13, rim=False),
    "soft":    dict(radius=0.32, h=0.42, base=0.0,  round=0.26, rim=False),
    "sharp":   dict(radius=0.06, h=0.40, base=0.14, round=0.035, rim=True),
}


def write_png(path, rgba):
    """rgba: float array (h, w, 4) in 0..1, row 0 = top. Straight alpha."""
    a = (np.clip(rgba, 0, 1) * 255 + 0.5).astype(np.uint8)
    h, w, _ = a.shape
    raw = b"".join(b"\x00" + a[y].tobytes() for y in range(h))
    def chunk(tag, data):
        c = struct.pack(">I", len(data)) + tag + data
        return c + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0))
                + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b""))


def read_render(path):
    img = bpy.data.images.load(path)
    img.colorspace_settings.name = 'Non-Color'
    w, h = img.size
    px = np.array(img.pixels[:], dtype=np.float32).reshape(h, w, 4)[::-1]
    bpy.data.images.remove(img)
    return px


def slab(name, w, d, z0, z1, radius, top_round, bottom_round=0.0):
    """Rounded-rectangle slab centred on the origin."""
    mesh = bpy.data.meshes.new(name)
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1)
    for v in bm.verts:
        v.co.x *= w
        v.co.y *= d
        v.co.z = z0 if v.co.z < 0 else z1
    vert = [e for e in bm.edges if abs(e.verts[0].co.z - e.verts[1].co.z) > 1e-4]
    bmesh.ops.bevel(bm, geom=vert, offset=radius, segments=24, profile=0.5, affect='EDGES')
    def ring(z):
        return [e for e in bm.edges if all(abs(v.co.z - z) < 1e-4 for v in e.verts) and len(e.link_faces) == 2
                and any(abs(f.normal.z) < 0.5 for f in e.link_faces)]
    if top_round > 0:
        bm.normal_update()
        bmesh.ops.bevel(bm, geom=ring(z1), offset=top_round, segments=14, profile=0.5, affect='EDGES')
    if bottom_round > 0:
        bm.normal_update()
        bmesh.ops.bevel(bm, geom=ring(z0), offset=bottom_round, segments=4, profile=0.5, affect='EDGES')
    bm.to_mesh(mesh)
    bm.free()
    ob = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(ob)
    for p in mesh.polygons:
        p.use_smooth = True
    return ob


def frame(name, w, d, z, radius, width, height):
    """Raised rim: outer rounded rect minus inner one."""
    outer = slab(name, w, d, z, z + height, radius, height * 0.45)
    inner = slab(name + "_cut", w - 2 * width, d - 2 * width, z - 1, z + 1, max(radius - width, 0.01), 0)
    m = outer.modifiers.new("cut", 'BOOLEAN')
    m.object = inner
    m.operation = 'DIFFERENCE'
    m.solver = 'EXACT'
    inner.hide_render = True
    inner.hide_viewport = True
    return outer


def material(name, color, rough, spec, coat=0.0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (*color, 1)
    b.inputs["Roughness"].default_value = rough
    b.inputs["Specular IOR Level"].default_value = spec
    b.inputs["Coat Weight"].default_value = coat
    b.inputs["Coat Roughness"].default_value = 0.12
    return m


def build(style, s):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    sc.render.engine = 'CYCLES'
    try:
        prefs = bpy.context.preferences.addons['cycles'].preferences
        prefs.compute_device_type = 'METAL'
        prefs.get_devices()
        for dev in prefs.devices:
            dev.use = True
        sc.cycles.device = 'GPU'
    except Exception as e:  # CPU fallback
        print("GPU unavailable:", e)
    sc.cycles.samples = SAMPLES
    sc.cycles.use_denoising = True
    sc.render.resolution_x = sc.render.resolution_y = CELL
    sc.render.film_transparent = True
    sc.render.image_settings.file_format = 'PNG'
    sc.render.image_settings.color_mode = 'RGBA'
    sc.view_settings.view_transform = 'Standard'
    sc.view_settings.look = 'None'

    W = 2.0
    h = s["h"]
    # Depth chosen so the tilted silhouette is exactly square.
    D = (W - h * math.sin(TILT)) / math.cos(TILT)
    r = s["radius"] * W
    cap = slab("cap", W, D, s["base"], h, r, s["round"], 0.02 if s["base"] > 0 else 0.03)
    parts = {"cap": cap}
    if s["base"] > 0:
        parts["base"] = slab("base", W, D, 0, s["base"] + 0.01, r, 0, 0.03)
    if s["rim"]:
        inset = 0.03 * W
        parts["rim"] = frame("rim", W - 2 * inset, D - 2 * inset, h - 0.004, r * 0.8, 0.03 * W, 0.022)

    bpy.ops.mesh.primitive_plane_add(size=40, location=(0, 0, 0))
    floor = bpy.context.object
    floor.is_shadow_catcher = True

    # Camera: orthographic, tilted so the front side shows below the face.
    y0 = h * math.sin(TILT) / 2 / math.cos(TILT)
    dist = 10
    bpy.ops.object.camera_add(location=(0, y0 - math.sin(TILT) * dist, math.cos(TILT) * dist), rotation=(TILT, 0, 0))
    cam = bpy.context.object
    cam.data.type = 'ORTHO'
    cam.data.ortho_scale = W * CELL / TILE
    sc.camera = cam

    def area(loc, energy, size, color=(1, 1, 1)):
        bpy.ops.object.light_add(type='AREA', location=loc)
        l = bpy.context.object
        l.data.energy = energy
        l.data.size = size
        l.data.color = color
        # Aim at the tile.
        d = -np.array(loc, dtype=float)
        l.rotation_euler = (math.atan2(math.hypot(d[0], d[1]), -d[2]) * 0 , 0, 0)
        from mathutils import Vector
        l.rotation_euler = Vector(d).to_track_quat('-Z', 'Y').to_euler()
        return l
    key = area((-1.2, 1.6, 6.5), 420, 4.0)
    fill = area((3.5, -3.0, 4.0), 90, 7.0)
    world = bpy.data.worlds.new("w")
    sc.world = world
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs[1].default_value = 0.55

    matte = material("matte", (0.8, 0.8, 0.8), 1.0, 0.0)
    glossy = material("glossy", (0, 0, 0), 0.22, 0.5, 0.35)
    all_parts = list(parts.values())

    def render(tag, visible, holdout=(), mat=matte, camera_visible=True, with_floor=False):
        for ob in all_parts:
            ob.data.materials.clear()
            ob.data.materials.append(mat)
            ob.hide_render = False
            ob.is_holdout = ob in holdout
            ob.visible_camera = camera_visible and (ob in visible or ob in holdout)
            if ob not in visible and ob not in holdout:
                ob.visible_camera = False
        floor.hide_render = not with_floor
        path = os.path.join(TMP, f"{style}_{tag}.png")
        sc.render.filepath = path
        bpy.ops.render.render(write_still=True)
        return read_render(path)

    edge_parts = [parts[k] for k in ("base", "rim") if k in parts]
    face = render("face", [cap], holdout=edge_parts)
    edge = render("edge", edge_parts, holdout=[cap]) if edge_parts else np.zeros_like(face)
    shadow = render("shadow", [], camera_visible=False, with_floor=True)
    # Highlights: black glossy body, a strip light for a sheen across the top.
    key.data.energy = 900
    fill.data.energy = 0
    world.node_tree.nodes["Background"].inputs[1].default_value = 0.0
    strip = area((-1.0, 3.5, 5.5), 500, 3.0)
    strip.data.shape = 'RECTANGLE'
    strip.data.size = 7.0
    strip.data.size_y = 1.6
    gloss = render("gloss", all_parts, mat=glossy)

    lum = lambda px: px[..., :3].mean(axis=2)
    body_a = np.maximum(face[..., 3], edge[..., 3])
    ys, xs = np.where(body_a > 0.5)
    box = [int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1]

    # Face multiplier: flat top = 1.0 so the palette colour is reproduced.
    fa = face[..., 3]
    cy0 = box[1] + int(TILE * 0.25); cy1 = box[1] + int(TILE * 0.55)
    cx0 = box[0] + int(TILE * 0.3);  cx1 = box[0] + int(TILE * 0.7)
    ref = float(np.median(lum(face)[cy0:cy1, cx0:cx1]))
    fm = lum(face) / ref
    over = np.clip(fm - 1.0, 0, 1)
    fm = np.clip(fm, 0, 1)
    # Keep shading gentle: tiles must stay readable in every theme.
    fm = 1 - (1 - fm) * 0.85

    if edge[..., 3].max() > 0.5:
        ea = edge[..., 3]
        eref = float(np.percentile(lum(edge)[ea > 0.9], 70))
        em = np.clip(lum(edge) / eref, 0, 1.15)
        em = np.clip(em, 0, 1)
    else:
        ea = np.zeros_like(fa); em = np.ones_like(fa)

    g = lum(gloss) * gloss[..., 3]
    # Only what exceeds the flat top's own reflection counts as a highlight,
    # otherwise saturated tiles (accent, joker) wash out.
    gref = float(np.percentile(g[cy0:cy1, cx0:cx1], 60))
    ga = np.clip((g - gref) * 1.8, 0, 1) * 0.45 + over * 0.9 * fa
    ga = np.clip(ga, 0, 0.8)

    sa = np.clip(shadow[..., 3] * 0.9, 0, 1)
    # Fade to nothing before the cell border so neighbours never show a seam.
    yy, xx = np.mgrid[0:CELL, 0:CELL]
    edge_dist = np.minimum(np.minimum(xx, CELL - 1 - xx), np.minimum(yy, CELL - 1 - yy)) / 40.0
    win = np.clip(edge_dist, 0, 1)
    sa = sa * win * win * (3 - 2 * win)

    def cell(l, a):
        return np.dstack([l, l, l, a])
    one = np.ones_like(fa)
    atlas = np.concatenate([cell(one * 0, sa), cell(em, ea), cell(fm, fa), cell(one, ga)], axis=1)
    write_png(os.path.join(OUT, f"tile_{style}.png"), atlas)

    face_ys = np.where(fa[:, CELL // 2] > 0.5)[0]
    side = (box[3] - (int(face_ys.max()) + 1)) if s["base"] > 0 else 0
    # Where the flat top ends (letters are centred on the flat part).
    meta = {
        "box": [box[0] / CELL, box[1] / CELL, box[2] / CELL, box[3] / CELL],
        "depth": round(h * math.sin(TILT) / W, 4),
        "edgeBand": round(side / TILE, 4),
        "hasEdge": bool(edge_parts),
    }
    print("META", style, meta, "ref", ref)
    return meta


os.makedirs(OUT, exist_ok=True)
os.makedirs(TMP, exist_ok=True)
meta_path = os.path.join(OUT, "tiles.json")
meta = json.load(open(meta_path)) if os.path.exists(meta_path) else {"cell": CELL, "styles": {}}
meta["cell"] = CELL
for name, spec in STYLES.items():
    if ONLY and name not in ONLY:
        continue
    meta["styles"][name] = build(name, spec)
with open(meta_path, "w") as f:
    json.dump(meta, f, indent=2, sort_keys=True)
    f.write("\n")
print("DONE")
