import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:informasi/src/domain/markdown.dart';
import 'package:informasi/src/domain/tip.dart';

void main() {
  group('asset completeness', () {
    for (final slug in kTipSlugs) {
      for (final l in kTipLocales) {
        test('$slug.$l exists, parses, cites a source, has no HTML', () {
          final f = File('assets/tips/$slug.$l.md');
          expect(f.existsSync(), isTrue, reason: f.path);
          final tip = parseTip(slug, f.readAsStringSync());
          expect(tip.title, isNotEmpty);
          expect(tip.sources, isNotEmpty);
          expect(
            tip.sources.every(
              (u) =>
                  u.host.endsWith('who.int') || u.host.endsWith('kemkes.go.id'),
            ),
            isTrue,
            reason: 'sources are WHO or Kemenkes',
          );
          expect(tip.illustration != null || tip.icon != null, isTrue);
          expect(tip.body, isNot(contains('<')), reason: 'no HTML');
          expect(tip.reviewed, isFalse, reason: 'O-11: not reviewed yet');
        });
      }
      test('$slug has the same structure in id and en', () {
        List<String> shape(String l) => [
          for (final b in parseMarkdown(
            parseTip(
              slug,
              File('assets/tips/$slug.$l.md').readAsStringSync(),
            ).body,
          ))
            switch (b) {
              MdHeading(:final level) => 'h$level',
              MdParagraph() => 'p',
              MdList(:final items, :final ordered) =>
                '${ordered ? 'ol' : 'ul'}${items.length}',
            },
        ];
        expect(shape('en'), shape('id'));
      });
    }

    test('the pubspec bundles the tips folder', () {
      expect(File('pubspec.yaml').readAsStringSync(), contains('assets/tips/'));
    });

    test('no stray article is left out of the list', () {
      final files = Directory('assets/tips')
          .listSync()
          .map((e) => e.path.split('/').last)
          .toSet();
      expect(files.length, kTipSlugs.length * kTipLocales.length);
    });
  });

  group('medical wording stays on the verified text', () {
    test('119 is the Kemenkes medical emergency service, no other numbers', () {
      for (final l in kTipLocales) {
        for (final slug in kTipSlugs) {
          final body = File('assets/tips/$slug.$l.md').readAsStringSync();
          final numbers = RegExp(r'\b\d{3,}\b')
              .allMatches(body)
              .map((m) => m.group(0));
          // Only 119 may appear as a phone number; 2020, 2023 etc. are years.
          expect(
            numbers.where(
              (n) => n!.length == 3 && n != '119' && !n.startsWith('2'),
            ),
            isEmpty,
            reason: '$slug.$l',
          );
        }
      }
      final id = File('assets/tips/gejala.id.md').readAsStringSync();
      expect(id, contains('119, layanan darurat medis Kementerian Kesehatan'));
      expect(id, contains('di bawah 93%'));
      expect(
        File('assets/tips/vaksinasi.id.md').readAsStringSync(),
        isNot(contains('dianjurkan pemerintah')),
      );
    });
  });

  group('parseTip and parseMarkdown', () {
    test('front matter fields and a missing title', () {
      final t = parseTip(
        'x',
        '---\ntitle: A\nreviewed: true\nsources:\n  - https://a.b/c\n---\n\nHi',
      );
      expect(
        (t.title, t.reviewed, t.sources.single.host, t.body),
        ('A', true, 'a.b', 'Hi'),
      );
      expect(
        () => parseTip('x', '---\nreviewed: true\n---\nHi'),
        throwsFormatException,
      );
      expect(() => parseTip('x', 'no front matter'), throwsFormatException);
    });

    test('headings, paragraphs, lists and links; HTML stays text', () {
      final b = parseMarkdown(
        '## H\n\nOne [link](https://x.y) two\n<b>x</b>\n\n- a\n- b\n\n1. c\n2. d\n',
      );
      expect(b[0], isA<MdHeading>());
      final p = b[1] as MdParagraph;
      expect(p.spans.map((s) => s.link), [null, 'https://x.y', null]);
      expect(p.spans.last.text, contains('<b>x</b>'));
      expect((b[2] as MdList).ordered, isFalse);
      expect((b[3] as MdList).items.length, 2);
      expect((b[3] as MdList).ordered, isTrue);
    });
  });
}
