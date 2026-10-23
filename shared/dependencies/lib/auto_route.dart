/// Routing exports.
///
/// Re-exports auto_route for navigation and routing.
library;

export 'package:auto_route/auto_route.dart';

// auto_route_generator emits `Key? key` into every `<Foo>RouteArgs` class it
// generates for a route whose page takes constructor parameters — but
// package:auto_route never re-exports Flutter's `Key` itself. A feature
// router file only imports this barrel, so as long as every one of its
// routes is argument-less, the missing import is invisible; the moment a
// feature adds its first route with constructor parameters, the generated
// `.gr.dart` part file fails with "Type 'Key' not found", pointing at
// generated code marked "DO NOT MODIFY BY HAND" rather than at this barrel.
// Re-exporting `Key` here fixes it once, workspace-wide, instead of adding
// `import 'package:flutter/widgets.dart';` to every feature's router file
// (Archipelago-m7dv).
export 'package:flutter/widgets.dart' show Key;
