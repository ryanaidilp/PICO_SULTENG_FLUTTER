import 'package:dependencies/auto_route.dart';
import 'package:flutter/widgets.dart';
import 'package:layanan/src/router/layanan_router.dart';

/// Port for the Layanan feature.
///
/// A single-package feature keeps the port and its implementation together.
/// The port carries no lifecycle: the feature's routes are declared by its
/// manifest, so the implementation is a lazy singleton, built the first
/// time something resolves this port. Once another feature needs this
/// port, split it into an `_api` package first.
///
/// A method that hands data back returns `Future<T?>`, like auto_route's
/// `push<T>()`; `null` means cancelled or dismissed.
///
/// ```dart
/// await getIt<LayananSDK>().launch(context);
/// ```
abstract interface class LayananSDK() {
  /// Launch the Layanan feature flow.
  Future<void> launch(BuildContext context);

  // TODO(user): Add the destinations and actions other features need, e.g.
  //   Future<String?> pickItem(BuildContext context);
}

/// Implementation of [LayananSDK].
///
/// A lazy singleton (see `LayananGlobalModule`):
/// it does not exist until something resolves the port. Pass collaborators
/// in through the constructor from the global module.
class LayananSDKImpl() implements LayananSDK {
  @override
  Future<void> launch(BuildContext context) async {
    // Use push() to keep the back stack, or replaceAll() to clear it.
    await context.router.push(const LayananShellRoute());
  }
}
