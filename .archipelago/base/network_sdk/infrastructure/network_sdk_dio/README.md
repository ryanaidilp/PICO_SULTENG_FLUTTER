# network_sdk_dio

Dio-based HTTP client implementation.

This package provides a concrete HTTP client using [Dio](https://pub.dev/packages/dio),
implementing the interfaces defined in `network_sdk_api`.

## Features

- `DioHttpClient` — Extends `DioMixin` so it can be registered as `Dio` in DI
- `DioInterceptorAdapter` — Bridges `HttpInterceptor` to Dio's interceptor system
- `AuthInterceptor` — Attaches the session bearer from `AuthTokenProvider` and,
  on a `401`, renews the session and replays the request once
- `DioConfig` — Configuration class for base URL, timeouts, headers
- Debug `LogInterceptor` automatically added in debug mode
- Injectable DI module with `@microPackageInit`

## Usage

Register via DI (injectable) or create directly:

```dart
final client = DioHttpClient.init(
  config: DioConfig(baseUrl: 'https://api.example.com'),
  // Optional. Installs AuthInterceptor; omit it to opt out of the auth
  // lifecycle entirely.
  authTokenProvider: resolveAuthTokenProvider,
);
```
