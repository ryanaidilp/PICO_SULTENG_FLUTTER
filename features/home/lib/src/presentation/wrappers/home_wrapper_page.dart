import 'package:dependencies/dependencies.dart';
import 'package:flutter/material.dart';
import 'package:home/src/presentation/blocs/banner/banner_bloc.dart';

@RoutePage()
class HomeWrapperPage extends StatelessWidget implements AutoRouteWrapper {
  const HomeWrapperPage({super.key});

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => BannerBloc()
              ..add(
                BannerEvent.load(),
              ),
          ),
        ],
        child: const AutoRouter(),
      );

  @override
  Widget wrappedRoute(BuildContext context) => this;
}
