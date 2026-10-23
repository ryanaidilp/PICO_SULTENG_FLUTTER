import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:ui_kit_generator/src/tailwind/tailwind_preset.dart';

// css name (without `--color-`) -> foundation constant. The dark variant is the
// constant with a `Dark` suffix, when the foundation defines one.
const _semanticColors = <String, String>{
  'bg': 'bgMain',
  'bg-subtle': 'bgSubtle',
  'bg-strong': 'bgStrong',
  'bg-inverse': 'bgInverse',
  'bg-card': 'bgCard',
  'bg-card-secondary': 'bgCardSecondary',
  'fg': 'foregroundMain',
  'fg-subtle': 'foregroundSubtle',
  'fg-muted': 'foregroundMuted',
  'fg-disabled': 'foregroundDisabled',
  'fg-inverse': 'foregroundInverse',
  'fg-primary': 'foregroundPrimary',
  'fg-success': 'foregroundSuccess',
  'fg-warning': 'foregroundWarning',
  'fg-error': 'foregroundError',
  'fg-info': 'foregroundInfo',
  'action-primary': 'actionPrimary',
  'action-primary-hover': 'actionPrimaryHover',
  'action-primary-disabled': 'actionPrimaryDisabled',
  'action-secondary': 'actionSecondary',
  'action-secondary-hover': 'actionSecondaryHover',
  'action-secondary-disabled': 'actionSecondaryDisabled',
  'action-destructive': 'actionDestructive',
  'action-destructive-hover': 'actionDestructiveHover',
  'action-destructive-disabled': 'actionDestructiveDisabled',
  'action-success': 'actionSuccess',
  'action-success-hover': 'actionSuccessHover',
  'action-success-disabled': 'actionSuccessDisabled',
  'border': 'outlineMain',
  'border-strong': 'outlineStrong',
  'border-subtle': 'outlineSubtle',
  'border-focus': 'outlineFocus',
  'success-bg': 'successBg',
  'warning-bg': 'warningBg',
  'error-bg': 'errorBg',
  'info-bg': 'infoBg',
  'overlay': 'overlay',
  'overlay-light': 'overlayLight',
};

final _decl = RegExp(r'static const ([\w<>]+) (\w+) =\s*([^;]*?);');

/// `name -> raw expression` for every `static const <type> name = expr;`.
Map<String, String> _consts(String src, [String? type]) => {
  for (final m in _decl.allMatches(src))
    if (type == null || m[1] == type) m[2]!: m[3]!.trim(),
};

String _read(String foundationsDir, String suffix) {
  final files =
      Directory(foundationsDir)
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith(suffix))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  if (files.isEmpty) {
    throw StateError('No *$suffix under $foundationsDir');
  }
  return files.map((f) => f.readAsStringSync()).join('\n');
}

String _tail(String expr) => expr.split('.').last;

/// Resolves a `Color(0x..)` literal or a (possibly chained) constant reference.
String _color(String expr, Map<String, String> colors) {
  final lit = RegExp(r'Color\(0x([0-9A-Fa-f]{8})\)').firstMatch(expr);
  if (lit != null) {
    final h = lit[1]!.toUpperCase();
    final rgb = h.substring(2);
    final a = h.substring(0, 2);
    return a == 'FF' ? '#$rgb' : '#$rgb$a';
  }
  final ref = colors[_tail(expr)];
  if (ref == null) throw StateError('Unresolved color: $expr');
  return _color(ref, colors);
}

num _num(String expr, Map<String, String> table) {
  final lit = num.tryParse(expr.trim());
  if (lit != null) return lit;
  final ref = table[_tail(expr.trim())];
  if (ref == null) throw StateError('Unresolved number: $expr');
  return _num(ref, table);
}

String _fmt(num v) => v == v.roundToDouble() ? '${v.round()}' : '$v';

String _rem(num px) {
  if (px == 0) return '0px';
  final s = (px / 16).toStringAsFixed(4).replaceAll(RegExp(r'0+$'), '');
  return '${s.endsWith('.') ? '${s}0' : s}rem';
}

String _px(num px) => px == 0 ? '0px' : '${_fmt(px)}px';

/// `bodyLarge` -> `body-large`.
String _kebab(String s) => s.replaceAllMapped(
  RegExp('([a-z0-9])([A-Z])'),
  (m) => '${m[1]}-${m[2]!.toLowerCase()}',
);

String _lowerFirst(String s) => s[0].toLowerCase() + s.substring(1);

String _fontName(String googleFontsMethod) =>
    _kebab(googleFontsMethod)
        .split('-')
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ')
        // google_fonts spells it jetBrainsMono; the family is "JetBrains Mono".
        .replaceFirst('Jet Brains', 'JetBrains');

List<String> _shadow(
  String list,
  Map<String, String> colors,
  Map<String, String> doubles,
  Map<String, String> offsets,
) {
  final parts = list.split('BoxShadow(').skip(1);
  return [
    for (final s in parts)
      () {
        String field(String name) =>
            RegExp('$name:\\s*(Offset\\([^)]*\\)|[\\w.\\-]+)')
                .firstMatch(s)![1]!;
        final off = RegExp(r'Offset\(\s*([-\d.]+)\s*,\s*([-\d.]+)\s*\)')
            .firstMatch(offsets[_tail(field('offset'))] ?? field('offset'))!;
        final dx = num.parse(off[1]!);
        final dy = num.parse(off[2]!);
        final spread = RegExp('spreadRadius:').hasMatch(s)
            ? _num(field('spreadRadius'), doubles)
            : 0;
        return [
          if (dx == 0) '0' else _px(dx),
          _px(dy),
          _px(_num(field('blurRadius'), doubles)),
          if (spread != 0) _px(spread),
          _color(field('color'), colors),
        ].join(' ');
      }(),
  ];
}

