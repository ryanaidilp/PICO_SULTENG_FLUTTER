import 'package:dependencies/dependencies.dart';
import 'package:flutter/material.dart';

@RoutePage()
class HomeWrapperPage extends StatelessWidget implements AutoRouteWrapper {
  const HomeWrapperPage({super.key});

  @override
  Widget build(BuildContext context) => const AutoRouter();

  @override
  Widget wrappedRoute(BuildContext context) => this;
}
