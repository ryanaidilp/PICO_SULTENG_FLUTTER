import 'package:dependencies/auto_route.dart';
import 'package:dependencies/state.dart';
import 'package:flutter/material.dart';
import 'package:peta/src/presentation/bloc/peta_bloc.dart';
import 'package:peta/src/presentation/bloc/peta_state.dart';

/// Main page for the Peta feature.
@RoutePage()
class const PetaPage({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => BlocBuilder<PetaBloc, PetaState>(
    builder: (context, state) => switch (state) {
      PetaInitial() || PetaLoading() => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      PetaLoaded() => Scaffold(
        appBar: AppBar(title: const Text('Peta')),
        body: const Center(child: Text('Peta Loaded')),
      ),
      PetaError(:final message) => Scaffold(
        body: Center(child: Text('Error: $message')),
      ),
    },
  );
}
