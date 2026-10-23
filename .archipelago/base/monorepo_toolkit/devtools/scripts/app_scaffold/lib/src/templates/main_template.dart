/// Generates the main entry point for a given flavor.
String mainTemplate({
  required String appName,
  required String flavor,
  required String flavorEnum,
  required String appClassName,
}) =>
    '''
import 'package:app_config/app_config.dart';
import 'package:$appName/app.dart';
import 'package:$appName/bootstrap.dart';

void main() => bootstrap(
  flavor: FlavorStatus.$flavorEnum,
  builder: (result, benchmark) =>
      $appClassName(router: result.requireRouter, benchmark: benchmark),
);
''';
