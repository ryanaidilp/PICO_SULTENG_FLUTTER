// PICO palette (the original app look, restored; the Tenun weave look was
// dropped). Primitives live in [PicoBrandPalette]. Widgets read semantic roles
// through `Theme.of(context).extension<PicoStateColors>()!`, never the
// primitives.
//
// Rule: state is never colour alone. Pair every role colour with its line form
// ([PicoLineForm]), mark ([PicoMark]) and a text label. The weave patterns are
// no longer drawn; [PicoWeave] only names the role.

import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Brand primitives (light and dark).
abstract final class PicoBrandPalette {
  // PICO palette, restored from the original app (warm grey neutrals and the
  // 0B92D5 blue). Names are kept from the first rewrite so every component
  // keeps compiling: paper = page, surface = card, cottonDeep = subtle layer,
  // tint = strong layer and selected wash, indigo = deep action blue.
  // Text-safe steps are used wherever a colour carries text (AA on paper and
  // card); 0B92D5 itself (3.3:1 on paper) is only for non-text marks.
  static const Color paperLight = Color(0xFFF9F8F6);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cottonDeepLight = Color(0xFFF3F1EE);
  static const Color tintLight = Color(0xFFE1F2FD);
  static const Color indigoLight = Color(0xFF0C5880);
  static const Color skyLight = Color(0xFF17A4E0);
  static const Color primaryLight = Color(0xFF0B92D5);
  static const Color primaryStrongLight = Color(0xFF09689B);
  static const Color crimsonLight = Color(0xFFC8261A);
  static const Color inkLight = Color(0xFF24221F);
  static const Color inkMutedLight = Color(0xFF535352);
  static const Color lineLight = Color(0xFFD5D4D2);
  static const Color lineStrongLight = Color(0xFF737271);
  static const Color onIndigoLight = Color(0xFFFFFFFF);
  static const Color onPrimaryLight = Color(0xFFFFFFFF);
  static const Color dyeMaroonLight = Color(0xFFB42318);
  static const Color dyeGoldLight = Color(0xFFB28000);
  static const Color dyeBarkLight = Color(0xFF7A5900);
  static const Color positiveLight = Color(0xFF09689B);
  static const Color recoveredLight = Color(0xFF087443);
  static const Color deceasedLight = Color(0xFFB42318);
  static const Color activeLight = Color(0xFF8A5A00);
  static const Color rtLight = Color(0xFF5E3BC6);

  static const Color paperDark = Color(0xFF24221F);
  static const Color surfaceDark = Color(0xFF302E2C);
  static const Color cottonDeepDark = Color(0xFF3A3836);
  static const Color tintDark = Color(0xFF0C3A52);
  static const Color indigoDark = Color(0xFF82D2F7);
  static const Color skyDark = Color(0xFF40BBF0);
  static const Color primaryDark = Color(0xFF40BBF0);
  static const Color primaryStrongDark = Color(0xFF40BBF0);
  static const Color crimsonDark = Color(0xFFF97066);
  static const Color inkDark = Color(0xFFF3F1EE);
  static const Color inkMutedDark = Color(0xFFA4A3A2);
  static const Color lineDark = Color(0xFF41403E);
  static const Color lineStrongDark = Color(0xFF8E8D8B);
  static const Color onIndigoDark = Color(0xFF24221F);
  static const Color onPrimaryDark = Color(0xFF24221F);
  static const Color dyeMaroonDark = Color(0xFFF97066);
  static const Color dyeGoldDark = Color(0xFFFDC941);
  static const Color dyeBarkDark = Color(0xFFFDC941);
  static const Color positiveDark = Color(0xFF40BBF0);
  static const Color recoveredDark = Color(0xFF3CCB7F);
  static const Color deceasedDark = Color(0xFFF97066);
  static const Color activeDark = Color(0xFFFDC941);
  static const Color rtDark = Color(0xFFA197EE);

  /// Magnitude ramp: mark size in logical px; area doubles per step.
  static const List<double> markRamp = <double>[4, 6, 8, 11, 16, 23];
}

