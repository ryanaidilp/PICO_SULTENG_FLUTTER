import 'package:flutter/material.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:pico_widgetbook/pico_widgetbook.dart';
import 'package:provider/provider.dart';

class ThemeSwitcherButton extends StatelessWidget {
  const ThemeSwitcherButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        final provider = context.read<ThemeProvider>();
        provider.isDark = !provider.isDark;
      },
      icon: Consumer<ThemeProvider>(
        builder: (_, themeState, __) => Icon(
          themeState.themeMode == ThemeMode.dark
              ? Icons.light_mode_rounded
              : Icons.dark_mode_rounded,
          color: context.picoColors.icon.neutral.main,
        ),
      ),
    );
  }
}
