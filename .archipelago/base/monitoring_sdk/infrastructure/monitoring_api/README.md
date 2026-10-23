# Monitoring API

Pure interfaces for crash reporting and performance monitoring.

## Overview

This package provides vendor-agnostic abstractions for monitoring services. It follows the API/Impl pattern where this package defines contracts and separate implementation packages provide concrete implementations.

## Features

- **Crash Reporting** - Record errors and exceptions with stack traces
- **Structured Logging** - Log messages with levels and tags
- **User Context** - Associate crashes with user identities
- **Performance Transactions** - Track operation durations
- **Multi-Vendor Support** - Target multiple monitoring backends

## Interfaces

### AppMonitoring

The main interface for all monitoring operations:

```dart
abstract interface class AppMonitoring {
  bool get enabled;

  Future<void> initialize({
    required bool enable,
    List<MonitoringVendor> vendors,
  });

  Future<void> setUserId(String id, {String? email, String? token});
  Future<void> removeUser();

  void log({String? tag, required String message, MonitoringLevel level});

  Future<void> recordError(dynamic exception, StackTrace? stack, {bool fatal});

  Future<void> recordTransaction({
    required String name,
    required String operation,
    Map<String, dynamic> data,
    void Function()? func,
  });
}
```

## Enums

### MonitoringLevel

Log severity levels:
- `debug` - Detailed debugging information
- `info` - General informational messages
- `warning` - Warning conditions
- `error` - Error conditions
- `fatal` - Critical failures

### MonitoringVendor

Target monitoring backends:
- `system` - Console logger (always available)

Additional vendors are added when you install their corresponding vendor brick:
- `crashlytics_monitoring_impl` - Firebase Crashlytics
- `sentry_monitoring_impl` - Sentry error tracking
- `newrelic_monitoring_impl` - New Relic mobile monitoring
- `grafana_monitoring_impl` - Grafana stack (Loki + Tempo)

### MonitoringStatus

Service state:
- `enabled` - Actively collecting data
- `disabled` - Not collecting data

## Related Packages

- `monitoring_impl` - Orchestrator with system logger
- `monitoring_noop` - No-op implementation for tests or an explicit opt-out
