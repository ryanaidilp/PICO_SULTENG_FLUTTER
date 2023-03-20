import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:pico_sulteng_flutter/app/config/env.dart';
import 'package:pico_sulteng_flutter/app/routes/app_pages.dart';
import 'package:pico_sulteng_flutter/generated/locales.g.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isAndroid) {
    await AndroidInAppWebViewController.setWebContentsDebuggingEnabled(true);
  }
  initializeDateFormatting('id_ID');
  Intl.defaultLocale = 'id_ID';

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  if (kDebugMode) {
    OneSignal.shared.setLogLevel(OSLogLevel.verbose, OSLogLevel.none);
  }

  OneSignal.shared.setAppId(Env.oneSignalAppId);
  OneSignal.shared.promptUserForPushNotificationPermission().then((value) {
    debugPrint('Permission accepted: $value');
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GetMaterialApp(
      title: LocaleKeys.app_name.tr,
      locale: Get.deviceLocale,
      fallbackLocale: const Locale('en', 'US'),
      getPages: AppPages.routes,
      initialRoute: AppPages.initial,
      debugShowCheckedModeBanner: false,
      defaultTransition: Transition.native,
      translationsKeys: AppTranslation.translations,
      // initialBinding: NoInternetBinding(), TODO: There's an issue with smart refresher and tabbarview
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        textTheme: GoogleFonts.sourceSansProTextTheme(textTheme),
        appBarTheme: const AppBarTheme(
          color: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0.0,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.white,
            statusBarBrightness: Brightness.light,
            statusBarIconBrightness: Brightness.dark,
          ),
        ),
        tabBarTheme: const TabBarTheme(
          unselectedLabelColor: Colors.grey,
          labelStyle: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
