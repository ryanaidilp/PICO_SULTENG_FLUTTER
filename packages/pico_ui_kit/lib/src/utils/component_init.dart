import 'package:flutter/material.dart';
import 'package:nil/nil.dart';

import 'package:pico_ui_kit/pico_ui_kit.dart';

/// A wrapper widget that initializes components within the Lontara UI Kit.
///
/// The `PCComponentInit` widget provides a mechanism for initializing \
/// components with specific configurations before they are rendered on the
/// screen. It applies a custom `textScaleFactor` based on the device's default
/// `textScaleFactor` and initializes the ScreenUtil utility for responsive
/// design using the maximum width and height constraints provided by the
/// parent widget.
///
/// This widget is commonly used as the root widget of the application to ensure
/// consistent text scaling and responsive layouts across different devices.
class PCComponentInit extends StatelessWidget {
  /// Creates an instance of [PCComponentInit].
  ///
  /// The [builder] parameter is a required function that takes a
  /// [BuildContext] as input and returns a widget to be displayed on the
  /// screen. It represents the component to be initialized and rendered.
  const PCComponentInit({
    required this.builder,
    super.key,
  });

  /// The function that builds the component and returns the widget
  /// to be rendered.
  final Widget Function(BuildContext context) builder;

  @override
  Widget build(BuildContext context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: MediaQuery.textScalerOf(context).clamp(
            minScaleFactor: 1,
            maxScaleFactor: 1.1,
          ),
        ),
        child: LayoutBuilder(
          builder: (_, constraints) {
            if (constraints.maxWidth != 0) {
              ScreenUtil.init(
                _,
                designSize: Size(
                  constraints.maxWidth,
                  constraints.maxHeight,
                ),
              );
              return builder(context);
            }

            return nil;
          },
        ),
      );
}
