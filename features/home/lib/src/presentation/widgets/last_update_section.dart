import 'package:flutter/material.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

class LastUpdateSection extends StatelessWidget {
  const LastUpdateSection({
    required this.date, super.key,
  });

  final String date;

  @override
  Widget build(BuildContext context) => Text(
        date,
        style: PicoTextStyle.bodySm(
          fontWeight: FontWeight.w400,
        ),
      );
}
