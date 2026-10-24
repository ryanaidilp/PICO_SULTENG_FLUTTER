"""Small python-lottie helpers for brand animations.

Every fill and stroke is named after a color slot from design/brand/brand.json,
so save() can write a dark twin by slot and nothing ships with an unnamed color.

    from lottie_kit import *
    anim = animation(120, 60)  # 120 px square, 60 frames at 30 fps
    ...
    save(anim, "logo_pulse", "packages/<app>_asset/assets/animations")
"""

import copy
import json
import os
import re
from pathlib import Path
from xml.etree import ElementTree

from lottie import NVector, objects
from lottie.objects import easing
from lottie.parsers.svg import parse_svg_etree

BRAND_JSON = Path(os.environ.get("BRAND_JSON", "design/brand/brand.json"))
BRAND = json.loads(BRAND_JSON.read_text()) if BRAND_JSON.exists() else {}
SLOTS = BRAND.get("slots", {})


def _rgb(hexv):
    return [int(hexv[i : i + 2], 16) / 255 for i in (1, 3, 5)]


def color(slot, theme="light"):
    assert slot in SLOTS, f"{slot!r} is not a slot in {BRAND_JSON} (copy brand.example.json there first)"
    return objects.Color(*_rgb(SLOTS[slot][theme]))


def fill(slot):
    f = objects.Fill(color(slot))
    f.name = slot
    return f


def stroke(slot, width=4):
    s = objects.Stroke(color(slot), width)
    s.name = slot
    s.line_cap = objects.LineCap.Round
    s.line_join = objects.LineJoin.Round
    return s


def group(name, *shapes):
    g = objects.Group()
    g.name = name
    for s in shapes:
        g.add_shape(s)
    return g


def ellipse(cx, cy, w, h):
    return objects.Ellipse(NVector(cx, cy), NVector(w, h))


def rect(cx, cy, w, h, r=0):
    return objects.Rect(NVector(cx, cy), NVector(w, h), r)


def path(points, closed=True):
    """A straight-edged path through (x, y) points."""
    bez = objects.Bezier()
    for x, y in points:
        bez.add_point(NVector(x, y))
    if closed:
        bez.close()
    return objects.Path(bez)


def animation(size, frames, fps=30):
    anim = objects.Animation(frames, fps)
    anim.width = anim.height = size
    return anim


def layer(anim, name, *shapes):
    lay = objects.ShapeLayer()
    lay.name = name
    lay.in_point, lay.out_point = 0, anim.out_point
    for s in shapes:
        lay.add_shape(s)
    anim.insert_layer(0, lay)  # later layers draw on top
    return lay


def keys(prop, frames_values, ease=easing.Sigmoid()):
    """Keyframes from (frame, value) pairs; a tuple value becomes a vector."""
    for t, v in frames_values:
        prop.add_keyframe(t, NVector(*v) if isinstance(v, tuple) else v, ease)


def svg_shapes(svg_path):
    """The shapes of an SVG (a logo mark) as one group, colors mapped to slots.

    Reuse the real mark instead of redrawing it. A fill or stroke whose color
    is not a slot's light value raises, so the dark twin cannot miss it.
    """
    tree = ElementTree.parse(svg_path)
    for el in tree.iter():
        if el.tag.endswith("path") and el.get("d"):
            el.set("d", normalise_path(el.get("d")))
    parsed = parse_svg_etree(tree)
    by_hex = {_hex(_rgb(v["light"])): k for k, v in SLOTS.items()}
    out = group(Path(svg_path).stem)
    for lay in parsed.layers:
        for shape in lay.shapes:
            _name_colors(shape, by_hex)
            out.add_shape(shape)
    return out


_NUM = re.compile(r"[-+]?(?:\d*\.\d+|\d+\.?)(?:[eE][-+]?\d+)?")


def normalise_path(d):
    """Spaces out path data. Minified SVG (svgo) writes arc flags with no
    separator (`a25 25 0 0193 228`), which python-lottie misreads."""
    out, i, cmd, n = [], 0, "", 0
    while i < len(d):
        c = d[i]
        if c in " ,\t\r\n":
            i += 1
        elif c.isalpha():
            cmd, n = c, 0
            out.append(c)
            i += 1
        elif cmd in "Aa" and n % 7 in (3, 4):  # large-arc and sweep flags: one character
            out.append(c)
            i, n = i + 1, n + 1
        else:
            m = _NUM.match(d, i)
            if not m:
                raise ValueError(f"bad path data at {i}: {d[i:i + 20]!r}")
            out.append(m.group())
            i, n = m.end(), n + 1
    return " ".join(out)


def _hex(rgb):
    return "#" + "".join(f"{round(c * 255):02X}" for c in rgb[:3])


def _name_colors(node, by_hex):
    if isinstance(node, (objects.Fill, objects.Stroke)):
        hexv = _hex(node.color.value)
        assert hexv in by_hex, f"{hexv} in the SVG is not a slot in {BRAND_JSON}"
        node.name = by_hex[hexv]
    for child in getattr(node, "shapes", []):
        _name_colors(child, by_hex)


def _themed(data, theme):
    """Recolors every fill and stroke by its slot name; raises on one with no slot."""
    data = copy.deepcopy(data)

    def walk(node):
        if isinstance(node, dict):
            # rlottie reads a layer as 3D unless "ddd" comes before "ks";
            # python-lottie drops "ddd": 0, so put it back first.
            if isinstance(node.get("ty"), int) and "ks" in node and "ddd" not in node:
                rest = dict(node)
                node.clear()
                node.update({"ty": rest.pop("ty"), "ddd": 0, **rest})
            if node.get("ty") in ("fl", "st"):
                slot = node.get("nm")
                assert slot in SLOTS, f"unslotted {node['ty']} named {slot!r}"
                node["c"] = {"a": 0, "k": [round(c, 4) for c in _rgb(SLOTS[slot][theme])] + [1]}
            for v in node.values():
                walk(v)
        elif isinstance(node, list):
            for v in node:
                walk(v)

    walk(data)
    return data


def save(anim, name, out_dir):
    """Writes <name>.json and <name>_dark.json; returns their paths."""
    out = Path(out_dir)
    out.mkdir(parents=True, exist_ok=True)
    data = anim.to_dict()
    paths = []
    for theme, suffix in (("light", ""), ("dark", "_dark")):
        p = out / f"{name}{suffix}.json"
        p.write_text(json.dumps(_round(_themed(data, theme)), separators=(",", ":")))
        paths.append(p)
        print(f"wrote {p} ({p.stat().st_size} bytes)")
    return paths


def _round(node):
    if isinstance(node, float):
        return round(node, 3)
    if isinstance(node, dict):
        return {k: _round(v) for k, v in node.items()}
    if isinstance(node, list):
        return [_round(v) for v in node]
    return node


if __name__ == "__main__":  # self-check: python3 lottie_kit.py
    assert normalise_path("M1 2a25.032 25.032 0 0193.342 228z") == "M 1 2 a 25.032 25.032 0 0 1 93.342 228 z"
    assert normalise_path("M1-2.5.5L3,4") == "M 1 -2.5 .5 L 3 4"
    assert normalise_path("A1 1 0 1 1 5 5 1 1 0 0 0 6 6") == "A 1 1 0 1 1 5 5 1 1 0 0 0 6 6"
    print("ok")
