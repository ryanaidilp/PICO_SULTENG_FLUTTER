import 'package:flutter/material.dart';

mixin PicoMaterialColor {
  MaterialColor lerpMaterialColor(
    MaterialColor a,
    MaterialColor b,
    double t,
  ) {
    return MaterialColor(
      _lerpColorComponent(t, a[500]!.red, b[500]!.red),
      <int, Color>{
        if (a[0] != null && b[0] != null)
          0: Color.fromARGB(
            _lerpColorComponent(t, a[0]!.alpha, b[0]!.alpha),
            _lerpColorComponent(t, a[0]!.red, b[0]!.red),
            _lerpColorComponent(t, a[0]!.green, b[0]!.green),
            _lerpColorComponent(t, a[0]!.blue, b[0]!.blue),
          ),
        if (a[25] != null && b[25] != null)
          0: Color.fromARGB(
            _lerpColorComponent(t, a[25]!.alpha, b[25]!.alpha),
            _lerpColorComponent(t, a[25]!.red, b[25]!.red),
            _lerpColorComponent(t, a[25]!.green, b[25]!.green),
            _lerpColorComponent(t, a[25]!.blue, b[25]!.blue),
          ),
        for (int shade = 100; shade <= 900; shade += 100)
          shade: Color.fromARGB(
            _lerpColorComponent(t, a[shade]!.alpha, b[shade]!.alpha),
            _lerpColorComponent(t, a[shade]!.red, b[shade]!.red),
            _lerpColorComponent(t, a[shade]!.green, b[shade]!.green),
            _lerpColorComponent(t, a[shade]!.blue, b[shade]!.blue),
          ),
      },
    );
  }

  int _lerpColorComponent(double t, int a, int b) {
    return (a + (b - a) * t).round().clamp(0, 255);
  }
}
