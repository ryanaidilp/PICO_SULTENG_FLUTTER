import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pico_ui_kit/src/extensions/extensions.dart';
import 'package:pico_ui_kit/src/foundations/themes/extensions/pico_color_extension.dart';

/// Size variants for [PicoAppBar].
enum PicoAppBarSize(
  /// The height of the app bar.
  final double height,
) {
  /// Compact app bar (48px).
  sm(48),

  /// Standard app bar (56px - default).
  md(56),

  /// Large app bar (64px).
  lg(64),
}

/// Style variants for [PicoAppBar].
enum PicoAppBarStyle() {
  /// Solid background color.
  solid,

  /// Transparent background with optional blur.
  transparent,

  /// Elevated with shadow.
  elevated,
}

/// A customizable app bar component following the design system.
///
/// Provides a flexible top app bar with support for leading and trailing
/// actions, custom title widget, and various styles.
///
/// ```dart
/// // Basic usage
/// PicoAppBar(
///   title: 'Dashboard',
/// )
///
/// // With navigation back button
/// PicoAppBar(
///   title: 'Settings',
///   leading: IconButton(
///     icon: Icon(Icons.arrow_back),
///     onPressed: () => Navigator.pop(context),
///   ),
/// )
///
/// // With trailing actions
/// PicoAppBar(
///   title: 'Messages',
///   actions: [
///     IconButton(icon: Icon(Icons.search), onPressed: () => search()),
///     IconButton(icon: Icon(Icons.more_vert), onPressed: () => showMenu()),
///   ],
/// )
///
/// // With custom title widget
/// PicoAppBar(
///   titleWidget: Row(
///     children: [
///       CircleAvatar(child: Text('JD')),
///       SizedBox(width: 8),
///       Text('John Doe'),
///     ],
///   ),
/// )
/// ```
class const PicoAppBar({
  /// The title text displayed in the app bar.
  final String? title,

  /// Custom widget displayed as the title.
  final Widget? titleWidget,

  /// Widget displayed before the title.
  final Widget? leading,

  /// Widgets displayed after the title.
  final List<Widget>? actions,

  /// Widget displayed below the app bar.
  final PreferredSizeWidget? bottom,

  /// The size variant of the app bar.
  final PicoAppBarSize size = PicoAppBarSize.md,

  /// The style variant of the app bar.
  final PicoAppBarStyle style = PicoAppBarStyle.solid,

  /// Whether to center the title.
  final bool centerTitle = false,

  /// Whether to show the back button automatically.
  final bool showBackButton = false,

  /// Callback when the back button is pressed.
  final VoidCallback? onBackPressed,

  /// Custom background color.
  final Color? backgroundColor,

  /// Custom foreground color for title and icons.
  final Color? foregroundColor,

  /// Custom elevation for the app bar.
  final double? elevation,
  super.key,
}) extends StatelessWidget implements PreferredSizeWidget {
  /// Creates an [PicoAppBar].
  this
    : assert(
        title == null || titleWidget == null,
        'Cannot provide both title and titleWidget',
      );

  @override
  Size get preferredSize =>
      Size.fromHeight(size.height + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final typography = context.typography;

    final effectiveBackgroundColor = _resolveBackgroundColor(colors);
    final effectiveForegroundColor = _resolveForegroundColor(colors);
    final effectiveElevation = _resolveElevation;

    final effectiveLeading = _buildLeading(context, effectiveForegroundColor);

    final effectiveTitle =
        titleWidget ??
        (title != null
            ? Text(
                title!,
                style: typography.heading.h5.copyWith(
                  color: effectiveForegroundColor,
                ),
                overflow: TextOverflow.ellipsis,
              )
            : null);

    return Container(
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        boxShadow: effectiveElevation > 0
            ? [
                BoxShadow(
                  color: colors.foreground.main.withValues(alpha: 0.08),
                  blurRadius: effectiveElevation * 2,
                  offset: Offset(0, effectiveElevation),
                ),
              ]
            : null,
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: size.height,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: spacing.sm),
                child: Row(
                  children: [
                    if (effectiveLeading != null) ...[
                      effectiveLeading,
                      SizedBox(width: spacing.sm),
                    ],
                    if (centerTitle && effectiveTitle != null)
                      Expanded(child: Center(child: effectiveTitle))
                    else
                      Expanded(child: effectiveTitle ?? const SizedBox()),
                    if (actions != null && actions!.isNotEmpty) ...[
                      SizedBox(width: spacing.sm),
                      ...actions!.map(
                        (action) => IconTheme(
                          data: IconThemeData(
                            color: effectiveForegroundColor,
                            size: 24,
                          ),
                          child: action,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            ?bottom,
          ],
        ),
      ),
    );
  }

  Widget? _buildLeading(BuildContext context, Color fgColor) {
    if (leading != null) {
      return IconTheme(
        data: IconThemeData(color: fgColor, size: 24),
        child: leading!,
      );
    }

    if (showBackButton) {
      return GestureDetector(
        onTap: onBackPressed ?? () => Navigator.maybePop(context),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(Icons.arrow_back, size: 24, color: fgColor),
        ),
      );
    }

    return null;
  }

  Color _resolveBackgroundColor(PicoColorExtension colors) {
    if (backgroundColor != null) return backgroundColor!;

    return switch (style) {
      PicoAppBarStyle.solid => colors.background.main,
      PicoAppBarStyle.transparent => Colors.transparent,
      PicoAppBarStyle.elevated => colors.background.main,
    };
  }

  Color _resolveForegroundColor(PicoColorExtension colors) {
    if (foregroundColor != null) return foregroundColor!;
    return colors.foreground.main;
  }

  double get _resolveElevation {
    if (elevation != null) return elevation!;

    return switch (style) {
      PicoAppBarStyle.solid => 0,
      PicoAppBarStyle.transparent => 0,
      PicoAppBarStyle.elevated => 4,
    };
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title))
      ..add(EnumProperty<PicoAppBarSize>('size', size))
      ..add(EnumProperty<PicoAppBarStyle>('style', style))
      ..add(DiagnosticsProperty<bool>('centerTitle', centerTitle))
      ..add(DiagnosticsProperty<bool>('showBackButton', showBackButton))
      ..add(ColorProperty('backgroundColor', backgroundColor))
      ..add(ColorProperty('foregroundColor', foregroundColor))
      ..add(DoubleProperty('elevation', elevation))
      ..add(
        ObjectFlagProperty<VoidCallback?>.has('onBackPressed', onBackPressed),
      );
  }
}

