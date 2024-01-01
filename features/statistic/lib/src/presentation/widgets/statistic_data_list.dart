import 'package:flutter/material.dart';
import 'package:i10n/i10n.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:statistic/statistic.dart';

class StatisticDataList extends StatelessWidget {
  StatisticDataList({
    Statistic? statistic,
    this.showSuspectCard = true,
    super.key,
  }) : statistic = statistic ?? Statistic();

  final Statistic statistic;
  final bool showSuspectCard;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PicoTotalConfirmedCase(
            total: statistic.cumulative.positive,
            newCase: statistic.newCases.positive,
          ),
          24.verticalSpace,
          StaggeredGrid.count(
            crossAxisCount: 3,
            crossAxisSpacing: 8.w,
            mainAxisSpacing: 8.h,
            children: [
              PicoCaseCard.treatment(
                total: statistic.cumulative.underTreatment,
                newCase: statistic.newCases.underTreatment,
              ),
              PicoCaseCard.cured(
                total: statistic.cumulative.recovered,
                newCase: statistic.newCases.recovered,
              ),
              PicoCaseCard.death(
                total: statistic.cumulative.deceased,
                newCase: statistic.newCases.deceased,
              ),
            ],
          ),
          if (showSuspectCard) ...[
            16.verticalSpace,
            PicoSuspectCard.underObservation(
              total: statistic.cumulative.totalObserved,
              newCase: statistic.newCases.totalObserved,
              newFinishedCase: statistic.newCases.finishedObservation,
              activeCase: statistic.cumulative.underObservation,
              finishedCase: statistic.cumulative.finishedObservation,
              onTap: () {},
            ),
            16.verticalSpace,
            PicoSuspectCard.underSupervision(
              total: statistic.cumulative.totalSupervised,
              newCase: statistic.newCases.totalSupervised,
              newFinishedCase: statistic.newCases.finishedSupervision,
              activeCase: statistic.cumulative.underSupervision,
              finishedCase: statistic.cumulative.finishedSupervision,
              onTap: () {},
            ),
            16.verticalSpace,
            PicoCardTile(
              label: context.i10n.national_case_label,
              onTap: () {},
            ),
            16.verticalSpace,
            PicoCardTile(
              label: context.i10n.regency_case_label,
              onTap: () {},
            ),
          ],
        ],
      );
}
