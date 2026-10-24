import 'dart:async';

import 'package:pico_data_api/pico_data_api.dart';

/// Which part of the page is open.
enum VaksinSegment {
  /// Cakupan.
  coverage,

  /// Lokasi.
  locations,
}

/// Events of the Vaksin bloc.
abstract class VaksinEvent {
  const new();
}

/// First load of the coverage series.
final class VaksinStarted extends VaksinEvent {
  /// Creates the event.
  const new();
}

/// Nasional or Sulawesi Tengah.
final class VaksinScopeChanged extends VaksinEvent {
  /// Creates the event.
  const new(this.scope);

  /// The new scope.
  final VaccinationScope scope;
}

/// Cakupan or Lokasi. Locations load on first open.
final class VaksinSegmentChanged extends VaksinEvent {
  /// Creates the event.
  const new(this.segment);

  /// The new segment.
  final VaksinSegment segment;
}

/// Pull to refresh or retry.
final class VaksinRefreshed extends VaksinEvent {
  /// Creates the event.
  const new({this.done});

  /// Completes when the open segment has answered.
  final Completer<void>? done;
}