/// A sliver-compatible version of [PicoAppBar] for use with
/// [CustomScrollView].
///
/// ```dart
/// CustomScrollView(
///   slivers: [
///     PicoSliverAppBar(
///       title: 'Profile',
///       expandedHeight: 200,
///       background: Image.network('https://example.com/cover.jpg'),
///     ),
///     SliverList(...),
///   ],
/// )
/// ```
class const PicoSliverAppBar({
  /// The title text displayed in the app bar.
  final String? title,

  /// Custom widget displayed as the title.
  final Widget? titleWidget,

  /// Widget displayed before the title.
  final Widget? leading,

  /// Widgets displayed after the title.
  final List<Widget>? actions,

  /// Background widget displayed when expanded.
  final Widget? background,

  /// The height of the app bar when expanded.
  final double expandedHeight = 200,

  /// The height of the app bar when collapsed.
  final double? collapsedHeight,

  /// Whether the app bar should remain visible when scrolled.
  final bool pinned = true,

  /// Whether the app bar should float when scrolling down.
  final bool floating = false,

  /// Whether the app bar should snap open when scrolling down.
  final bool snap = false,

  /// Whether the app bar should stretch when over-scrolled.
  final bool stretch = false,

  /// Whether to show the back button automatically.
  final bool showBackButton = false,

  /// Callback when the back button is pressed.
  final VoidCallback? onBackPressed,

  /// Custom background color.
  final Color? backgroundColor,

  /// Custom foreground color for title and icons.
  final Color? foregroundColor,
  super.key,
}) extends StatelessWidget {
  /// Creates an [PicoSliverAppBar].
  this;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    final effectiveBackgroundColor = backgroundColor ?? colors.background.main;
    final effectiveForegroundColor = foregroundColor ?? colors.foreground.main;

    final effectiveLeading = _buildLeading(context, effectiveForegroundColor);

    final effectiveTitle =
        titleWidget ??
        (title != null
            ? Text(
                title!,
                style: typography.heading.h5.copyWith(
                  color: effectiveForegroundColor,
                ),
              )
            : null);

    return SliverAppBar(
      title: effectiveTitle,
      leading: effectiveLeading,
      actions: actions
          ?.map(
            (action) => IconTheme(
              data: IconThemeData(color: effectiveForegroundColor, size: 24),
              child: action,
            ),
          )
          .toList(),
      expandedHeight: expandedHeight,
      collapsedHeight: collapsedHeight,
      pinned: pinned,
      floating: floating,
      snap: snap,
      stretch: stretch,
      backgroundColor: effectiveBackgroundColor,
      foregroundColor: effectiveForegroundColor,
      flexibleSpace: background != null
          ? FlexibleSpaceBar(background: background)
          : null,
      elevation: 0,
    );
  }

  Widget? _buildLeading(BuildContext context, Color fgColor) {
    if (leading != null) {
      return IconTheme(
        data: IconThemeData(color: fgColor, size: 24),
        child: leading!,
      );
    }

    if (showBackButton) {
      return GestureDetector(
        onTap: onBackPressed ?? () => Navigator.maybePop(context),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(Icons.arrow_back, size: 24, color: fgColor),
        ),
      );
    }

    return null;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title))
      ..add(DoubleProperty('expandedHeight', expandedHeight))
      ..add(DoubleProperty('collapsedHeight', collapsedHeight))
      ..add(DiagnosticsProperty<bool>('pinned', pinned))
      ..add(DiagnosticsProperty<bool>('floating', floating))
      ..add(DiagnosticsProperty<bool>('snap', snap))
      ..add(DiagnosticsProperty<bool>('stretch', stretch))
      ..add(DiagnosticsProperty<bool>('showBackButton', showBackButton))
      ..add(ColorProperty('backgroundColor', backgroundColor))
      ..add(ColorProperty('foregroundColor', foregroundColor))
      ..add(
        ObjectFlagProperty<VoidCallback?>.has('onBackPressed', onBackPressed),
      );
  }
}
