import 'package:dependencies/auto_route.dart';
import 'package:dependencies/state.dart';
import 'package:flutter/material.dart';
import 'package:pengaturan/src/presentation/bloc/pengaturan_bloc.dart';
import 'package:pengaturan/src/presentation/bloc/pengaturan_state.dart';

/// Main page for the Pengaturan feature.
@RoutePage()
class const PengaturanPage({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<PengaturanBloc, PengaturanState>(
        builder: (context, state) => switch (state) {
          PengaturanInitial() || PengaturanLoading() => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          PengaturanLoaded() => Scaffold(
            appBar: AppBar(title: const Text('Pengaturan')),
            body: const Center(child: Text('Pengaturan Loaded')),
          ),
          PengaturanError(:final message) => Scaffold(
            body: Center(child: Text('Error: $message')),
          ),
        },
      );
}
