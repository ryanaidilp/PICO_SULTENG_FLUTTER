import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pico_ui_kit/src/extensions/extensions.dart';

/// A standardized scaffold template with consistent theming.
///
/// Provides a pre-configured [Scaffold] with theme-aware defaults
/// for background color, app bar styling, and safe area handling.
///
/// ```dart
/// PicoScaffoldTemplate(
///   appBar: AppBar(title: Text('Home')),
///   body: Center(child: Text('Content')),
/// )
/// ```
class const PicoScaffoldTemplate({
  /// The primary content of the scaffold.
  required final Widget body,

  /// An app bar to display at the top of the scaffold.
  final PreferredSizeWidget? appBar,

  /// A floating action button to display.
  final Widget? floatingActionButton,

  /// Location of the floating action button.
  final FloatingActionButtonLocation? floatingActionButtonLocation,

  /// A bottom navigation bar to display.
  final Widget? bottomNavigationBar,

  /// A drawer to display.
  final Widget? drawer,

  /// An end drawer to display.
  final Widget? endDrawer,

  /// A persistent bottom sheet.
  final Widget? bottomSheet,

  /// The background color of the scaffold.
  final Color? backgroundColor,

  /// Whether the body should resize when the keyboard appears.
  final bool resizeToAvoidBottomInset = true,

  /// Whether the body extends behind the bottom navigation bar.
  final bool extendBody = false,

  /// Whether the body extends behind the app bar.
  final bool extendBodyBehindAppBar = false,

  /// Whether to wrap body in SafeArea.
  final bool useSafeArea = true,
  super.key,
}) extends StatelessWidget {
  /// Creates an [PicoScaffoldTemplate].
  this;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final safeBody = useSafeArea
        ? SafeArea(
            top: appBar == null,
            bottom: bottomNavigationBar == null,
            child: body,
          )
        : body;

    return Scaffold(
      appBar: appBar,
      body: safeBody,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
      drawer: drawer,
      endDrawer: endDrawer,
      bottomSheet: bottomSheet,
      backgroundColor: backgroundColor ?? colors.background.main,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<FloatingActionButtonLocation?>(
          'floatingActionButtonLocation',
          floatingActionButtonLocation,
        ),
      )
      ..add(ColorProperty('backgroundColor', backgroundColor))
      ..add(
        DiagnosticsProperty<bool>(
          'resizeToAvoidBottomInset',
          resizeToAvoidBottomInset,
        ),
      )
      ..add(DiagnosticsProperty<bool>('extendBody', extendBody))
      ..add(
        DiagnosticsProperty<bool>(
          'extendBodyBehindAppBar',
          extendBodyBehindAppBar,
        ),
      )
      ..add(DiagnosticsProperty<bool>('useSafeArea', useSafeArea));
  }
}

/// A scaffold template with a sliver app bar.
///
/// Provides a scrollable scaffold with a collapsible app bar.
///
/// ```dart
/// PicoSliverScaffoldTemplate(
///   title: 'Profile',
///   slivers: [
///     SliverList(...),
///   ],
/// )
/// ```
class const PicoSliverScaffoldTemplate({
  /// The slivers to display in the scroll view.
  required final List<Widget> slivers,

  /// The title text for the app bar.
  final String? title,

  /// A custom title widget (takes precedence over [title]).
  final Widget? titleWidget,

  /// Actions to display in the app bar.
  final List<Widget>? actions,

  /// A widget to display before the title.
  final Widget? leading,

  /// The height of the app bar when fully expanded.
  final double expandedHeight = 200.0,

  /// The height of the app bar when collapsed.
  final double? collapsedHeight,

  /// The widget to display behind the title when expanded.
  final Widget? flexibleSpace,

  /// Whether the app bar should become visible as soon as the user scrolls.
  final bool floating = false,

  /// Whether the app bar should remain visible at the start of the scroll
  /// view.
  final bool pinned = true,

  /// Whether the app bar should snap into view when scrolling.
  final bool snap = false,

  /// Whether the app bar should stretch when over-scrolled.
  final bool stretch = false,

  /// A floating action button.
  final Widget? floatingActionButton,

  /// Location of the floating action button.
  final FloatingActionButtonLocation? floatingActionButtonLocation,

  /// A bottom navigation bar.
  final Widget? bottomNavigationBar,

  /// The background color of the scaffold.
  final Color? backgroundColor,
  super.key,
}) extends StatelessWidget {
  /// Creates an [PicoSliverScaffoldTemplate].
  this;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return Scaffold(
      backgroundColor: backgroundColor ?? colors.background.main,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: expandedHeight,
            collapsedHeight: collapsedHeight,
            floating: floating,
            pinned: pinned,
            snap: snap,
            stretch: stretch,
            leading: leading,
            actions: actions,
            flexibleSpace:
                flexibleSpace ??
                FlexibleSpaceBar(
                  title:
                      titleWidget ??
                      (title != null
                          ? Text(title!, style: typography.heading.h4)
                          : null),
                  centerTitle: true,
                ),
          ),
          ...slivers,
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title))
      ..add(DoubleProperty('expandedHeight', expandedHeight))
      ..add(DoubleProperty('collapsedHeight', collapsedHeight))
      ..add(DiagnosticsProperty<bool>('floating', floating))
      ..add(DiagnosticsProperty<bool>('pinned', pinned))
      ..add(DiagnosticsProperty<bool>('snap', snap))
      ..add(DiagnosticsProperty<bool>('stretch', stretch))
      ..add(
        DiagnosticsProperty<FloatingActionButtonLocation?>(
          'floatingActionButtonLocation',
          floatingActionButtonLocation,
        ),
      )
      ..add(ColorProperty('backgroundColor', backgroundColor));
  }
}
