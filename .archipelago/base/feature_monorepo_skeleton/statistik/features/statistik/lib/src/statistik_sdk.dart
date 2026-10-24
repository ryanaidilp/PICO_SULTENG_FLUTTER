import 'package:dependencies/auto_route.dart';
import 'package:flutter/widgets.dart';
import 'package:statistik/src/router/statistik_router.dart';

/// Port for the Statistik feature.
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
/// await getIt<StatistikSDK>().launch(context);
/// ```
abstract interface class StatistikSDK() {
  /// Launch the Statistik feature flow.
  Future<void> launch(BuildContext context);

  // TODO(user): Add the destinations and actions other features need, e.g.
  //   Future<String?> pickItem(BuildContext context);
}

/// Implementation of [StatistikSDK].
///
/// A lazy singleton (see `StatistikGlobalModule`):
/// it does not exist until something resolves the port. Pass collaborators
/// in through the constructor from the global module.
class StatistikSDKImpl() implements StatistikSDK {
  @override
  Future<void> launch(BuildContext context) async {
    // Use push() to keep the back stack, or replaceAll() to clear it.
    await context.router.push(const StatistikShellRoute());
  }
}
