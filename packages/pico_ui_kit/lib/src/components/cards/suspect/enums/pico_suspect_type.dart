import 'package:flutter/widgets.dart';
import 'package:i10n/i10n.dart';

enum PicoSuspectType {
  underSupervision,
  underObservation;

  String label(BuildContext context) => switch (this) {
        underSupervision =>
          context.translations.statistics.cardLabel.caseType.pdp,
        underObservation =>
          context.translations.statistics.cardLabel.caseType.odp,
      };

  String title(BuildContext context) => switch (this) {
        underSupervision => context.translations.information.caseType.pdp.title,
        underObservation => context.translations.information.caseType.odp.title,
      };

  String description(BuildContext context) => switch (this) {
        underSupervision =>
          context.translations.information.caseType.pdp.description,
        underObservation =>
          context.translations.information.caseType.odp.description,
      };
}
