import 'package:flutter/material.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

@UseCase(
  name: 'Under Observation',
  type: PicoSuspectCard,
)
Widget underObservationCase(BuildContext context) => Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: PicoSuspectCard.underObservation(
            total: context.knobs.int.input(
              label: 'Total Observed',
              description: 'Total observed patient.',
            ),
            newCase: context.knobs.int.input(
              label: 'New Observed Case',
              description: 'New observed patient.',
            ),
            newFinishedCase: context.knobs.int.input(
              label: 'New Finished Case',
              description: 'New finish observed patient.',
            ),
            activeCase: context.knobs.int.input(
              label: 'Total Under Observed',
              description: 'Total under observed patient.',
            ),
            finishedCase: context.knobs.int.input(
              label: 'Total Finish Observed',
              description: 'Total finish observed patient.',
            ),
          ),
        ),
      ),
    );

@UseCase(
  name: 'Under Supervision',
  type: PicoSuspectCard,
)
Widget underSupervisionCase(BuildContext context) => Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: PicoSuspectCard.underSupervision(
            total: context.knobs.int.input(
              label: 'Total Supervised',
              description: 'Total supervised patient.',
            ),
            newCase: context.knobs.int.input(
              label: 'New Supervised Case',
              description: 'New supervised patient.',
            ),
            newFinishedCase: context.knobs.int.input(
              label: 'New Finished Case',
              description: 'New finish supervised patient.',
            ),
            activeCase: context.knobs.int.input(
              label: 'Total Under Supervised',
              description: 'Total under supervised patient.',
            ),
            finishedCase: context.knobs.int.input(
              label: 'Total Finish Supervised',
              description: 'Total finish supervised patient.',
            ),
          ),
        ),
      ),
    );
