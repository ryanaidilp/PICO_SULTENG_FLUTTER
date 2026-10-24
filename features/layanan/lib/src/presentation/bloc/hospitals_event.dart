import 'dart:async';

/// Events of the hospitals bloc.
abstract class HospitalsEvent {
  const new();
}

/// Load the hospitals and the regency names.
final class HospitalsStarted extends HospitalsEvent {
  /// Creates the event.
  const new();
}

/// Pull to refresh. [done] completes when the streams finish.
final class HospitalsRefreshed extends HospitalsEvent {
  /// Creates the event.
  const new({this.done});

  /// Completed when the refresh ends.
  final Completer<void>? done;
}
