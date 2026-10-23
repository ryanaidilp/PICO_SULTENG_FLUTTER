# Monitoring Impl

Monitoring implementation with system logger.

## Overview

This package provides the main orchestrator implementation of `AppMonitoring` that dispatches to multiple monitoring vendors. It includes system logging via `app_utilities`.

## Features

- **Vendor Orchestration** - Routes monitoring calls to appropriate backends
- **Flutter Error Fanout** - `recordFlutterError` reaches every enabled vendor once; `bootstrap.dart` owns `FlutterError.onError` and `PlatformDispatcher.instance.onError`
- **System Logging** - Console output via `Log` from `app_utilities`
- **Injectable DI Module** - Registers as `AppMonitoring` via `@LazySingleton`

## Architecture

`MonitoringImpl` is the main orchestrator that:
1. Accepts vendor implementations via DI constructor injection
2. Routes method calls based on `MonitoringVendor` enum
3. Sets up global Flutter/Dart error handlers on initialization

To add vendor implementations (e.g., Crashlytics, Sentry, New Relic, Grafana),
install the corresponding vendor brick and register it as a dependency.

## Release Builds

This package ships in debug and release builds. `AppMonitoring` resolves to
`ConsentAwareMonitoring`, which drops every call until the user grants the
`diagnostics` consent purpose. `monitoring_noop` registers the same
`MonitoringImplPackageModule` class, so you can still swap it in with a
`build_prepare` mapping if you choose to opt out.

## Related Packages

- `monitoring_api` - Interface contracts
- `monitoring_noop` - No-op implementation for tests or an explicit opt-out
- `app_utilities` - Provides `Log` for system logging
