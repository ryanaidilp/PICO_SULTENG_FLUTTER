import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:pico_sulteng_flutter/generated/locales.g.dart';

class ErrorPlaceHolderWidget extends StatelessWidget {
  ErrorPlaceHolderWidget({
    super.key,
    required this.label,
    this.child = const Placeholder(),
    required this.onRetry,
  });

  final String label;
  Widget child;
  final GestureTapCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (child is Placeholder) {
      child = Lottie.asset(
        'assets/lottie/error.json',
        height: 60.0,
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: SizedBox(
          height: 160,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              child,
              Text(label),
              TextButton(
                onPressed: onRetry,
                child: Text(LocaleKeys.buttons_try_again.tr),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
