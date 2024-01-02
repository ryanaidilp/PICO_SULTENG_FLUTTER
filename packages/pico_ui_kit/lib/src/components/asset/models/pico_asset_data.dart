import 'package:flutter/material.dart';
import 'package:pico_ui_kit/src/components/asset/enums/pico_asset_extension.dart';

@immutable
class PicoAssetData<T> {
  const PicoAssetData({
    required this.file,
    required this.extension,
  });
  final T file;
  final PicoAssetExtension extension;
}