/// Fill pattern for a data role (SVG tiles in brand/patterns/).
enum PicoWeave {
  plain('tenun polos', 'assets/patterns/pico-weave-positive.svg'),
  steppedDiamond(
    'belah ketupat berundak',
    'assets/patterns/pico-weave-recovered.svg',
  ),
  doubleThread('benang ganda', 'assets/patterns/pico-weave-deceased.svg'),
  dashedWeft('pakan putus-putus', 'assets/patterns/pico-weave-active.svg'),
  hatched('arsir', 'assets/patterns/pico-weave-rt.svg');

  new(this.labelId, this.asset);
  final String labelId;
  final String asset;
}

/// How a series line is drawn.
enum PicoLineForm { solid, dotted, doubled, dashed }

/// Mark shape at a data point.
enum PicoMark { square, diamond, bars, triangle, ring }

/// Semantic COVID-19 states: bilingual label, weave, line form and mark.
enum PicoState {
  positive(
    'Positif',
    'Positive',
    PicoWeave.plain,
    PicoLineForm.solid,
    PicoMark.square,
  ),
  recovered(
    'Sembuh',
    'Recovered',
    PicoWeave.steppedDiamond,
    PicoLineForm.dotted,
    PicoMark.diamond,
  ),
  deceased(
    'Meninggal',
    'Deceased',
    PicoWeave.doubleThread,
    PicoLineForm.doubled,
    PicoMark.bars,
  ),
  active(
    'Dirawat',
    'Active',
    PicoWeave.dashedWeft,
    PicoLineForm.dashed,
    PicoMark.triangle,
  ),
  rt('Rt', 'Rt', PicoWeave.hatched, PicoLineForm.solid, PicoMark.ring);

  new(this.labelId, this.labelEn, this.weave, this.line, this.mark);
  final String labelId;
  final String labelEn;
  final PicoWeave weave;
  final PicoLineForm line;
  final PicoMark mark;

  /// Dash pattern for dotted / dashed lines (logical px).
  List<double>? get dash => switch (line) {
    PicoLineForm.dashed => const <double>[6, 4],
    PicoLineForm.dotted => const <double>[0.1, 4],
    _ => null,
  };
}

/// Colours for the semantic states. Register on both ThemeData objects.
@immutable
class PicoStateColors extends ThemeExtension<PicoStateColors> {
  const new({
    required this.positive,
    required this.recovered,
    required this.deceased,
    required this.active,
    required this.rt,
  });

  final Color positive;
  final Color recovered;
  final Color deceased;
  final Color active;
  final Color rt;

  static const PicoStateColors light = PicoStateColors(
    positive: PicoBrandPalette.positiveLight,
    recovered: PicoBrandPalette.recoveredLight,
    deceased: PicoBrandPalette.deceasedLight,
    active: PicoBrandPalette.activeLight,
    rt: PicoBrandPalette.rtLight,
  );

  static const PicoStateColors dark = PicoStateColors(
    positive: PicoBrandPalette.positiveDark,
    recovered: PicoBrandPalette.recoveredDark,
    deceased: PicoBrandPalette.deceasedDark,
    active: PicoBrandPalette.activeDark,
    rt: PicoBrandPalette.rtDark,
  );

  Color of(PicoState s) => switch (s) {
    PicoState.positive => positive,
    PicoState.recovered => recovered,
    PicoState.deceased => deceased,
    PicoState.active => active,
    PicoState.rt => rt,
  };

  @override
  PicoStateColors copyWith({
    Color? positive,
    Color? recovered,
    Color? deceased,
    Color? active,
    Color? rt,
  }) => PicoStateColors(
    positive: positive ?? this.positive,
    recovered: recovered ?? this.recovered,
    deceased: deceased ?? this.deceased,
    active: active ?? this.active,
    rt: rt ?? this.rt,
  );

  @override
  PicoStateColors lerp(covariant PicoStateColors? other, double t) {
    if (other == null) return this;
    return PicoStateColors(
      positive: Color.lerp(positive, other.positive, t)!,
      recovered: Color.lerp(recovered, other.recovered, t)!,
      deceased: Color.lerp(deceased, other.deceased, t)!,
      active: Color.lerp(active, other.active, t)!,
      rt: Color.lerp(rt, other.rt, t)!,
    );
  }
}

