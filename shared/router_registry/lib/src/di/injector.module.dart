// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'dart:async' as _i687;

import 'package:injectable/injectable.dart' as _i526;

import '../external_navigator.dart' as _i249;
import '../route_registry.dart' as _i17;
import '../route_registry_impl.dart' as _i671;

class RouterRegistryPackageModule extends _i526.MicroPackageModule {
  // initializes the registration of main-scope dependencies inside of GetIt
  @override
  _i687.FutureOr<void> init(_i526.GetItHelper gh) {
    gh.lazySingleton<_i249.ExternalNavigator>(
      () => _i249.ExternalNavigatorImpl(),
    );
    gh.lazySingleton<_i17.RouteRegistry>(() => _i671.RouteRegistryImpl());
  }
}
