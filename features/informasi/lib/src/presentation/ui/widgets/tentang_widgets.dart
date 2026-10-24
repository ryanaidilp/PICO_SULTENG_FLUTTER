import 'package:flutter/material.dart';
import 'package:informasi/src/l10n/translations.g.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

/// A calm "Dalam peninjauan" marker for content that is not final. Text, with a
/// dashed look, so it is never only colour.
class ReviewMarker extends StatelessWidget {
  const ReviewMarker({required this.id, super.key});

  /// The marker id, one of `kOpenReviewMarkers`.
  final String id;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: context.t.reviewPending,
    child: ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.chartSurface.tint,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: context.colors.outline.strong),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            context.t.reviewPending,
            key: ValueKey('review-$id'),
            style: context.typography.label.caption.copyWith(
              color: context.colors.foreground.main,
            ),
          ),
        ),
      ),
    ),
  );
}

/// A section heading with an anchor key.
class AnchorHeading extends StatelessWidget {
  const AnchorHeading({required this.title, required this.anchor, super.key});

  final String title;
  final GlobalKey anchor;

  @override
  Widget build(BuildContext context) => Padding(
    key: anchor,
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: PicoSectionHeader(title: title),
  );
}

/// A body paragraph.
class Para extends StatelessWidget {
  const Para(this.text, {this.trailing, this.strong = false, super.key});

  final String text;

  /// Shown after the text (a [ReviewMarker]).
  final Widget? trailing;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final style = context.typography.body.regular.copyWith(
      color: context.colors.foreground.main,
      fontWeight: strong ? FontWeight.w600 : null,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: trailing == null
          ? Text(text, style: style)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: style),
                const SizedBox(height: 4),
                trailing!,
              ],
            ),
    );
  }
}
