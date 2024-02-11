import 'package:config/config.dart';
import 'package:core/src/log/filter/release_log_filter.dart';
import 'package:core/src/log/printer/simple_log_printer.dart';
import 'package:core/src/network/http/http_client.dart';
import 'package:core/src/network/http/http_setting.dart';
import 'package:dependencies/dependencies.dart';
import 'package:logger/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';

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

  @preResolve
  Future<PackageInfo> get packageInfo => PackageInfo.fromPlatform();

  HttpClient get httpClient => HttpClient.init(
        HttpSetting(
          baseUrl: Env.apiBaseUrl,
        ),
      );
}
