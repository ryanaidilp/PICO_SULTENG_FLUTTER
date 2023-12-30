import 'package:flutter/material.dart';

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
  final IconData iconData;
  final String label;
}
