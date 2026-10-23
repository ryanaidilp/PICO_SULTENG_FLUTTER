import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pico_ui_kit/src/components/atoms/brand/pico_themed_svg.dart';
import 'package:pico_ui_kit/src/foundations/colors/pico_brand_palette.dart';

/// Rasterises the role weave tiles (`pico-weave-*.svg`) into images, once per
/// theme and device pixel ratio, and hands out repeating [ImageShader]s for
/// chart fills (ADR-0107). Painters ask [shaderIfReady] and fall back to a
/// solid role colour until the first rasterisation ends.
///
/// The district band weaves are not rasterised: they wait for the cultural
/// review (O-12).
class WeaveShaderCache {
  new _();

  /// The shared cache.
  static final WeaveShaderCache instance = WeaveShaderCache._();

  final Map<String, Future<ui.Image>> _pending = {};
  final Map<String, ui.Image> _ready = {};

  String _key(PicoState s, Brightness b, double dpr) =>
      '${s.name}|${b.name}|$dpr';

  /// Loads and rasterises the tile of [state]. Safe to call many times.
  Future<ui.Image> load(PicoState state, Brightness brightness, double dpr) {
    final key = _key(state, brightness, dpr);
    return _pending.putIfAbsent(key, () async {
      final svg = await PicoSvgSource.load(state.weave.asset, brightness);
      final info = await vg.loadPicture(SvgStringLoader(svg), null);
      final side = (56 * dpr).round();
      final recorder = ui.PictureRecorder();
      ui.Canvas(recorder)
        ..scale(dpr)
        ..drawPicture(info.picture);
      final image = await recorder.endRecording().toImage(side, side);
      _ready[key] = image;
      return image;
    });
  }

  /// The tile as a repeating shader, or null while it is not rasterised yet.
  ui.ImageShader? shaderIfReady(
    PicoState state,
    Brightness brightness,
    double dpr,
  ) {
    final image = _ready[_key(state, brightness, dpr)];
    if (image == null) return null;
    return ImageShader(
      image,
      TileMode.repeated,
      TileMode.repeated,
      (Matrix4.identity()..scale(1 / dpr)).storage,
    );
  }

  /// Rasterises all five role tiles. Call before the first paint to avoid the
  /// solid fallback.
  Future<void> warmUp(Brightness brightness, double dpr) =>
      Future.wait([for (final s in PicoState.values) load(s, brightness, dpr)]);

  /// Drops every image (tests).
  void clear() {
    _pending.clear();
    _ready.clear();
  }
}
