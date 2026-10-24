import 'package:dependencies/auto_route.dart';
import 'package:dependencies/state.dart';
import 'package:flutter/material.dart';
import 'package:layanan/src/presentation/bloc/layanan_bloc.dart';
import 'package:layanan/src/presentation/bloc/layanan_state.dart';

/// Main page for the Layanan feature.
@RoutePage()
class const LayananPage({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => BlocBuilder<LayananBloc, LayananState>(
    builder: (context, state) => switch (state) {
      LayananInitial() || LayananLoading() => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      LayananLoaded() => Scaffold(
        appBar: AppBar(title: const Text('Layanan')),
        body: const Center(child: Text('Layanan Loaded')),
      ),
      LayananError(:final message) => Scaffold(
        body: Center(child: Text('Error: $message')),
      ),
    },
  );
}
