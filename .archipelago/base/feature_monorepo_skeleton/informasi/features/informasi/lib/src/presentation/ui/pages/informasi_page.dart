import 'package:dependencies/auto_route.dart';
import 'package:dependencies/state.dart';
import 'package:flutter/material.dart';
import 'package:informasi/src/presentation/bloc/informasi_bloc.dart';
import 'package:informasi/src/presentation/bloc/informasi_state.dart';

/// Main page for the Informasi feature.
@RoutePage()
class const InformasiPage({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<InformasiBloc, InformasiState>(
        builder: (context, state) => switch (state) {
          InformasiInitial() || InformasiLoading() => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          InformasiLoaded() => Scaffold(
            appBar: AppBar(title: const Text('Informasi')),
            body: const Center(child: Text('Informasi Loaded')),
          ),
          InformasiError(:final message) => Scaffold(
            body: Center(child: Text('Error: $message')),
          ),
        },
      );
}
