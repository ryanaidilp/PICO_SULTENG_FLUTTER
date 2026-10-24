import 'package:dependencies/di.dart' show GetIt, GetItHelper;
import 'package:flutter_test/flutter_test.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_data_impl/pico_data_impl.dart';
import 'package:pico_data_impl/testing.dart';

void main() {
  test(
    'the package module registers every port into a root container',
    () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      await PicoDataImplTestPrerequisite().install();
      final root = GetIt.asNewInstance();

      await PicoDataImplPackageModule().init(GetItHelper(root));

      expect(root<CaseRepository>(), isA<CaseRepository>());
      expect(root<StatsRepository>(), isA<StatsRepository>());
      expect(root<DirectoryRepository>(), isA<DirectoryRepository>());
      expect(root<ContentRepository>(), isA<ContentRepository>());
      expect(root<SettingsRepository>().themeMode, PicoThemeMode.system);
      expect(root<LocalDataAdmin>(), isA<LocalDataAdmin>());
      expect(identical(root<CaseRepository>(), root<CaseRepository>()), isTrue);
    },
  );
}