/// Reads the real ui_kit foundations (Dart source) under [uiKitPath] and maps
/// them to Tailwind variables. Parses source instead of importing the package
/// so it runs in plain Dart with no Flutter toolchain.
TailwindTokens readUiKitTokens(String uiKitPath) {
  final dir = p.join(uiKitPath, 'lib', 'src', 'foundations');
  final colorTokens = _consts(_read(dir, '_color_token.dart'), 'Color');
  final foundation = _consts(_read(dir, '_color_foundation.dart'), 'Color');
  final colors = {...colorTokens, ...foundation};

  final light = <String, String>{};
  final dark = <String, String>{};

  // Palettes: literal shades only, which skips the `gray*` -> `slate*` aliases.
  final palette = RegExp(r'^([a-z]+)(\d{2,3})$');
  for (final e in colorTokens.entries) {
    final m = palette.firstMatch(e.key);
    if (m == null || !e.value.startsWith('Color(')) continue;
    final name = m[1] == 'slate' ? 'neutral' : m[1];
    light['--color-$name-${m[2]}'] = _color(e.value, colors);
  }

  for (final e in _semanticColors.entries) {
    if (!foundation.containsKey(e.value)) continue;
    light['--color-${e.key}'] = _color(foundation[e.value]!, colors);
    final d = foundation['${e.value}Dark'];
    if (d != null) {
      dark['--color-${e.key}'] = _color(d, colors);
    }
  }

  // Dark action colors are literals inside AppActionColors.dark(), not
  // foundation constants.
  final actions = Directory(dir)
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('_action_colors.dart'))
      .map((f) => f.readAsStringSync())
      .join('\n');
  final darkBlock = actions.split(RegExp(r'\bdark\(\)')).skip(1).join();
  for (final m in RegExp(
    r'(primary|secondary|destructive|success):\s*\w+\(\s*'
    r'active:\s*([\w.]+),\s*hover:\s*([\w.]+),\s*disabled:\s*([\w.]+)',
  ).allMatches(darkBlock)) {
    dark['--color-action-${m[1]}'] = _color(m[2]!, colors);
    dark['--color-action-${m[1]}-hover'] = _color(m[3]!, colors);
    dark['--color-action-${m[1]}-disabled'] = _color(m[4]!, colors);
  }

  final fonts = _read(dir, '_font_family.dart');
  for (final f in {
    'sans': '_bodyFontFamily',
    'mono': '_monoFontFamily',
  }.entries) {
    final m = RegExp('${f.value}\\s*\\?\\?\\s*GoogleFonts\\.(\\w+)\\(')
        .firstMatch(fonts);
    if (m != null) light['--font-${f.key}'] = '"${_fontName(m[1]!)}"';
  }

  final type = _consts(_read(dir, '_typography_token.dart'));
  final typeNum = {
    for (final e in type.entries)
      if (num.tryParse(e.value) != null) e.key: e.value,
  };
  for (final e in type.entries) {
    final name = _kebab(_lowerFirst(e.key.replaceFirst(RegExp('^[a-z]+'), '')));
    if (e.key.startsWith('size')) {
      light['--text-$name'] = _rem(_num(e.value, typeNum));
    } else if (e.key.startsWith('weight')) {
      light['--font-weight-$name'] = e.value.replaceFirst('FontWeight.w', '');
    } else if (e.key.startsWith('height')) {
      light['--leading-$name'] = _fmt(_num(e.value, typeNum));
    } else if (e.key.startsWith('tracking')) {
      light['--tracking-$name'] = '${_fmt(_num(e.value, typeNum))}px';
    }
  }

  final spacing = _consts(_read(dir, '_spacing_token.dart'), 'double');
  for (final e in spacing.entries.where((e) => e.key != 'base')) {
    light['--spacing-${e.key}'] = _rem(_num(e.value, spacing));
  }

  final radius = _consts(_read(dir, '_radius_token.dart'), 'double');
  for (final e in radius.entries) {
    final v = _num(e.value, radius);
    light['--radius-${e.key}'] = v >= 9999 ? '9999px' : _px(v);
  }

  final shadowTokens = _read(dir, '_shadow_token.dart');
  colors.addAll(_consts(shadowTokens, 'Color'));
  final doubles = _consts(shadowTokens, 'double');
  final offsets = _consts(shadowTokens, 'Offset');
  final shadows = _consts(
    _read(dir, '_shadow_foundation.dart'),
    'List<BoxShadow>',
  );
  for (final e in shadows.entries) {
    final isDark = e.key.endsWith('Dark');
    final level = isDark ? e.key.substring(0, e.key.length - 4) : e.key;
    final layers = _shadow(e.value, colors, doubles, offsets);
    if (layers.isEmpty) continue;
    (isDark ? dark : light)['--shadow-$level'] = layers.join(', ');
  }

  return (light: light, dark: dark);
}
