# network_sdk_api

Pure HTTP client interfaces with zero external dependencies.

This package defines the contract for HTTP clients used throughout the application.
It contains no implementation details — only abstract interfaces and immutable data classes.

## Contents

- `HttpClient` — Abstract interface for HTTP operations (GET, POST, PUT, PATCH, DELETE)
- `HttpInterceptor` — Abstract class for request/response/error interception
- `NetworkInterceptorRegistry` — Port a package that cannot see the app's client (the debug network inspector) uses to hand it a vendor-native interceptor; the Dio client adopts a Dio `Interceptor`, the http client a `void Function(http.Response)` observer, in any DI order
- `HttpRequest` — Immutable request representation with factory constructors
- `RequestOptions` — Immutable request configuration (headers, timeouts, query params)
- `RequestConfigs` — Predefined timeout presets (standard, fast, long, fileTransfer)
- `HttpResponse` — Immutable response with status helpers and data accessors
- `HttpException` — Sealed exception hierarchy (request, timeout, cancelled, network, parse)
- `HttpMethod` — Enum for HTTP methods
- `AuthTokenProvider` — The transport's view of the app's session: the bearer
  to attach, and "may I retry this 401?". Implemented by the auth feature,
  resolved optionally, so the transport never depends on `auth_api`
- `AuthExemptRequest` / `AuthRequestMarkers` — Opt a request out of the auth
  lifecycle (no bearer attached, no refresh on 401). Required for the
  sign-in and token-renewal endpoints themselves

## Usage

Depend on this package for type definitions. Use `network_sdk_dio` or `network_sdk_http`
for concrete implementations.
