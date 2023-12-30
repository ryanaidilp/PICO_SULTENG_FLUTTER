import 'package:flutter/material.dart';

class PicoColors {
  PicoColors._();

  static const MaterialColor gray = MaterialColor(
    0xFF737271,
    {
      0: Color(0xFFFFFFFF),
      25: Color(0xFFFBFBF9),
      50: Color(0xFFF9F8F6),
      100: Color(0xFFF3F1EE),
      200: Color(0xFFEBE9E5),
      300: Color(0xFFD5D4D2),
      400: Color(0xFFA4A3A2),
      500: Color(0xFF737271),
      600: Color(0xFF535352),
      700: Color(0xFF41403E),
      800: Color(0xFF302E2C),
      900: Color(0xFF24221F),
    },
  );

  static const MaterialColor tertiary = MaterialColor(
    0xFF72dfc9,
    {
      50: Color(0xFFf1fcf9),
      100: Color(0xFFd0f7ed),
      200: Color(0xFFa1eedc),
      300: Color(0xFF72dfc9),
      400: Color(0xFF3cc5ae),
      500: Color(0xFF23a994),
      600: Color(0xFF198879),
      700: Color(0xFF186d62),
      800: Color(0xFF185750),
      900: Color(0xFF184943),
    },
  );

  static const MaterialColor secondary = MaterialColor(
    0xFF8f7de8,
    {
      50: Color(0xFFf5f4fe),
      100: Color(0xFFecebfc),
      200: Color(0xFFdcdafa),
      300: Color(0xFFc1bdf5),
      400: Color(0xFFa197ee),
      500: Color(0xFF8f7de8),
      600: Color(0xFF6e4ed9),
      700: Color(0xFF5e3bc6),
      800: Color(0xFF4f31a6),
      900: Color(0xFF422a88),
    },
  );
  static const MaterialColor primary = MaterialColor(
    0xFF0b92d5,
    {
      50: Color(0xFFf1f9fe),
      100: Color(0xFFe1f2fd),
      200: Color(0xFFbde6fa),
      300: Color(0xFF82d2f7),
      400: Color(0xFF40bbf0),
      500: Color(0xFF17a4e0),
      600: Color(0xFF09689b),
      700: Color(0xFF09689b),
      800: Color(0xFF0c5880),
      900: Color(0xFF104a6a),
    },
  );

  static const MaterialColor error = MaterialColor(
    0xFFF04438,
    {
      25: Color(0xFFFFFBFA),
      50: Color(0xFFFEF3F2),
      100: Color(0xFFFEE4E2),
      200: Color(0xFFFECDCA),
      300: Color(0xFFFDA29B),
      400: Color(0xFFF97066),
      500: Color(0xFFF04438),
      600: Color(0xFFD92D20),
      700: Color(0xFFB42318),
      800: Color(0xFF912018),
      900: Color(0xFF7A271A),
    },
  );

  static const MaterialColor info = MaterialColor(
    0xFF275CD8,
    {
      25: Color(0xFFE1EAFF),
      50: Color(0xFFC7D8FF),
      100: Color(0xFFACC2F7),
      200: Color(0xFF7FA0ED),
      300: Color(0xFF5480E8),
      400: Color(0xFF3A6DE4),
      500: Color(0xFF275CD8),
      600: Color(0xFF184DC8),
      700: Color(0xFF1342AF),
      800: Color(0xFF113997),
      900: Color(0xFF0E3181),
    },
  );

  static const MaterialColor success = MaterialColor(
    0xFF16B364,
    {
      25: Color(0xFFF6FEF9),
      50: Color(0xFFE5FBEC),
      100: Color(0xFFD3F8DF),
      200: Color(0xFFAAF0C4),
      300: Color(0xFF73E2A3),
      400: Color(0xFF3CCB7F),
      500: Color(0xFF16B364),
      600: Color(0xFF099250),
      700: Color(0xFF087443),
      800: Color(0xFF095C37),
      900: Color(0xFF084C2E),
    },
  );

  static const MaterialColor warning = MaterialColor(
    0xFFFDBB11,
    {
      25: Color(0xFFFFF8E7),
      50: Color(0xFFFFF1CF),
      100: Color(0xFFFEEBB8),
      200: Color(0xFFFEE4A0),
      300: Color(0xFFFED670),
      400: Color(0xFFFDC941),
      500: Color(0xFFFDBB11),
      600: Color(0xFFD89C00),
      700: Color(0xFFB28000),
      800: Color(0xFF7A5900),
      900: Color(0xFF523A00),
    },
  );

  static final Color bgMain = gray.shade50;
  static final Color bgSubtle = gray.shade100;
  static final Color bgStrong = gray.shade200;
  static const Color bgWhite = Colors.white;
  static final Color bgInverse = gray.shade900;
  static final Color bgMainDark = gray.shade900;
  static final Color bgSubtleDark = gray.shade800;
  static final Color bgStrongDark = gray.shade700;
  static final Color bgWhiteDark = gray.shade900;
  static const Color bgInverseDark = Colors.white;
  static final vaccinePublic = Colors.pink.shade400;
  static const vaccineElderly = Colors.blueAccent;
  static final vaccineTeenager = Colors.pinkAccent.shade100;
  static final vaccineAll = Colors.green.shade700;
  static const vaccinePublicWorker = Colors.purple;
  static final vaccineHealthWorker = Colors.orange.shade700;
  static final vaccinePublicDark = Colors.pink.shade200;
  static final vaccineElderlyDark = Colors.blueAccent.shade200;
  static final vaccineTeenagerDark = Colors.pinkAccent.shade100;
  static final vaccineAllDark = Colors.green.shade400;
  static final vaccinePublicWorkerDark = Colors.purple.shade200;
  static final vaccineHealthWorkerDark = Colors.orange.shade300;
  static final Color textStrong = gray.shade900;
  static final Color textMain = gray.shade700;
  static final Color textSubtle = gray.shade500;
  static final Color textDisabled = gray.shade400;
  static const Color textOnImageStrong = Colors.white;
  static final Color textOnImageSubtle = Colors.white.withOpacity(0.5);
  static const Color textInverse = Colors.white;
  static const Color textStrongDark = Colors.white;
  static final Color textMainDark = gray.shade100;
  static final Color textSubtleDark = gray.shade400;
  static final Color textDisabledDark = gray.shade500;
  static const Color textOnImageStrongDark = Colors.white;
  static final Color textOnImageSubtleDark = Colors.white.withOpacity(0.5);
  static const Color textInverseDark = Colors.black;
}
