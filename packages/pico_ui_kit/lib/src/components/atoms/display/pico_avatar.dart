import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pico_ui_kit/src/extensions/extensions.dart';
import 'package:pico_ui_kit/src/foundations/themes/extensions/pico_color_extension.dart';
import 'package:pico_ui_kit/src/foundations/themes/extensions/pico_typography_extension.dart';

/// Padding between avatar and loading ring.
const double _loadingRingPadding = 6.0;

/// Duration for size/fade animations.
const Duration _animationDuration = Duration(milliseconds: 300);

/// Duration for the result icon display.
const Duration _resultDisplayDuration = Duration(milliseconds: 1200);

/// Returns stroke width for loading ring based on avatar size.
double _getStrokeWidth(PicoAvatarSize size) => switch (size) {
  PicoAvatarSize.xs => 2.0,
  PicoAvatarSize.sm => 2.5,
  PicoAvatarSize.md => 3.0,
  PicoAvatarSize.lg => 3.5,
  PicoAvatarSize.xl => 4.0,
  PicoAvatarSize.xl2 => 4.5,
};

/// Scale factor when avatar shrinks during loading.
const double _loadingShrinkScale = 0.85;

/// Size variants for [PicoAvatar].
enum PicoAvatarSize(
  /// The size in logical pixels.
  final double size,
) {
  /// Extra small avatar (24px).
  xs(24),

  /// Small avatar (32px).
  sm(32),

  /// Medium avatar (40px).
  md(40),

  /// Large avatar (48px).
  lg(48),

  /// Extra large avatar (64px).
  xl(64),

  /// 2X large avatar (80px).
  xl2(80);

  /// Returns the icon size for this avatar size.
  double get iconSize => size * 0.5;

  /// Returns the font size for initials.
  double get fontSize => size * 0.4;

  /// Returns the result icon size.
  double get resultIconSize => size * 0.45;
}

/// Loading result state for [PicoAvatar].
enum PicoAvatarLoadingResult() {
  /// Loading completed successfully.
  success,

  /// Loading failed.
  failure,
}

/// A customizable avatar component following the design system.
///
/// Supports image, initials, or icon display with multiple sizes.
/// Features smooth animated loading states with progress ring,
/// success/failure indicators, and size transitions.
///
/// ```dart
/// // With image
/// PicoAvatar(
///   imageUrl: 'https://example.com/photo.jpg',
///   size: PicoAvatarSize.md,
/// )
///
/// // With initials
/// PicoAvatar(
///   initials: 'JD',
///   size: PicoAvatarSize.md,
/// )
///
/// // With loading indicator (for upload progress)
/// PicoAvatar(
///   imageUrl: 'https://example.com/photo.jpg',
///   isLoading: true,
///   loadingProgress: 0.5, // Optional: 0.0 to 1.0
///   onLoadingComplete: (result) => print('Loading $result'),
/// )
/// ```
class const PicoAvatar({
  /// URL of the image to display.
  final String? imageUrl,

  /// Initials to display when no image is available.
  final String? initials,

  /// Icon to display when no image or initials are available.
  final IconData? icon,

  /// The size of the avatar.
  final PicoAvatarSize size = PicoAvatarSize.md,

  /// Background color of the avatar.
  final Color? backgroundColor,

  /// Foreground color for initials or icon.
  final Color? foregroundColor,

  /// Callback when the avatar is tapped.
  final VoidCallback? onTap,

  /// Width of the border around the avatar.
  final double? borderWidth,

  /// Color of the border around the avatar.
  final Color? borderColor,

  /// Whether to show a loading indicator overlay.
  final bool isLoading = false,

  /// Optional loading progress value from 0.0 to 1.0.
  final double? loadingProgress,

  /// Color of the loading indicator.
  final Color? loadingColor,

  /// The result of loading operation.
  final PicoAvatarLoadingResult? loadingResult,

  /// Callback when loading animation completes (after result is shown).
  final ValueChanged<PicoAvatarLoadingResult?>? onLoadingComplete,
  super.key,
}) extends StatefulWidget {
  /// Creates an [PicoAvatar].
  this;

  @override
  State<PicoAvatar> createState() => _PicoAvatarState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('imageUrl', imageUrl))
      ..add(StringProperty('initials', initials))
      ..add(DiagnosticsProperty<IconData?>('icon', icon))
      ..add(EnumProperty<PicoAvatarSize>('size', size))
      ..add(ColorProperty('backgroundColor', backgroundColor))
      ..add(ColorProperty('foregroundColor', foregroundColor))
      ..add(DoubleProperty('borderWidth', borderWidth))
      ..add(ColorProperty('borderColor', borderColor))
      ..add(DiagnosticsProperty<bool>('isLoading', isLoading))
      ..add(DoubleProperty('loadingProgress', loadingProgress))
      ..add(ColorProperty('loadingColor', loadingColor))
      ..add(
        EnumProperty<PicoAvatarLoadingResult?>('loadingResult', loadingResult),
      )
      ..add(ObjectFlagProperty<VoidCallback?>.has('onTap', onTap))
      ..add(
        ObjectFlagProperty<ValueChanged<PicoAvatarLoadingResult?>?>.has(
          'onLoadingComplete',
          onLoadingComplete,
        ),
      );
  }
}

