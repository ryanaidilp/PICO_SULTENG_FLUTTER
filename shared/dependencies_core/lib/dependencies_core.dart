/// Dependencies core package for Pico.
///
/// The Flutter-free half of the `dependencies` package: the common
/// third-party packages that need no Flutter SDK. Pure-Dart packages and
/// `*_api` contracts depend on this; Flutter packages depend on
/// `dependencies`, which re-exports everything here.
///
/// Included dependencies:
/// - State Management: bloc
/// - Equality: equatable
/// - Dependency Injection: get_it, injectable
/// - Annotations: meta
library;

export 'bloc.dart';
export 'di.dart';
export 'equality.dart';
export 'meta.dart';
