import 'package:dependencies/auto_route.dart';
import 'package:dependencies/state.dart';
import 'package:flutter/material.dart';
import 'package:infografis/src/presentation/bloc/infografis_bloc.dart';
import 'package:infografis/src/presentation/bloc/infografis_state.dart';

/// Main page for the Infografis feature.
@RoutePage()
class const InfografisPage({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<InfografisBloc, InfografisState>(
        builder: (context, state) => switch (state) {
          InfografisInitial() || InfografisLoading() => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          InfografisLoaded() => Scaffold(
            appBar: AppBar(title: const Text('Infografis')),
            body: const Center(child: Text('Infografis Loaded')),
          ),
          InfografisError(:final message) => Scaffold(
            body: Center(child: Text('Error: $message')),
          ),
        },
      );
}
