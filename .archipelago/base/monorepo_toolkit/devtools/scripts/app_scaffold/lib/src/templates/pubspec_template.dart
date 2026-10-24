/// Generates a pubspec.yaml for a new app.
String pubspecTemplate({
  required String appName,
  required String uiKitPackageName,
}) =>
    '''
name: $appName
description: "A host app for the Archipelago monorepo workspace."
version: 0.1.0
publish_to: "none"

environment:
  sdk: ">=3.11.0 <4.0.0"

resolution: workspace

dependencies:
  analytics_api:
    path: ../../infrastructure/analytics_api
  analytics_impl:
    path: ../../infrastructure/analytics_impl
  app_asset:
    path: ../../packages/app_asset
  app_config:
    path: ../../shared/app_config
  $uiKitPackageName:
    path: ../../packages/$uiKitPackageName
  app_utilities:
    path: ../../utilities/app_utilities
  auth_api:
    path: ../../features/auth/auth_api
  auth_impl:
    path: ../../features/auth/auth_impl
  consent_impl:
    path: ../../shared/consent_impl
  dependencies:
    path: ../../shared/dependencies
  feature_flag_api:
    path: ../../infrastructure/feature_flag_api
  feature_flag_impl:
    path: ../../infrastructure/feature_flag_impl
  feature_sdk:
    path: ../../shared/feature_sdk
  flutter:
    sdk: flutter
  flutter_native_splash: ^2.4.7
  home_api:
    path: ../../features/home/home_api
  home_impl:
    path: ../../features/home/home_impl
  introduction:
    path: ../../features/introduction
  locale_core:
    path: ../../shared/locale_core
  monitoring_api:
    path: ../../infrastructure/monitoring_api
  monitoring_impl:
    path: ../../infrastructure/monitoring_impl
  network_sdk_api:
    path: ../../infrastructure/network_sdk_api
  network_sdk_dio:
    path: ../../infrastructure/network_sdk_dio
  paywall_api:
    path: ../../features/paywall/paywall_api
  paywall_impl:
    path: ../../features/paywall/paywall_impl
  router_registry:
    path: ../../shared/router_registry
  websocket_sdk_api:
    path: ../../infrastructure/websocket_sdk_api
  websocket_sdk_dart:
    path: ../../infrastructure/websocket_sdk_dart

dev_dependencies:
  auto_route_generator: ^10.5.0
  build_runner:
  change_app_package_name: ^1.5.0
  flutter_flavorizr: ^2.4.2
  flutter_launcher_icons: ^0.14.4
  flutter_test:
    sdk: flutter
  injectable_generator: ^3.0.2
  very_good_analysis: ">=10.0.0"

flutter:
  uses-material-design: true
''';
