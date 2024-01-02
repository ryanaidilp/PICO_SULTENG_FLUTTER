import 'package:flutter/widgets.dart';
import 'package:i10n/i10n.dart';

enum PicoSuspectType {
  underSupervision,
  underObservation;

  String label(BuildContext context) => switch (this) {
        underSupervision => context.i10n.pdp.label,
        underObservation => context.i10n.odp.label,
      };

  String title(BuildContext context) => switch (this) {
        underSupervision => context.i10n.pdp.title,
        underObservation => context.i10n.odp.title,
      };

  String description(BuildContext context) => switch (this) {
        underSupervision => context.i10n.pdp.description,
        underObservation => context.i10n.odp.description,
      };
}
