"""Renders an SVG or a Lottie (.json or .lottie) to PNG previews you can look at.

    python3 preview.py <file> [--out DIR] [--px 400] [--sizes 20,48,192] [--frames 6]

SVG: one sheet, the asset at each size on the light and the dark background.
Lottie: key frames on both backgrounds, a contact sheet, the same frames at
display size blown up 3x, and an animated GIF per theme.
A `<name>_dark.<ext>` beside the file is used for the dark row.
"""

import argparse
import io
import json
import os
import subprocess
import tempfile
import zipfile
from pathlib import Path

import numpy as np
from PIL import Image

BRAND_JSON = Path(os.environ.get("BRAND_JSON", "design/brand/brand.json"))
BACKGROUNDS = {"light": "#FFFFFF", "dark": "#0B0C0E"}
# What currentColor renders as on each background (the "ink" slot, if any).
INK = {"light": "#0F172A", "dark": "#F8FAFC"}
if BRAND_JSON.exists():
    brand = json.loads(BRAND_JSON.read_text())
    BACKGROUNDS.update(brand.get("backgrounds", {}))
    INK.update(brand.get("slots", {}).get("ink", {}))


def dark_twin(path):
    twin = path.with_name(f"{path.stem}_dark{path.suffix}")
    return twin if twin.exists() else path


def rgb(hexv):
    return tuple(int(hexv[i : i + 2], 16) for i in (1, 3, 5))


def svg_png(svg, px, bg, ink):
    with tempfile.NamedTemporaryFile("w", suffix=".css") as css:
        css.write("svg { color: %s; }" % ink)  # no f-string: the file is a Mason template
        css.flush()
        out = subprocess.run(
            ["rsvg-convert", "-w", str(px), "-h", str(px), "-a", "-b", bg, "-s", css.name, str(svg)],
            check=True,
            capture_output=True,
        ).stdout
    return Image.open(io.BytesIO(out)).convert("RGB")


def svg_sheet(svg, sizes, out):
    pad = 16
    cell = max(sizes) + pad * 2
    sheet = Image.new("RGB", (cell * len(sizes), cell * 2))
    for row, (theme, bg) in enumerate(BACKGROUNDS.items()):
        source = svg if theme == "light" else dark_twin(svg)
        for col, px in enumerate(sizes):
            tile = Image.new("RGB", (cell, cell), rgb(bg))
            im = svg_png(source, px, bg, INK[theme])
            tile.paste(im, ((cell - im.width) // 2, (cell - im.height) // 2))
            sheet.paste(tile, (col * cell, row * cell))
    path = out / f"{svg.stem}_sheet.png"
    sheet.save(path)
    return [path]


def lottie_json(path):
    """The animation JSON of a .json, or of the first animation in a .lottie."""
    if path.suffix != ".lottie":
        return path.read_text()
    with zipfile.ZipFile(path) as z:
        names = [n for n in z.namelist() if n.endswith(".json") and Path(n).name != "manifest.json"]
        names.sort(key=lambda n: not n.startswith(("animations/", "a/")))
        return z.read(names[0]).decode()


def frames_of(path, px, bg):
    # pip install rlottie-python: it honours layer order and mattes, unlike an SVG export.
    from rlottie_python import LottieAnimation

    anim = LottieAnimation.from_data(lottie_json(path))
    back = np.array(rgb(bg), dtype=np.float32)
    for f in range(anim.lottie_animation_get_totalframe()):
        im = np.asarray(anim.render_pillow_frame(frame_num=f, width=px, height=px), dtype=np.float32)
        # rlottie returns premultiplied RGBA: composite as src + bg * (1 - alpha).
        out = im[..., :3] + back * (1 - im[..., 3:] / 255)
        yield Image.fromarray(out.clip(0, 255).astype(np.uint8))


def lottie_previews(path, px, frames, out):
    meta = json.loads(lottie_json(path))
    fps = meta.get("fr", 30)
    written, rows = [], []
    for theme, bg in BACKGROUNDS.items():
        seq = list(frames_of(path if theme == "light" else dark_twin(path), px, bg))
        picks = [seq[round((len(seq) - 1) * i / max(frames - 1, 1))] for i in range(frames)]
        rows.append(picks)
        gif = out / f"{path.stem}_{theme}.gif"
        seq[0].save(gif, save_all=True, append_images=seq[1:], duration=round(1000 / fps), loop=0, disposal=2)
        written.append(gif)
    sheet = Image.new("RGB", (px * frames, px * 2))
    for y, row in enumerate(rows):
        for x, im in enumerate(row):
            sheet.paste(im, (x * px, y * px))
    keyframes = out / f"{path.stem}_keyframes.png"
    sheet.save(keyframes)
    # Real display size (64 px), blown up 3x with hard pixels: blur and thin strokes show here.
    small = sheet.resize((64 * frames, 128), Image.LANCZOS)
    x3 = out / f"{path.stem}_64px_x3.png"
    small.resize((small.width * 3, small.height * 3), Image.NEAREST).save(x3)
    return [keyframes, x3, *written]


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("file", type=Path)
    ap.add_argument("--out", type=Path, default=Path("build/brand-previews"))
    ap.add_argument("--px", type=int, default=400, help="Lottie frame size")
    ap.add_argument("--sizes", default="20,48,192", help="SVG sizes, comma-separated")
    ap.add_argument("--frames", type=int, default=6, help="Lottie key frames per row")
    args = ap.parse_args()
    args.out.mkdir(parents=True, exist_ok=True)
    if args.file.suffix == ".svg":
        paths = svg_sheet(args.file, [int(s) for s in args.sizes.split(",")], args.out)
    else:
        paths = lottie_previews(args.file, args.px, args.frames, args.out)
    for p in paths:
        print(p)


if __name__ == "__main__":
    main()
