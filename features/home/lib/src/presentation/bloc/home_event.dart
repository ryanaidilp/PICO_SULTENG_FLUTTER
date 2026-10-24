import 'dart:async';

/// Events of the Beranda bloc.
sealed class HomeEvent {
  const HomeEvent();
}

/// First load: starts the three data streams.
final class HomeStarted extends HomeEvent {
  /// Creates the event.
  const HomeStarted();
}

/// Pull to refresh or "Coba lagi": every source fetches again.
final class HomeRefreshed extends HomeEvent {
  /// Creates the event. [done] completes when every source has answered.
  const HomeRefreshed({this.done});

  /// Lets a refresh indicator wait for the end of the refresh.
  final Completer<void>? done;
}
