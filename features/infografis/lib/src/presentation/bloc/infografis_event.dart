import 'dart:async';

/// Events of the infographics bloc.
abstract class InfografisEvent {
  const new();
}

/// Load page 1.
final class InfografisStarted extends InfografisEvent {
  const new();
}

/// Load the next page, if there is one and none is loading.
final class InfografisMoreRequested extends InfografisEvent {
  const new();
}

/// Pull to refresh: reload from page 1. [done] completes when it ends.
final class InfografisRefreshed extends InfografisEvent {
  const new({this.done});

  final Completer<void>? done;
}
