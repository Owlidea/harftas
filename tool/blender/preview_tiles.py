# Composites the tile atlases over theme colours for a quick look (no Flutter).
#   blender -b --factory-startup -P tool/blender/preview_tiles.py -- <tiles_dir> <out.png>
import bpy, sys, os, json, zlib, struct
import numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
src, out = sys.argv[sys.argv.index("--") + 1:][:2]
meta = json.load(open(os.path.join(src, "tiles.json")))
C = meta["cell"]

def load(p):
    img = bpy.data.images.load(p); img.colorspace_settings.name = 'Non-Color'
    w, h = img.size
    return np.array(img.pixels[:], dtype=np.float32).reshape(h, w, 4)[::-1]

def hexc(s): return np.array([int(s[i:i+2], 16) / 255 for i in (0, 2, 4)], dtype=np.float32)
def over(dst, rgb, a): return dst * (1 - a[..., None]) + rgb * a[..., None]

themes = [  # background, tile, edge, shadow alpha
    ("E9E3D6", "FCF8EE", "D9CDB2", 0.30), ("E9E3D6", "0E6F6B", "094845", 0.30),
    ("16203A", "EAE5D8", "B9B19D", 0.60), ("16203A", "4CC3BA", "317F79", 0.60),
    ("E9E3D6", "F1E4FA", "D9CDB2", 0.30),
]
styles = [s for s in ("classic", "soft", "sharp", "grain", "marble") if s in meta["styles"]]
canvas = np.zeros((C * len(styles), C * len(themes), 3), dtype=np.float32)
for r, st in enumerate(styles):
    at = load(os.path.join(src, f"tile_{st}.png"))
    sh, ed, fa, gl = (at[:, i * C:(i + 1) * C] for i in range(4))
    for c, (bg, tile, edge, sa) in enumerate(themes):
        px = np.ones((C, C, 3), dtype=np.float32) * hexc(bg)
        px = over(px, np.zeros(3, dtype=np.float32), sh[..., 3] * sa)
        px = over(px, ed[..., :3] * hexc(edge), ed[..., 3])
        px = over(px, fa[..., :3] * hexc(tile), fa[..., 3])
        px = over(px, np.ones(3, dtype=np.float32), gl[..., 3])
        canvas[r * C:(r + 1) * C, c * C:(c + 1) * C] = px
a = (np.clip(canvas, 0, 1) * 255 + 0.5).astype(np.uint8); h, w, _ = a.shape
raw = b"".join(b"\x00" + a[y].tobytes() for y in range(h))
ch = lambda t, d: struct.pack(">I", len(d)) + t + d + struct.pack(">I", zlib.crc32(t + d) & 0xFFFFFFFF)
open(out, "wb").write(b"\x89PNG\r\n\x1a\n" + ch(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0)) + ch(b"IDAT", zlib.compress(raw)) + ch(b"IEND", b""))
