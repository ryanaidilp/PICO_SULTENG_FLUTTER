import 'package:dependencies/auto_route.dart';
import 'package:dependencies/state.dart';
import 'package:flutter/material.dart';
import 'package:statistik/src/presentation/bloc/statistik_bloc.dart';
import 'package:statistik/src/presentation/bloc/statistik_state.dart';

/// Main page for the Statistik feature.
@RoutePage()
class const StatistikPage({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<StatistikBloc, StatistikState>(
        builder: (context, state) => switch (state) {
          StatistikInitial() || StatistikLoading() => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          StatistikLoaded() => Scaffold(
            appBar: AppBar(title: const Text('Statistik')),
            body: const Center(child: Text('Statistik Loaded')),
          ),
          StatistikError(:final message) => Scaffold(
            body: Center(child: Text('Error: $message')),
          ),
        },
      );
}
