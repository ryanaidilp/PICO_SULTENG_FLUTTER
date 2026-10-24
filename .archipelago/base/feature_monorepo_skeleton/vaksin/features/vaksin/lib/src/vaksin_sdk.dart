import 'package:dependencies/auto_route.dart';
import 'package:flutter/widgets.dart';
import 'package:vaksin/src/router/vaksin_router.dart';

/// Port for the Vaksin feature.
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
/// await getIt<VaksinSDK>().launch(context);
/// ```
abstract interface class VaksinSDK() {
  /// Launch the Vaksin feature flow.
  Future<void> launch(BuildContext context);

  // TODO(user): Add the destinations and actions other features need, e.g.
  //   Future<String?> pickItem(BuildContext context);
}

/// Implementation of [VaksinSDK].
///
/// A lazy singleton (see `VaksinGlobalModule`):
/// it does not exist until something resolves the port. Pass collaborators
/// in through the constructor from the global module.
class VaksinSDKImpl() implements VaksinSDK {
  @override
  Future<void> launch(BuildContext context) async {
    // Use push() to keep the back stack, or replaceAll() to clear it.
    await context.router.push(const VaksinShellRoute());
  }
}
