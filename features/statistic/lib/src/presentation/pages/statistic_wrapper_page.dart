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
          BlocProvider<AllStatisticsCubit>(
            create: (_) => AllStatisticsCubit()..fetch(),
          ),
          BlocProvider<AllNationalStatisticsCubit>(
            create: (_) => AllNationalStatisticsCubit()..fetch(),
          ),
          BlocProvider(
            create: (_) => AllStatisticFilterCubit(),
          ),
          BlocProvider(
            create: (_) => AllNationalStatisticFilterCubit(),
          ),
          BlocProvider(
            create: (_) => LineChartLocalStatisticFilter(),
          ),
          BlocProvider(
            create: (_) => LineChartNationalStatisticFilter(),
          ),
        ],
        child: const AutoRouter(),
      );
}
