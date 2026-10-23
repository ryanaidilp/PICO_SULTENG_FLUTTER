"""Example: the logo builds in once (1.5 s). Each piece of the mark settles into place from above, lowest first, so a piece never passes through the ones already placed.

Copy to design/motion/<name>.py and adapt; it animates the real mark, never a redraw.
A mark whose SVG has no separate pieces (one group of paths) settles in as a whole.

    python3 .claude/skills/brand-assets/scripts/examples/logo_reveal.py <mark.svg> <out_dir>
"""

import sys
from pathlib import Path
from xml.etree import ElementTree

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from lottie_kit import NVector, animation, easing, keys, layer, objects, save, svg_shapes  # noqa: E402

SIZE, FRAMES = 256, 45  # px, frames at 30 fps
DROP, STAGGER, DURATION = 0.12, 8, 18  # drop as a share of the mark's height, frames between pieces, frames per piece


def view_box(svg):
    root = ElementTree.parse(svg).getroot()
    if root.get("viewBox"):
        _, _, w, h = (float(v) for v in root.get("viewBox").replace(",", " ").split())
    else:
        w, h = float(root.get("width")), float(root.get("height"))
    return w, h


def main(svg, out_dir):
    w, h = view_box(svg)
    anim = animation(SIZE, FRAMES)
    mark = svg_shapes(svg)
    root = mark.shapes[0]
    pieces = [s for s in root.shapes if isinstance(s, objects.Group)] or [root]
    pieces.sort(key=lambda g: -g.bounding_box(0).y2)  # lowest piece first

    out = easing.Sigmoid(0.2)  # decelerates into place
    centre = (w / 2, h / 2)
    for i, piece in enumerate(pieces):
        start = i * STAGGER
        piece.transform.anchor_point.value = NVector(*centre)
        piece.transform.position.value = NVector(*centre)
        keys(piece.transform.position, [(start, (centre[0], centre[1] - DROP * h)), (start + DURATION, centre)], out)
        keys(piece.transform.opacity, [(start, 0), (start + DURATION * 2 // 3, 100)], out)

    lay = layer(anim, "mark", mark)
    # Fit the mark with a 10% margin, so the drop never leaves the canvas.
    zoom = SIZE / max(w, h) * 80
    lay.transform.anchor_point.value = NVector(*centre)
    lay.transform.position.value = NVector(SIZE / 2, SIZE / 2)
    lay.transform.scale.value = NVector(zoom, zoom)
    save(anim, Path(svg).stem + "_reveal", out_dir)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
