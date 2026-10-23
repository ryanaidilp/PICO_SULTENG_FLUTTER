---
name: brand-assets
description: Use when designing or producing brand art in code for this app - SVG icons and illustrations, Lottie animations written with python-lottie, festive variants of the logo, app icon or splash - and when converting Lottie .json to .lottie (dotLottie) or back, or wiring new art into the asset package, launcher icons, splash and Widgetbook.
---

# Brand Assets

You draw brand art as code (SVG, python-lottie), and you judge it by what it looks like rendered, never by its source. Every asset ends rendered to PNG, looked at, fixed, and wired into the asset package.

## Before you draw

Read the brand truth, in this order:

1. `PRODUCT.md`, `DESIGN.md`, `MOTION.md` or a brand doc, if the project has one.
2. The UI kit color tokens: `packages/pico_ui_kit/lib/src/foundations/colors/` (`*_color_token.dart` holds the palette, `*_color_foundation.dart` maps it to roles).
3. The existing marks: `packages/pico_asset/assets/logos/`, `apps/pico/launcher/`, `apps/pico/splash/` and `flutter_native_splash.yaml` (splash colors).

A new asset extends the mark. It never redraws it.

Then set up once:

```bash
pip install -r .claude/skills/brand-assets/scripts/requirements.txt   # python-lottie, rlottie-python, Pillow, numpy
npm install --prefix .claude/skills/brand-assets/scripts             # @dotlottie/dotlottie-js (LottieFiles)
brew install librsvg                                                 # rsvg-convert (apt: librsvg2-bin)
mkdir -p design/brand && cp .claude/skills/brand-assets/scripts/brand.example.json design/brand/brand.json
```

Fill `design/brand/brand.json` from the UI kit tokens: one **slot** per color the art uses, each with a light and a dark value, plus the light and dark page backgrounds. The scripts read it (override the path with `BRAND_JSON=...`). Run every command from the workspace root.

## Where files go

| What | Source (committed) | Shipped |
|---|---|---|
| Icon | `design/icons/<name>.svg` | `packages/pico_asset/assets/icons/<category>/<name>.svg` |
| Illustration | `design/illustrations/<name>.svg` | `packages/pico_asset/assets/illustrations/<name>.svg` (+ `<name>_dark.svg`) |
| Logo, festive mark | `design/brand/festive/<occasion>/<name>.svg` | `packages/pico_asset/assets/logos/` |
| Animation | `design/motion/<name>.py` -> `design/motion/out/<name>.json` | `packages/pico_asset/assets/animations/<name>.lottie` (+ `<name>_dark.lottie`) |
| App icon, splash | `design/brand/...svg` | PNGs in `apps/pico/launcher/` and `splash/` |

A `<name>_dark.<ext>` beside an asset is its dark variant: the asset generator wires it automatically.

## Craft rules

- Few deliberate shapes. Optical balance over mathematical symmetry. One stroke width, corner radius and grid across a set.
- Icons: 24 px viewBox, 2 px stroke, round caps and joins, `stroke="currentColor"` (or `fill`), so the widget can tint them. An icon must read at 20 and 24 px.
- Illustrations must read at 160 and 64 px. Use slot colors from `brand.json`, never arbitrary hex.
- People, when a scene needs them: real anatomy (head about 1/6 to 1/7 of the body, neck, shoulders, hands with fingers), complete faces, a range of skin tones and dress. Draw one figure and render it at 320 and 160 px before you draw a set: a stiff figure is worse than none.
- Motion follows `MOTION.md` if it exists. Otherwise entrances decelerate, exits are faster than entrances, and nothing loops as decoration (a loader may loop).

## Lottie from code

Write the generator as `design/motion/<name>.py` with the helpers in `scripts/lottie_kit.py`. Every fill and stroke is named after a slot, so `save()` writes the dark twin by slot and fails on an unnamed color. To animate the logo, parse the real SVG with `svg_shapes()` instead of redrawing it. `scripts/examples/logo_reveal.py` is a worked example:

```bash
python3 .claude/skills/brand-assets/scripts/examples/logo_reveal.py design/brand/mark.svg design/motion/out
# wrote design/motion/out/mark_reveal.json, design/motion/out/mark_reveal_dark.json
```

Give layers and shapes stable names; keep the JSON small (`save()` rounds numbers).

## Lottie .json <-> .lottie (dotLottie)

A `.lottie` is a zip holding `manifest.json` and the animation JSON (`a/<id>.json` in dotLottie v2, `animations/<id>.json` in v1). It is usually 70-90% smaller than the JSON. Ship the `.lottie`; keep the JSON as the design source. `scripts/dotlottie.mjs` uses the official LottieFiles library and validates what it writes:

