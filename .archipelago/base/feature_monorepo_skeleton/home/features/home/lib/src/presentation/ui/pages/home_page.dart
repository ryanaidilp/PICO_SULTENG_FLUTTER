import 'package:dependencies/auto_route.dart';
import 'package:dependencies/state.dart';
import 'package:flutter/material.dart';
import 'package:home/src/presentation/bloc/home_bloc.dart';
import 'package:home/src/presentation/bloc/home_state.dart';

/// Main page for the Home feature.
@RoutePage()
class const HomePage({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => BlocBuilder<HomeBloc, HomeState>(
    builder: (context, state) => switch (state) {
      HomeInitial() || HomeLoading() => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      HomeLoaded() => Scaffold(
        appBar: AppBar(title: const Text('Home')),
        body: const Center(child: Text('Home Loaded')),
      ),
      HomeError(:final message) => Scaffold(
        body: Center(child: Text('Error: $message')),
      ),
    },
  );
}
