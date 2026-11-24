# Renders the greyscale board surface textures.
#
#   blender -b --factory-startup -P tool/blender/render_boards.py -- <repo_root> [name ...]
#
# Output: assets/images/boards/board_{felt,grain,marble}.webp (SIZE px). The
# game multiplies the texture into the theme's board colour (BoardArt), so the
# bright field is close to white and the detail only darkens gently.
# Needs `cwebp` on PATH.
import bpy, sys, os, math, subprocess

argv = sys.argv[sys.argv.index("--") + 1:]
ROOT, ONLY = argv[0], argv[1:]
SIZE = 768
TMP = os.path.join(bpy.app.tempdir, "boards")


def scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    sc.render.engine = 'CYCLES'
    sc.cycles.samples = 16
    sc.cycles.use_denoising = False
    sc.render.resolution_x = sc.render.resolution_y = SIZE
    sc.render.image_settings.file_format = 'PNG'
    sc.render.image_settings.color_mode = 'RGB'
    sc.view_settings.view_transform = 'Standard'
    sc.view_settings.look = 'None'
    bpy.ops.mesh.primitive_plane_add(size=2)
    plane = bpy.context.object
    bpy.ops.object.camera_add(location=(0, 0, 5))
    cam = bpy.context.object
    cam.data.type = 'ORTHO'
    cam.data.ortho_scale = 2
    sc.camera = cam
    m = bpy.data.materials.new("surface")
    m.use_nodes = True
    nt = m.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    emit = nt.nodes.new("ShaderNodeEmission")
    nt.links.new(emit.outputs["Emission"], out.inputs["Surface"])
    plane.data.materials.append(m)
    return sc, nt, emit


def ramp(nt, stops):
    """stops: [(position, grey value)] -> ColorRamp node (values are display greys)."""
    node = nt.nodes.new("ShaderNodeValToRGB")
    el = node.color_ramp.elements
    for i, (pos, v) in enumerate(stops):
        e = el[i] if i < 2 else el.new(pos)
        e.position = pos
        lin = v ** 2.2        # the render is saved through the sRGB display transform
        e.color = (lin, lin, lin, 1)
    return node


def coords(nt, scale=(1, 1, 1), rotation=0.0):
    tc = nt.nodes.new("ShaderNodeTexCoord")
    mp = nt.nodes.new("ShaderNodeMapping")
    mp.inputs["Scale"].default_value = scale
    mp.inputs["Rotation"].default_value = (0, 0, math.radians(rotation))
    nt.links.new(tc.outputs["Object"], mp.inputs["Vector"])
    return mp


def multiply(nt, a, b):
    mix = nt.nodes.new("ShaderNodeMix")
    mix.data_type = 'RGBA'
    mix.blend_type = 'MULTIPLY'
    mix.inputs["Factor"].default_value = 1.0
    nt.links.new(a, mix.inputs["A"])
    nt.links.new(b, mix.inputs["B"])
    return mix.outputs["Result"]


def felt(nt, emit):
    # Fine fibrous speckle plus soft, larger mottling.
    fine = nt.nodes.new("ShaderNodeTexNoise")
    fine.inputs["Scale"].default_value = 260
    fine.inputs["Detail"].default_value = 6
    fine.inputs["Roughness"].default_value = 0.75
    nt.links.new(coords(nt, (1, 2.4, 1), 18).outputs["Vector"], fine.inputs["Vector"])
    r1 = ramp(nt, [(0.30, 0.86), (0.72, 1.0)])
    nt.links.new(fine.outputs["Fac"], r1.inputs["Fac"])
    soft = nt.nodes.new("ShaderNodeTexNoise")
    soft.inputs["Scale"].default_value = 5
    soft.inputs["Detail"].default_value = 2
    nt.links.new(coords(nt).outputs["Vector"], soft.inputs["Vector"])
    r2 = ramp(nt, [(0.30, 0.94), (0.75, 1.0)])
    nt.links.new(soft.outputs["Fac"], r2.inputs["Fac"])
    nt.links.new(multiply(nt, r1.outputs["Color"], r2.outputs["Color"]), emit.inputs["Color"])


def grain(nt, emit):
    # Long planks: stretched bands with a wobble, plus fine pores.
    wave = nt.nodes.new("ShaderNodeTexWave")
    wave.wave_type = 'BANDS'
    wave.bands_direction = 'Y'
    wave.inputs["Scale"].default_value = 1.5
    wave.inputs["Distortion"].default_value = 3.2
    wave.inputs["Detail"].default_value = 4.0
    wave.inputs["Detail Scale"].default_value = 1.4
    nt.links.new(coords(nt, (0.10, 1.0, 1.0), 3).outputs["Vector"], wave.inputs["Vector"])
    r1 = ramp(nt, [(0.10, 0.90), (0.85, 1.0)])
    nt.links.new(wave.outputs["Fac"], r1.inputs["Fac"])
    pores = nt.nodes.new("ShaderNodeTexNoise")
    pores.inputs["Scale"].default_value = 90
    pores.inputs["Detail"].default_value = 3
    nt.links.new(coords(nt, (0.05, 1.0, 1.0)).outputs["Vector"], pores.inputs["Vector"])
    r2 = ramp(nt, [(0.35, 0.96), (0.7, 1.0)])
    nt.links.new(pores.outputs["Fac"], r2.inputs["Fac"])
    nt.links.new(multiply(nt, r1.outputs["Color"], r2.outputs["Color"]), emit.inputs["Color"])


def marble(nt, emit):
    # Thin dark veins on a softly clouded field.
    wave = nt.nodes.new("ShaderNodeTexWave")
    wave.wave_type = 'BANDS'
    wave.inputs["Scale"].default_value = 0.7
    wave.inputs["Distortion"].default_value = 11.0
    wave.inputs["Detail"].default_value = 6.0
    wave.inputs["Detail Scale"].default_value = 1.2
    nt.links.new(coords(nt, (1, 1, 1), 32).outputs["Vector"], wave.inputs["Vector"])
    r1 = ramp(nt, [(0.0, 1.0), (1.0, 1.0), (0.455, 1.0), (0.50, 0.70), (0.545, 1.0)])
    nt.links.new(wave.outputs["Fac"], r1.inputs["Fac"])
    cloud = nt.nodes.new("ShaderNodeTexNoise")
    cloud.inputs["Scale"].default_value = 2.2
    cloud.inputs["Detail"].default_value = 4
    nt.links.new(coords(nt, (1, 1, 1), -20).outputs["Vector"], cloud.inputs["Vector"])
    r2 = ramp(nt, [(0.30, 0.90), (0.75, 1.0)])
    nt.links.new(cloud.outputs["Fac"], r2.inputs["Fac"])
    nt.links.new(multiply(nt, r1.outputs["Color"], r2.outputs["Color"]), emit.inputs["Color"])


if __name__ == "__main__":
    os.makedirs(TMP, exist_ok=True)
    out_dir = os.path.join(ROOT, "assets/images/boards")
    os.makedirs(out_dir, exist_ok=True)
    for name, build in (("felt", felt), ("grain", grain), ("marble", marble)):
        if ONLY and name not in ONLY:
            continue
        sc, nt, emit = scene()
        build(nt, emit)
        png = os.path.join(TMP, f"board_{name}.png")
        sc.render.filepath = png
        bpy.ops.render.render(write_still=True)
        subprocess.run(["cwebp", "-quiet", "-q", "88", "-m", "6", png, "-o", os.path.join(out_dir, f"board_{name}.webp")],
                       check=True)
        print("WROTE", name, png)
    print("DONE")
