import 'package:dependencies/dependencies.dart';
import 'package:flutter/material.dart';
import 'package:statistic/statistic.dart';

@RoutePage()
class StatisticWrapperPage extends StatelessWidget implements AutoRouteWrapper {
  const StatisticWrapperPage({super.key});

  @override
  Widget wrappedRoute(BuildContext context) => this;

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
        providers: [
          BlocProvider<AllStatisticsBloc>(
            create: (_) => AllStatisticsBloc()..add(AllStatisticsEvent.fetch()),
          ),
          BlocProvider<AllNationalStatisticsCubit>(
            create: (_) => AllNationalStatisticsCubit()..fetch(),
          ),
        ],
        child: const AutoRouter(),
      );
}
