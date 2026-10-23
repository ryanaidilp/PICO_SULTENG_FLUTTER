import 'package:flutter/material.dart';
import 'package:pico_ui_kit/src/components/atoms/brand/pico_illustration.dart';
import 'package:pico_ui_kit/src/components/atoms/brand/pico_lottie.dart';
import 'package:pico_ui_kit/src/components/utilities/pico_kit_text.dart';
import 'package:pico_ui_kit/src/extensions/build_context_extensions.dart';

enum _Kind { loading, empty, error, offline, notFound }

/// A calm, designed state: loading, empty, error, offline or not found.
/// The copy is factual and uses no red. The loading Lottie is the only
/// looping animation, and it becomes a still image under reduced motion.
class PicoStateView extends StatelessWidget {
  const new _(this._kind, this.message, this.onRetry, {super.key});

  /// Loading: the weaving Lottie and "Memuat data".
  const new loading({String? message, Key? key})
    : this._(_Kind.loading, message, null, key: key);

  /// Empty: "Belum ada data" or [message].
  const new empty({String? message, Key? key})
    : this._(_Kind.empty, message, null, key: key);

  /// Error with a retry button.
  const new error({required VoidCallback onRetry, String? message, Key? key})
    : this._(_Kind.error, message, onRetry, key: key);

  /// Offline with a retry button. Text says "Tidak terhubung".
  const new offline({required VoidCallback onRetry, Key? key})
    : this._(_Kind.offline, null, onRetry, key: key);

  /// Not found.
  const new notFound({String? message, Key? key})
    : this._(_Kind.notFound, message, null, key: key);

  final _Kind _kind;

  /// Custom message, or null for the default copy.
  final String? message;

  /// Retry action for error and offline.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final t = PicoKitText.of(context);
    final (text, art) = switch (_kind) {
      _Kind.loading => (
        message ?? t.loading,
        const PicoLottie('pico-loading', width: 120, height: 120),
      ),
      _Kind.empty => (
        message ?? t.empty,
        const PicoIllustration('pico-state-empty', width: 220, height: 165),
      ),
      _Kind.error => (
        message ?? t.errorMessage,
        const PicoIllustration('pico-state-error', width: 220, height: 165),
      ),
      _Kind.offline => (
        t.offlineMessage,
        const PicoIllustration('pico-state-offline', width: 220, height: 165),
      ),
      _Kind.notFound => (
        message ?? t.notFoundMessage,
        const PicoIllustration('pico-state-not-found', width: 220, height: 165),
      ),
    };
    final retry = onRetry;
    // Scrolls instead of overflowing at large text scale.
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: box.hasBoundedHeight ? box.maxHeight : 0,
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ExcludeSemantics(child: art),
                  const SizedBox(height: 16),
                  Semantics(
                    liveRegion: _kind == _Kind.loading,
                    child: Text(
                      text,
                      textAlign: TextAlign.center,
                      style: context.typography.body.regular.copyWith(
                        color: context.colors.foreground.main,
                      ),
                    ),
                  ),
                  if (_kind == _Kind.offline) ...[
                    const SizedBox(height: 4),
                    Text(
                      t.offline,
                      style: context.typography.label.caption.copyWith(
                        color: context.colors.foreground.subtle,
                      ),
                    ),
                  ],
                  if (retry != null) ...[
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: retry,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(48, 48),
                      ),
                      child: Text(t.retry),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
