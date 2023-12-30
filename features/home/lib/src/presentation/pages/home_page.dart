import 'package:dependencies/dependencies.dart';
import 'package:flutter/material.dart';
import 'package:home/src/presentation/blocs/banner/banner_bloc.dart';
import 'package:i10n/i10n.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

@RoutePage()
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.i10n.app_name,
            ),
            Text(
              context.i10n.app_desc,
              style: TextStyle(
                fontSize: 10.sp,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(
              EvaIcons.menu,
              size: 24.sp,
              color: context.picoColors.text.main,
            ),
          ),
        ],
      ),
      body: BlocBuilder<BannerBloc, BannerState>(
        builder: (_, state) {
          if (state is BannerLoadingState) {
            return Center(
              child: SpinKitFadingCircle(
                color: Colors.blueAccent,
                size: 20.sp,
              ),
            );
          } else if (state is BannerFailedState) {
            return Center(
              child: Text(state.failure.message),
            );
          } else if (state is BannerLoadedState) {
            return ListView.builder(
              itemCount: state.data.length,
              itemBuilder: (context, index) => Text(
                state.data[index].title,
                style: TextStyle(
                  color: context.picoColors.text.main,
                ),
              ),
            );
          }

          return Center(
            child: ElevatedButton(
              onPressed: () => context.read<BannerBloc>().add(
                    BannerEvent.load(),
                  ),
              child: const Text('Load Data'),
            ),
          );
        },
      ),
    );
  }
}
