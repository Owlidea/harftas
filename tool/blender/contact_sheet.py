# Lays PNGs out on one sheet (light + dark background rows) for review.
#   blender -b --factory-startup -P tool/blender/contact_sheet.py -- <out.png> <cell_px> <in.png> ...
import bpy, sys, zlib, struct
import numpy as np
a = sys.argv[sys.argv.index("--") + 1:]
out, cell, files = a[0], int(a[1]), a[2:]
def load(p):
    img = bpy.data.images.load(p); img.colorspace_settings.name = 'Non-Color'
    w, h = img.size
    px = np.array(img.pixels[:], dtype=np.float32).reshape(h, w, 4)[::-1]
    step = max(w // cell, 1)
    px = px[:h - h % step, :w - w % step].reshape(h // step, step, w // step, step, 4)
    al = px[..., 3:4]
    rgb = (px[..., :3] * al).sum(axis=(1, 3)) / np.maximum(al.sum(axis=(1, 3)), 1e-6)
    return np.dstack([rgb, al.mean(axis=(1, 3))])[:cell, :cell]
sheet = np.zeros((cell * 2, cell * len(files), 3), dtype=np.float32)
for r, bg in enumerate(((0.965, 0.953, 0.925), (0.059, 0.09, 0.161))):
    for c, f in enumerate(files):
        px = load(f); h, w, _ = px.shape
        base = np.ones((cell, cell, 3), dtype=np.float32) * np.array(bg, dtype=np.float32)
        base[:h, :w] = base[:h, :w] * (1 - px[..., 3:4]) + px[..., :3] * px[..., 3:4]
        sheet[r * cell:(r + 1) * cell, c * cell:(c + 1) * cell] = base
b = (np.clip(sheet, 0, 1) * 255 + 0.5).astype(np.uint8); h, w, _ = b.shape
raw = b"".join(b"\x00" + b[y].tobytes() for y in range(h))
ch = lambda t, d: struct.pack(">I", len(d)) + t + d + struct.pack(">I", zlib.crc32(t + d) & 0xFFFFFFFF)
open(out, "wb").write(b"\x89PNG\r\n\x1a\n" + ch(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0)) + ch(b"IDAT", zlib.compress(raw)) + ch(b"IEND", b""))
