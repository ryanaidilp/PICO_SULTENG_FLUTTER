import 'package:flutter/material.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

@immutable
class CaseData {
  const CaseData({
    required this.iconColor,
    required this.bgColor,
    required this.iconData,
    required this.label,
  });
  final Color iconColor;
  final Color bgColor;
  final PicoIcons iconData;
  final String label;
}
