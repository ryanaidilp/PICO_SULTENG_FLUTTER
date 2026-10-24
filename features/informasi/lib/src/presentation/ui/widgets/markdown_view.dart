import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:informasi/src/domain/markdown.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

/// Renders the Markdown subset. Links call [onLink] with the raw target:
/// a path starting with `/` is in-app, anything else opens outside the app.
class MarkdownView extends StatefulWidget {
  const new({required this.source, required this.onLink, super.key});

  final String source;
  final ValueChanged<String> onLink;

  @override
  State<MarkdownView> createState() => _MarkdownViewState();
}

class _MarkdownViewState extends State<MarkdownView> {
  final _recognizers = <TapGestureRecognizer>[];

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  TapGestureRecognizer _tap(String target) {
    final r = TapGestureRecognizer()..onTap = () => widget.onLink(target);
    _recognizers.add(r);
    return r;
  }

  InlineSpan _span(List<MdSpan> spans, TextStyle style) {
    final link = style.copyWith(
      color: Theme.of(context).colorScheme.primary,
      decoration: TextDecoration.underline,
    );
    return TextSpan(
      style: style,
      children: [
        for (final s in spans)
          if (s.link == null)
            TextSpan(text: s.text)
          else
            TextSpan(
              text: s.text,
              style: link,
              recognizer: _tap(s.link!),
              semanticsLabel: s.text,
            ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    _recognizers.clear();
    final body = context.typography.body.regular.copyWith(
      color: context.colors.foreground.main,
    );
    final blocks = parseMarkdown(widget.source);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final b in blocks)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: switch (b) {
              MdHeading(:final level, :final spans) => Semantics(
                header: true,
                child: Text.rich(
                  _span(
                    spans,
                    (level == 1
                            ? context.typography.heading.h3
                            : context.typography.heading.h4)
                        .copyWith(color: context.colors.foreground.main),
                  ),
                ),
              ),
              MdParagraph(:final spans) => Text.rich(_span(spans, body)),
              MdList(:final ordered, :final items) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < items.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 28,
                            child: Text(
                              ordered ? '${i + 1}.' : '•',
                              style: body,
                            ),
                          ),
                          Expanded(child: Text.rich(_span(items[i], body))),
                        ],
                      ),
                    ),
                ],
              ),
            },
          ),
      ],
    );
  }
}
