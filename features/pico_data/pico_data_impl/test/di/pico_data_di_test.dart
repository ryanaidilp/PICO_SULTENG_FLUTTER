import 'package:dependencies/di.dart' show GetIt, GetItHelper;
import 'package:flutter_test/flutter_test.dart';
import 'package:pico_data_impl/pico_data_impl.dart';

void main() {
  test('the package module registers into a root container', () async {
    final root = GetIt.asNewInstance();

    await PicoDataImplPackageModule().init(GetItHelper(root));
  });
}
