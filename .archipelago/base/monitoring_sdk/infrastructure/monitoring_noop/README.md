# Monitoring Noop

No-op monitoring implementation for tests or an explicit opt-out.

## Overview

This package provides empty implementations of all monitoring interfaces.
It is **not** swapped in by default: `monitoring_impl` ships in release
builds, and `ConsentAwareMonitoring` gates it on the user's `diagnostics`
consent.

## Features

- **Zero Dependencies** - No vendor SDKs included
- **Behavior Preservation** - `recordTransaction` still calls `func?.call()` to maintain expected behavior
- **Same public names** - Declares `MonitoringImplPackageModule` and `ConsentAwareMonitoring` (the class bound as `AppMonitoring`), the names `monitoring_impl` exports, so a swap changes only the package and its import

## Opting out of release monitoring

To strip monitoring from release builds anyway, add this mapping to
`build_prepare.yaml`:

```yaml
build_prepare:
  mappings:
    - debug: monitoring_impl
      release: monitoring_noop
```

## Related Packages

- `monitoring_api` - Interface contracts
- `monitoring_impl` - Vendor fanout behind the consent gate
