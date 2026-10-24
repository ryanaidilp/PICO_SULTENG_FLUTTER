import 'dart:async';

import 'package:statistik/src/domain/area_query.dart';

/// Events of the area bloc.
abstract class AreaEvent {
  const AreaEvent();
}

/// A page opened with this query (from the route). Loads the area's series if
/// it is not the one already loaded.
final class AreaOpened extends AreaEvent {
  /// Creates the event.
  const AreaOpened(this.query);

  /// Query read from the route.
  final AreaQuery query;
}

/// The user changed the query. Same area: no new request.
final class AreaQueryChanged extends AreaEvent {
  /// Creates the event.
  const AreaQueryChanged(this.query);

  /// The new query.
  final AreaQuery query;
}

/// Toggles the "Bandingkan" overlay of all four metrics.
final class AreaCompareToggled extends AreaEvent {
  /// Creates the event.
  const AreaCompareToggled();
}

/// Pull to refresh or retry.
final class AreaRefreshed extends AreaEvent {
  /// Creates the event. [done] completes when the series has answered.
  const AreaRefreshed({this.done});

  /// Lets a refresh indicator wait.
  final Completer<void>? done;
}
