import 'package:dependencies/auto_route.dart';
import 'package:dependencies/state.dart';
import 'package:flutter/material.dart';
import 'package:vaksin/src/presentation/bloc/vaksin_bloc.dart';
import 'package:vaksin/src/presentation/bloc/vaksin_state.dart';

/// Main page for the Vaksin feature.
@RoutePage()
class const VaksinPage({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => BlocBuilder<VaksinBloc, VaksinState>(
    builder: (context, state) => switch (state) {
      VaksinInitial() || VaksinLoading() => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      VaksinLoaded() => Scaffold(
        appBar: AppBar(title: const Text('Vaksin')),
        body: const Center(child: Text('Vaksin Loaded')),
      ),
      VaksinError(:final message) => Scaffold(
        body: Center(child: Text('Error: $message')),
      ),
    },
  );
}
