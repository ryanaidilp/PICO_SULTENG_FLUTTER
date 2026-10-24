import 'dart:io';

import 'package:app_config/app_config.dart';
import 'package:dependencies/di.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_data_impl/src/api/pico_api_client.dart';
import 'package:pico_data_impl/src/cache/local_data_admin_impl.dart';
import 'package:pico_data_impl/src/cache/snapshot_source.dart';
import 'package:pico_data_impl/src/cache/snapshot_store.dart';
import 'package:pico_data_impl/src/settings/settings_repository_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App version in the User-Agent. Override with
/// `--dart-define=PICO_VERSION=<version>`.
const String kPicoVersion = String.fromEnvironment(
  'PICO_VERSION',
  defaultValue: '8.0.0',
);

/// Builds the objects the repositories need: the API client (base URL from
/// `API_BASE_URL` of the active flavor), the snapshot store under
/// `<support dir>/pico_cache/v1`, settings and the local data admin.
@module
abstract class PicoDataImplModule {
  /// Loaded before the first frame so settings are ready (C08).
  @preResolve
  @lazySingleton
  Future<SharedPreferences> sharedPreferences() =>
      SharedPreferences.getInstance();

  /// The PICO API client. Base URL: `AppEnv.apiBaseUrl`
  /// (production: https://pico-api.banuacoder.com/api/v1).
  @lazySingleton
  PicoApiClient apiClient() => PicoApiClient.create(
    baseUrl: AppEnv.apiBaseUrl,
    userAgent: 'PICO-Sulteng/$kPicoVersion (${Platform.operatingSystem})',
  );

  /// Snapshot store in the app support directory.
  @preResolve
  @lazySingleton
  Future<SnapshotStore> snapshotStore() async => SnapshotStore(
    Directory('${(await getApplicationSupportDirectory()).path}/pico_cache/v1'),
  );

  /// The shared stream-rule reader.
  @lazySingleton
  SnapshotSource snapshotSource(PicoApiClient client, SnapshotStore store) =>
      SnapshotSource(client, store);

  /// Disk image cache admin.
  @lazySingleton
  ImageCacheAdmin imageCacheAdmin() => DiskImageCacheAdmin();

  /// Settings on shared_preferences.
  @LazySingleton(as: SettingsRepository)
  SettingsRepositoryImpl settingsRepository(SharedPreferences prefs) =>
      SettingsRepositoryImpl(prefs);

  /// Local data admin.
  @LazySingleton(as: LocalDataAdmin)
  LocalDataAdminImpl localDataAdmin(
    SnapshotStore store,
    ImageCacheAdmin images,
  ) => LocalDataAdminImpl(store, images);
}
