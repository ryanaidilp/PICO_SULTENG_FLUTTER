import 'package:flutter/material.dart';
import 'package:i10n/i10n.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:pico_widgetbook/pico_widgetbook.dart';
import 'package:provider/provider.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) => TranslationProvider(
        child: PCComponentInit(
          builder: (_) => ChangeNotifierProvider(
            create: (context) => ThemeProvider(),
            child: Consumer<ThemeProvider>(
              builder: (_, themeState, __) => MaterialApp(
                title: 'PICO UI Kit',
                theme: PicoTheme.light(ThemeData.light()).themeData,
                darkTheme: PicoTheme.dark(ThemeData.dark()).themeData,
                themeMode: themeState.themeMode,
                home: const HomePage(),
              ),
            ),
          ),
        ),
      );
}
