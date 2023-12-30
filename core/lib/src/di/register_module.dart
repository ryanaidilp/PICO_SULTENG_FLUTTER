import 'package:config/config.dart';
import 'package:core/src/log/filter/release_log_filter.dart';
import 'package:core/src/log/printer/simple_log_printer.dart';
import 'package:core/src/network/http/http_client.dart';
import 'package:core/src/network/http/http_setting.dart';
import 'package:dependencies/dependencies.dart';
import 'package:logger/logger.dart';

@module
abstract class RegisterModule {
  Logger get logger => Logger(
        filter: ReleaseLogFilter(),
        printer: PrefixPrinter(
          SimpleLogPrinter(),
          error: 'PicoError -',
          debug: 'PicoLog -',
          fatal: 'PicoFatalError -',
          info: 'PicoInfo -',
          trace: 'PicoTrace -',
          warning: 'PicoWarning -',
        ),
      );

  HttpClient get httpClient => HttpClient.init(
        HttpSetting(
          baseUrl: Env.baseUrl,
        ),
      );
}
