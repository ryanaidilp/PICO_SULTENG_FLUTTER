import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pico_ui_kit/src/extensions/extensions.dart';

/// A base page template with consistent padding and structure.
///
/// Provides a standardized layout for pages with optional header,
/// body content, and footer sections.
///
/// ```dart
/// PicoPageTemplate(
///   header: Text('Welcome'),
///   body: ListView(...),
///   footer: PicoButton(onPressed: () {}, child: Text('Continue')),
/// )
/// ```
class const PicoPageTemplate({
  /// The main content of the page.
  required final Widget body,

  /// An optional header displayed above the body.
  final Widget? header,

  /// An optional footer displayed below the body.
  final Widget? footer,

  /// Padding around the entire page content.
  final EdgeInsetsGeometry? padding,

  /// The background color of the page.
  final Color? backgroundColor,

  /// Whether header, body, and footer scroll together as one unit.
  final bool scrollable = true,

  /// Whether to add safe area padding at the top.
  final bool safeAreaTop = true,

  /// Whether to add safe area padding at the bottom.
  final bool safeAreaBottom = true,

  /// Custom padding for the footer section.
  final EdgeInsetsGeometry? footerPadding,

  /// Custom padding for the header section.
  final EdgeInsetsGeometry? headerPadding,

  /// Custom padding for the body section.
  final EdgeInsetsGeometry? bodyPadding,

  /// Keeps the footer fixed below the scroll area instead of scrolling with
  /// header and body. Ignored when [scrollable] is `false`.
  final bool footerPinned = false,
  super.key,
}) extends StatelessWidget {
  /// Creates an [PicoPageTemplate].
  this;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final defaultPadding = EdgeInsets.symmetric(horizontal: spacing.md);
    final resolvedFooterPadding =
        footerPadding ??
        EdgeInsets.all(spacing.md).copyWith(bottom: spacing.lg);

    final headerWidget = header == null
        ? null
        : Padding(padding: headerPadding ?? defaultPadding, child: header);
    final bodyWidget = Padding(
      padding: bodyPadding ?? defaultPadding,
      child: body,
    );
    final footerWidget = footer == null
        ? null
        : Padding(padding: resolvedFooterPadding, child: footer);

    Widget content;
    if (scrollable) {
      final pinFooter = footerPinned && footerWidget != null;
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ?headerWidget,
                  bodyWidget,
                  if (footerWidget != null && !pinFooter) footerWidget,
                ],
              ),
            ),
          ),
          if (pinFooter) footerWidget,
        ],
      );
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ?headerWidget,
          Expanded(child: bodyWidget),
          ?footerWidget,
        ],
      );
    }

    if (padding != null) {
      content = Padding(padding: padding!, child: content);
    }

    return ColoredBox(
      color: backgroundColor ?? colors.background.main,
      child: SafeArea(top: safeAreaTop, bottom: safeAreaBottom, child: content),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<EdgeInsetsGeometry?>('padding', padding))
      ..add(ColorProperty('backgroundColor', backgroundColor))
      ..add(DiagnosticsProperty<bool>('scrollable', scrollable))
      ..add(DiagnosticsProperty<bool>('safeAreaTop', safeAreaTop))
      ..add(DiagnosticsProperty<bool>('safeAreaBottom', safeAreaBottom))
      ..add(
        DiagnosticsProperty<EdgeInsetsGeometry?>(
          'footerPadding',
          footerPadding,
        ),
      )
      ..add(
        DiagnosticsProperty<EdgeInsetsGeometry?>(
          'headerPadding',
          headerPadding,
        ),
      )
      ..add(
        DiagnosticsProperty<EdgeInsetsGeometry?>('bodyPadding', bodyPadding),
      )
      ..add(DiagnosticsProperty<bool>('footerPinned', footerPinned));
  }
}

/// A centered content page template.
///
/// Useful for authentication, onboarding, or empty state pages
/// where content should be vertically centered.
///
/// ```dart
/// PicoCenteredPageTemplate(
///   icon: Icon(Icons.lock),
///   title: 'Sign In',
///   subtitle: 'Enter your credentials',
///   content: Column(...),
///   actions: [
///     PicoButton(...),
///   ],
/// )
/// ```
class const PicoCenteredPageTemplate({
  /// An optional icon displayed at the top.
  final Widget? icon,

  /// The title text.
  final String? title,

  /// The subtitle text.
  final String? subtitle,

  /// Additional content below the subtitle.
  final Widget? content,

  /// Action buttons at the bottom.
  final List<Widget>? actions,

  /// Padding around the content.
  final EdgeInsetsGeometry? padding,

  /// The background color.
  final Color? backgroundColor,

  /// Whether the content should be scrollable.
  final bool scrollable = true,

  /// Cross axis alignment for the content.
  final CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,

  /// Spacing between elements.
  final double? spacing,
  super.key,
}) extends StatelessWidget {
  /// Creates an [PicoCenteredPageTemplate].
  this;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final appSpacing = context.spacing;
    final elementSpacing = spacing ?? appSpacing.md;

    Widget child = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[icon!, SizedBox(height: elementSpacing * 2)],
        if (title != null) ...[
          Text(
            title!,
            style: typography.heading.h2,
            textAlign: crossAxisAlignment == CrossAxisAlignment.center
                ? TextAlign.center
                : null,
          ),
          SizedBox(height: elementSpacing / 2),
        ],
        if (subtitle != null) ...[
          Text(
            subtitle!,
            style: typography.body.large.copyWith(
              color: colors.foreground.subtle,
            ),
            textAlign: crossAxisAlignment == CrossAxisAlignment.center
                ? TextAlign.center
                : null,
          ),
          SizedBox(height: elementSpacing * 2),
        ],
        if (content != null) ...[
          content!,
          SizedBox(height: elementSpacing * 2),
        ],
        if (actions != null && actions!.isNotEmpty) ...[
          ...actions!.map(
            (action) => Padding(
              padding: EdgeInsets.only(bottom: elementSpacing / 2),
              child: action,
            ),
          ),
        ],
      ],
    );

    if (scrollable) {
      child = SingleChildScrollView(child: child);
    }

    return ColoredBox(
      color: backgroundColor ?? colors.background.main,
      child: SafeArea(
        child: Padding(
          padding: padding ?? EdgeInsets.all(appSpacing.lg),
          child: Center(child: child),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title))
      ..add(StringProperty('subtitle', subtitle))
      ..add(DiagnosticsProperty<EdgeInsetsGeometry?>('padding', padding))
      ..add(ColorProperty('backgroundColor', backgroundColor))
      ..add(DiagnosticsProperty<bool>('scrollable', scrollable))
      ..add(
        EnumProperty<CrossAxisAlignment>(
          'crossAxisAlignment',
          crossAxisAlignment,
        ),
      )
      ..add(DoubleProperty('spacing', spacing));
  }
}

