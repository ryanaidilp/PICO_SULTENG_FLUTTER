import 'dart:async';

import 'package:peta/src/domain/map_values.dart';

/// Events of the map bloc.
abstract class PetaEvent {
  const PetaEvent();
}

/// Load the outlines and the latest value of each kabupaten.
final class PetaStarted extends PetaEvent {
  const PetaStarted();
}

/// Another metric.
final class PetaMetricChanged extends PetaEvent {
  const PetaMetricChanged(this.metric);

  final PetaMetric metric;
}

/// A date within the data range, or null for the latest day. The 13 series
/// give the values of a past day.
final class PetaDateChosen extends PetaEvent {
  const PetaDateChosen(this.date);

  final DateTime? date;
}

/// Map or list.
final class PetaViewChanged extends PetaEvent {
  const PetaViewChanged({required this.list});

  final bool list;
}

/// A region (or its mark) was tapped; null closes the sheet.
final class PetaSelected extends PetaEvent {
  const PetaSelected(this.code);

  final String? code;
}

/// Pull to refresh or retry.
final class PetaRefreshed extends PetaEvent {
  const PetaRefreshed({this.done});

  final Completer<void>? done;
}