```bash
D=.claude/skills/brand-assets/scripts/dotlottie.mjs
A=packages/pico_asset/assets/animations
node $D pack design/motion/out/mark_reveal.json -o $A/mark_reveal.lottie
node $D pack design/motion/out/mark_reveal_dark.json -o $A/mark_reveal_dark.lottie
node $D info $A/mark_reveal.lottie                     # valid? manifest
node $D unpack $A/mark_reveal.lottie design/motion/out # back to <id>.json
node $D pack a.json b.json -o set.lottie               # several animations, the first is the default
node $D pack a.json -o a.lottie --v1                   # v1 layout, for a player that only reads v1
```

Without Node, python-lottie converts too (`lottie_convert.py in.json out.lottie`, `lottie_convert.py in.lottie out.json`). It rewrites the animation through its object model, so prefer `dotlottie.mjs` for animations you did not write with python-lottie.

When a `.lottie` and a `.json` share a name in `assets/animations/`, the generator uses the `.lottie`. Remove a design-source `.json` from the package if you keep one there.

## Render loop (required)

```bash
P=.claude/skills/brand-assets/scripts/preview.py
python3 $P design/icons/<name>.svg --sizes 20,24,48             # icon
python3 $P design/illustrations/<name>.svg --sizes 64,160,320    # illustration
python3 $P $A/mark_reveal.lottie                                 # key frames, 64 px x3, GIF per theme
```

Previews go to `build/brand-previews/`. Open the PNGs (and the GIFs) and write a short critique: what is stiff, off-balance, clipped, blurry at 20 px, or generic. Fix it and render again; stop after two fix rounds. Render a `.lottie` you packed, not only its JSON, so you check what ships. `currentColor` renders as the `ink` slot.

## Festive variants (logo, app icon, splash)

- A festive variant dresses the mark; it never redraws it. The silhouette and primary color stay recognisable at 20 px. Change at most about a third of the area, with an accessory, a pattern fill or a color accent.
- Respect the occasion: national flags drawn correctly, no state emblems, no sacred text or religious symbols as decoration, the same care for every faith. Match the product's domain (a finance app shows saving and sharing, never money thrown around).
- Start about 6 weeks before the date. Default window: 3 days before to 2 days after.
- Render the variant next to the normal mark at 20, 48 and 192 px on both backgrounds before you wire it.

| Surface | How it changes |
|---|---|
| In-app mark, loader, empty state | A date-gated asset in the asset package, switched by a feature flag with a local date fallback. Same day. |
| Splash | Static in the binary. Ship it in a release before the date, or keep the normal splash and show the festive mark in the first frame. |
| App icon | Static too. Switching at runtime needs Android activity-alias / iOS alternate icons (not set up here); make it opt-in from Settings, never automatic. |

App icon and splash PNGs from SVG (flutter_launcher_icons scales from the 1024 px source; `-a` keeps the aspect ratio):

```bash
cd apps/pico
rsvg-convert -w 1024 -h 1024 -a ../../design/brand/festive/<occasion>/logo-icon.svg -o launcher/logo.png
dart run flutter_launcher_icons -f flutter_launcher_icons-production.yaml   # one file per flavor
dart run flutter_native_splash:create                                       # reads flutter_native_splash.yaml
```

`ios-logo.png` must have no alpha (`remove_alpha_ios: true`); the adaptive icon uses `logo-foreground.png` (mark only, inside the 66% safe zone) over `logo-background.png`.

## Wire it in

1. Copy the shipped files into `packages/pico_asset/assets/...`. A new folder (`illustrations/`) also goes under `flutter: assets:` in that package's `pubspec.yaml`, and a new icon category under `icon_categories` in its `asset_generator.yaml`.
2. `dart run monorepo_toolkit asset-gen generate` (or `melos run asset-gen:generate`) regenerates the type-safe enums. Never hand-edit `lib/src/generated/`.
3. `dart run monorepo_toolkit assets optimize --dry-run`, then without `--dry-run`, to shrink the SVG and PNG files.
4. Render through the UI kit's asset widget (`<Prefix>AssetWidget`, e.g. `AppAssetWidget.icon(...)`), never `Image.asset` or a raw path.
5. Show every new asset in Widgetbook: add a use case (light and dark) to `apps/pico_widgetbook/lib/showcase/atoms/asset_showcase.dart`, or a new showcase file registered in `widgetbook_app.dart`.
6. `melos run analyze`, and the UI kit's tests.

## Report

List the asset paths, the preview PNG and GIF paths, and the critique of the final round. Do not commit unless asked.
