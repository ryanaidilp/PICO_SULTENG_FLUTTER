/// Dependencies package for Pico.
///
/// This package centralizes and exports commonly used external dependencies
/// across the application. It simplifies dependency management by providing
/// a single point of import for frequently used packages. The Flutter-free
/// ones live in dependencies_core and are re-exported from here.
///
/// Included dependencies:
/// - Routing: auto_route
/// - Equality: equatable
/// - Dependency Injection: get_it, injectable
/// - Annotations: meta
/// - Localization: slang, slang_flutter
/// - State Management: flutter_bloc
library;

export 'auto_route.dart';
export 'di.dart';
export 'equality.dart';
export 'l10n.dart';
export 'meta.dart';

export 'state.dart';