/// Cloth surface colours for woven charts and bands.
@immutable
class PicoClothSurface extends ThemeExtension<PicoClothSurface> {
  const new({
    required this.tint,
    required this.cottonDeep,
    required this.weft,
    required this.accent,
    this.weftOpacity = 0.35,
  });

  final Color tint;
  final Color cottonDeep;
  final Color weft;
  final Color accent;
  final double weftOpacity;

  static const PicoClothSurface light = PicoClothSurface(
    tint: PicoBrandPalette.tintLight,
    cottonDeep: PicoBrandPalette.cottonDeepLight,
    weft: PicoBrandPalette.paperLight,
    accent: PicoBrandPalette.crimsonLight,
  );

  static const PicoClothSurface dark = PicoClothSurface(
    tint: PicoBrandPalette.tintDark,
    cottonDeep: PicoBrandPalette.cottonDeepDark,
    weft: PicoBrandPalette.paperDark,
    accent: PicoBrandPalette.crimsonDark,
  );

  @override
  PicoClothSurface copyWith({
    Color? tint,
    Color? cottonDeep,
    Color? weft,
    Color? accent,
    double? weftOpacity,
  }) => PicoClothSurface(
    tint: tint ?? this.tint,
    cottonDeep: cottonDeep ?? this.cottonDeep,
    weft: weft ?? this.weft,
    accent: accent ?? this.accent,
    weftOpacity: weftOpacity ?? this.weftOpacity,
  );

  @override
  PicoClothSurface lerp(covariant PicoClothSurface? other, double t) {
    if (other == null) return this;
    return PicoClothSurface(
      tint: Color.lerp(tint, other.tint, t)!,
      cottonDeep: Color.lerp(cottonDeep, other.cottonDeep, t)!,
      weft: Color.lerp(weft, other.weft, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      weftOpacity: lerpDouble(weftOpacity, other.weftOpacity, t)!,
    );
  }
}

/// Seed ColorSchemes. The ui kit maps these onto its own foundation tokens.
abstract final class PicoColorSchemes {
  static const ColorScheme light = ColorScheme(
    brightness: Brightness.light,
    primary:
        PicoBrandPalette.primaryStrongLight, // logo-blue hue, text-safe step
    onPrimary: PicoBrandPalette.onPrimaryLight,
    primaryContainer: PicoBrandPalette.tintLight,
    onPrimaryContainer: PicoBrandPalette.indigoLight,
    secondary: PicoBrandPalette.crimsonLight,
    onSecondary: PicoBrandPalette.surfaceLight,
    tertiary: PicoBrandPalette.indigoLight,
    onTertiary: PicoBrandPalette.onIndigoLight,
    error: PicoBrandPalette.crimsonLight,
    onError: PicoBrandPalette.surfaceLight,
    surface: PicoBrandPalette.paperLight,
    onSurface: PicoBrandPalette.inkLight,
    onSurfaceVariant: PicoBrandPalette.inkMutedLight,
    outline: PicoBrandPalette.lineStrongLight,
    outlineVariant: PicoBrandPalette.lineLight,
  );

  static const ColorScheme dark = ColorScheme(
    brightness: Brightness.dark,
    primary: PicoBrandPalette.primaryDark,
    onPrimary: PicoBrandPalette.onPrimaryDark,
    primaryContainer: PicoBrandPalette.tintDark,
    onPrimaryContainer: PicoBrandPalette.indigoDark,
    secondary: PicoBrandPalette.crimsonDark,
    onSecondary: PicoBrandPalette.paperDark,
    tertiary: PicoBrandPalette.indigoDark,
    onTertiary: PicoBrandPalette.onIndigoDark,
    error: PicoBrandPalette.crimsonDark,
    onError: PicoBrandPalette.paperDark,
    surface: PicoBrandPalette.paperDark,
    onSurface: PicoBrandPalette.inkDark,
    onSurfaceVariant: PicoBrandPalette.inkMutedDark,
    outline: PicoBrandPalette.lineStrongDark,
    outlineVariant: PicoBrandPalette.lineDark,
  );
}