/// A loading page template.
///
/// Displays a centered loading indicator with optional message.
///
/// ```dart
/// PicoLoadingPageTemplate(
///   message: 'Loading your data...',
/// )
/// ```
class const PicoLoadingPageTemplate({
  /// An optional message to display below the indicator.
  final String? message,

  /// A custom loading indicator.
  final Widget? indicator,

  /// The background color.
  final Color? backgroundColor,
  super.key,
}) extends StatelessWidget {
  /// Creates an [PicoLoadingPageTemplate].
  this;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final spacing = context.spacing;

    return ColoredBox(
      color: backgroundColor ?? colors.background.main,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            indicator ??
                CircularProgressIndicator(color: colors.action.primary.active),
            if (message != null) ...[
              SizedBox(height: spacing.md),
              Text(
                message!,
                style: typography.body.regular.copyWith(
                  color: colors.foreground.subtle,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('message', message))
      ..add(ColorProperty('backgroundColor', backgroundColor));
  }
}

/// An error page template.
///
/// Displays an error message with optional retry action.
///
/// ```dart
/// PicoErrorPageTemplate(
///   title: 'Oops!',
///   message: 'Something went wrong',
///   onRetry: () => refresh(),
/// )
/// ```
class const PicoErrorPageTemplate({
  /// An optional icon to display.
  final Widget? icon,

  /// The error title.
  final String? title,

  /// The error message.
  final String? message,

  /// Callback when retry is pressed.
  final VoidCallback? onRetry,

  /// Label for the retry button.
  final String retryLabel = 'Try Again',

  /// The background color.
  final Color? backgroundColor,
  super.key,
}) extends StatelessWidget {
  /// Creates an [PicoErrorPageTemplate].
  this;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final spacing = context.spacing;

    return ColoredBox(
      color: backgroundColor ?? colors.background.main,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(spacing.lg),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                icon ??
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: colors.action.destructive.active,
                    ),
                if (title != null) ...[
                  SizedBox(height: spacing.md),
                  Text(
                    title!,
                    style: typography.heading.h4,
                    textAlign: TextAlign.center,
                  ),
                ],
                if (message != null) ...[
                  SizedBox(height: spacing.sm),
                  Text(
                    message!,
                    style: typography.body.regular.copyWith(
                      color: colors.foreground.subtle,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                if (onRetry != null) ...[
                  SizedBox(height: spacing.lg),
                  FilledButton(onPressed: onRetry, child: Text(retryLabel)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title))
      ..add(StringProperty('message', message))
      ..add(ObjectFlagProperty<VoidCallback?>.has('onRetry', onRetry))
      ..add(StringProperty('retryLabel', retryLabel))
      ..add(ColorProperty('backgroundColor', backgroundColor));
  }
}

/// An empty state page template.
///
/// Displays a message when there's no content to show.
///
/// ```dart
/// PicoEmptyStateTemplate(
///   icon: Icon(Icons.inbox),
///   title: 'No messages',
///   message: 'Your inbox is empty',
///   action: PicoButton(
///     onPressed: () => compose(),
///     child: Text('Compose'),
///   ),
/// )
/// ```
class const PicoEmptyStateTemplate({
  /// An optional icon to display.
  final Widget? icon,

  /// The title text.
  final String? title,

  /// The descriptive message.
  final String? message,

  /// An optional action button.
  final Widget? action,

  /// The background color.
  final Color? backgroundColor,
  super.key,
}) extends StatelessWidget {
  /// Creates an [PicoEmptyStateTemplate].
  this;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final spacing = context.spacing;

    return ColoredBox(
      color: backgroundColor ?? colors.background.main,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(spacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                IconTheme(
                  data: IconThemeData(size: 64, color: colors.foreground.muted),
                  child: icon!,
                ),
                SizedBox(height: spacing.md),
              ],
              if (title != null) ...[
                Text(
                  title!,
                  style: typography.heading.h5,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: spacing.xs),
              ],
              if (message != null)
                Text(
                  message!,
                  style: typography.body.regular.copyWith(
                    color: colors.foreground.subtle,
                  ),
                  textAlign: TextAlign.center,
                ),
              if (action != null) ...[SizedBox(height: spacing.lg), action!],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title))
      ..add(StringProperty('message', message))
      ..add(ColorProperty('backgroundColor', backgroundColor));
  }
}