class _PicoAvatarState()
    extends State<PicoAvatar>
    with TickerProviderStateMixin {
  late AnimationController _sizeController;
  late AnimationController _progressController;
  late AnimationController _resultController;

  late Animation<double> _sizeAnimation;
  late Animation<double> _overlayAnimation;
  late Animation<double> _progressAnimation;
  late Animation<double> _resultScaleAnimation;
  late Animation<double> _resultOpacityAnimation;

  double _currentProgress = 0.0;
  double _targetProgress = 0.0;
  bool _showResult = false;
  PicoAvatarLoadingResult? _displayedResult;
  bool _wasLoading = false;
  Color? _resultRingColor;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();

    if (widget.isLoading) {
      _wasLoading = true;
      _sizeController.forward();
    }

    if (widget.loadingProgress != null) {
      _currentProgress = widget.loadingProgress!;
      _targetProgress = widget.loadingProgress!;
    }
  }

  void _initializeAnimations() {
    _sizeController = AnimationController(
      duration: _animationDuration,
      vsync: this,
    );

    _sizeAnimation = Tween<double>(begin: 1.0, end: _loadingShrinkScale)
        .animate(
          CurvedAnimation(parent: _sizeController, curve: Curves.easeOutCubic),
        );

    _overlayAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _sizeController, curve: Curves.easeOut));

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOut),
    );

    _progressController.addListener(_updateProgress);

    _resultController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _resultScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: 1.2,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.2,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 40,
      ),
    ]).animate(_resultController);

    _resultOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _resultController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );
  }

  void _updateProgress() {
    setState(() {
      _currentProgress = _progressAnimation.value;
    });
  }

  @override
  void didUpdateWidget(PicoAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isLoading && !oldWidget.isLoading) {
      _wasLoading = true;
      _showResult = false;
      _displayedResult = null;
      _sizeController.forward();
    } else if (!widget.isLoading && oldWidget.isLoading) {
      if (widget.loadingResult != null) {
        _showResultAnimation(widget.loadingResult!);
      } else {
        _hideLoading();
      }
    }

    if (widget.loadingProgress != null &&
        widget.loadingProgress != _targetProgress) {
      _animateProgressTo(widget.loadingProgress!);
    }
  }

  void _animateProgressTo(double target) {
    final oldProgress = _currentProgress;
    _targetProgress = target;

    _progressAnimation = Tween<double>(begin: oldProgress, end: target).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOut),
    );

    _progressController
      ..reset()
      ..forward();
  }

  Future<void> _showResultAnimation(PicoAvatarLoadingResult result) async {
    final colors = context.colors;

    if (_targetProgress > 0 && _currentProgress < 1.0) {
      _animateProgressTo(1.0);
      await Future<void>.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
    }

    setState(() {
      _showResult = true;
      _displayedResult = result;
      _resultRingColor = result == PicoAvatarLoadingResult.success
          ? colors.action.success.active
          : colors.action.destructive.active;
      _currentProgress = 1.0;
      _targetProgress = 1.0;
    });

    await _resultController.forward();
    await Future<void>.delayed(_resultDisplayDuration);

    if (!mounted) return;

    await _resultController.reverse();

    if (!mounted) return;

    await _hideLoading();

    widget.onLoadingComplete?.call(result);
  }

  Future<void> _hideLoading() async {
    if (_targetProgress > 0 && _currentProgress < 1.0) {
      _animateProgressTo(1.0);
      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;
    }

    await _sizeController.reverse();
    if (mounted) {
      setState(() {
        _showResult = false;
        _displayedResult = null;
        _wasLoading = false;
        _currentProgress = 0.0;
        _targetProgress = 0.0;
        _resultRingColor = null;
      });
    }
  }

  @override
  void dispose() {
    _sizeController.dispose();
    _progressController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    final effectiveBackgroundColor =
        widget.backgroundColor ??
        colors.action.primary.active.withValues(alpha: 0.1);
    final effectiveForegroundColor =
        widget.foregroundColor ?? colors.action.primary.active;
    final effectiveLoadingColor =
        widget.loadingColor ?? colors.action.primary.active;

    Widget content;
    if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
      content = ClipOval(
        child: Image.network(
          widget.imageUrl!,
          width: widget.size.size,
          height: widget.size.size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildFallback(colors, typography, effectiveForegroundColor),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildPlaceholder(colors);
          },
        ),
      );
    } else {
      content = _buildFallback(colors, typography, effectiveForegroundColor);
    }

    final baseAvatar = Container(
      width: widget.size.size,
      height: widget.size.size,
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        shape: BoxShape.circle,
        border: widget.borderWidth != null && widget.borderWidth! > 0
            ? Border.all(
                color: widget.borderColor ?? colors.outline.main,
                width: widget.borderWidth!,
              )
            : null,
      ),
      child: content,
    );

    if (!widget.isLoading && !_wasLoading) {
      return _wrapWithTap(baseAvatar);
    }

    final ringSize = widget.size.size + _loadingRingPadding * 2;
    final strokeWidth = _getStrokeWidth(widget.size);

    return _wrapWithTap(
      AnimatedBuilder(
        animation: Listenable.merge([_sizeController, _resultController]),
        builder: (context, child) {
          final ringOpacity =
              1.0 -
              ((_sizeAnimation.value - _loadingShrinkScale) /
                  (1.0 - _loadingShrinkScale));
          final showRing = ringOpacity > 0.01;

          return SizedBox(
            width: ringSize,
            height: ringSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (showRing)
                  Positioned.fill(
                    child: Opacity(
                      opacity: ringOpacity.clamp(0.0, 1.0),
                      child: _AnimatedProgressRing(
                        progress: widget.loadingProgress != null
                            ? _currentProgress
                            : null,
                        strokeWidth: strokeWidth,
                        color: _resultRingColor ?? effectiveLoadingColor,
                        backgroundColor: colors.outline.subtle,
                      ),
                    ),
                  ),
                Transform.scale(
                  scale: _sizeAnimation.value,
                  child: Stack(
                    children: [
                      baseAvatar,
                      if (_overlayAnimation.value > 0)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: colors.background.main.withValues(
                                alpha: 0.4 * _overlayAnimation.value,
                              ),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (_showResult && _displayedResult != null)
                  Transform.scale(
                    scale: _resultScaleAnimation.value,
                    child: Opacity(
                      opacity: _resultOpacityAnimation.value,
                      child: _buildResultIcon(colors),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultIcon(PicoColorExtension colors) {
    final isSuccess = _displayedResult == PicoAvatarLoadingResult.success;
    final iconSize = widget.size.resultIconSize;
    final containerSize = iconSize * 1.6;

    return Container(
      width: containerSize,
      height: containerSize,
      decoration: BoxDecoration(
        color: isSuccess
            ? colors.action.success.active
            : colors.action.destructive.active,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color:
                (isSuccess
                        ? colors.action.success.active
                        : colors.action.destructive.active)
                    .withValues(alpha: 0.3),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(
        isSuccess ? Icons.check_rounded : Icons.close_rounded,
        size: iconSize,
        color: Colors.white,
      ),
    );
  }

  Widget _wrapWithTap(Widget child) {
    if (widget.onTap != null) {
      return GestureDetector(onTap: widget.onTap, child: child);
    }
    return child;
  }

  Widget _buildFallback(
    PicoColorExtension colors,
    PicoTypographyExtension typography,
    Color foregroundColor,
  ) {
    if (widget.initials != null && widget.initials!.isNotEmpty) {
      return Center(
        child: Text(
          widget.initials!.toUpperCase().substring(
            0,
            widget.initials!.length.clamp(0, 2),
          ),
          style: typography.body.smallMedium.copyWith(
            fontSize: widget.size.fontSize,
            color: foregroundColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Center(
      child: Icon(
        widget.icon ?? Icons.person_outline,
        size: widget.size.iconSize,
        color: foregroundColor,
      ),
    );
  }

  Widget _buildPlaceholder(PicoColorExtension colors) => Center(
    child: SizedBox(
      width: widget.size.iconSize,
      height: widget.size.iconSize,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(colors.foreground.muted),
      ),
    ),
  );
}

/// An animated progress ring with smooth transitions.
class const _AnimatedProgressRing({
  required final double strokeWidth,
  required final Color color,
  required final Color backgroundColor,
  final double? progress,
}) extends StatefulWidget {
  @override
  State<_AnimatedProgressRing> createState() => _AnimatedProgressRingState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('progress', progress))
      ..add(DoubleProperty('strokeWidth', strokeWidth))
      ..add(ColorProperty('color', color))
      ..add(ColorProperty('backgroundColor', backgroundColor));
  }
}

class _AnimatedProgressRingState()
    extends State<_AnimatedProgressRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _indeterminateController;

  @override
  void initState() {
    super.initState();
    _indeterminateController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    if (widget.progress == null) {
      _indeterminateController.repeat();
    }
  }

  @override
  void didUpdateWidget(_AnimatedProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.progress == null && oldWidget.progress != null) {
      _indeterminateController.repeat();
    } else if (widget.progress != null && oldWidget.progress == null) {
      _indeterminateController.stop();
    }
  }

  @override
  void dispose() {
    _indeterminateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.progress != null) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: widget.progress),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        builder: (context, value, child) => CustomPaint(
          painter: _ProgressRingPainter(
            progress: value,
            strokeWidth: widget.strokeWidth,
            color: widget.color,
            backgroundColor: widget.backgroundColor,
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _indeterminateController,
      builder: (context, child) => CustomPaint(
        painter: _IndeterminateRingPainter(
          animationValue: _indeterminateController.value,
          strokeWidth: widget.strokeWidth,
          color: widget.color,
          backgroundColor: widget.backgroundColor,
        ),
      ),
    );
  }
}

class _ProgressRingPainter({
  required final double progress,
  required final double strokeWidth,
  required final Color color,
  required final Color backgroundColor,
}) extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_ProgressRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.backgroundColor != backgroundColor;
}

class _IndeterminateRingPainter({
  required final double animationValue,
  required final double strokeWidth,
  required final Color color,
  required final Color backgroundColor,
}) extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final startAngle = 2 * math.pi * animationValue - math.pi / 2;
    const sweepAngle = math.pi * 0.8;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_IndeterminateRingPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue ||
      oldDelegate.color != color;
}
