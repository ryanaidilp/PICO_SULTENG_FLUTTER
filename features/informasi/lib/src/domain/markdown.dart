/// A piece of inline text; [link] is set for `[text](url)`.
class MdSpan {
  const new(this.text, {this.link});

  final String text;
  final String? link;
}

/// A block of the small Markdown subset: headings, paragraphs, lists, links.
sealed class MdBlock {
  const new();
}

class MdHeading extends MdBlock {
  const new(this.level, this.spans);

  final int level;
  final List<MdSpan> spans;
}

class MdParagraph extends MdBlock {
  const new(this.spans);

  final List<MdSpan> spans;
}

class MdList extends MdBlock {
  const new({required this.ordered, required this.items});

  final bool ordered;
  final List<List<MdSpan>> items;
}

final _link = RegExp(r'\[([^\]]+)\]\(([^)\s]+)\)');
final _ordered = RegExp(r'^\d+\.\s+(.*)$');

/// Splits one line of text into plain and link spans. No HTML: tags stay text.
List<MdSpan> parseInline(String s) {
  final out = <MdSpan>[];
  var at = 0;
  for (final m in _link.allMatches(s)) {
    if (m.start > at) out.add(MdSpan(s.substring(at, m.start)));
    out.add(MdSpan(m.group(1)!, link: m.group(2)));
    at = m.end;
  }
  if (at < s.length) out.add(MdSpan(s.substring(at)));
  return out;
}

/// Parses [src] into blocks. Blank lines end a paragraph or a list.
List<MdBlock> parseMarkdown(String src) {
  final blocks = <MdBlock>[];
  final para = <String>[];
  List<List<MdSpan>>? list;
  var ordered = false;

  void flushPara() {
    if (para.isNotEmpty) {
      blocks.add(MdParagraph(parseInline(para.join(' '))));
      para.clear();
    }
  }

  void flushList() {
    if (list != null) {
      blocks.add(MdList(ordered: ordered, items: list!));
      list = null;
    }
  }

  for (final raw in src.replaceAll('\r\n', '\n').split('\n')) {
    final line = raw.trimRight();
    if (line.trim().isEmpty) {
      flushPara();
      flushList();
      continue;
    }
    final h = RegExp(r'^(#{1,3})\s+(.*)$').firstMatch(line);
    if (h != null) {
      flushPara();
      flushList();
      blocks.add(MdHeading(h.group(1)!.length, parseInline(h.group(2)!)));
      continue;
    }
    final bullet = line.startsWith('- ') ? line.substring(2) : null;
    final numbered = _ordered.firstMatch(line)?.group(1);
    if (bullet != null || numbered != null) {
      flushPara();
      final isOrdered = numbered != null;
      if (list != null && ordered != isOrdered) flushList();
      list ??= [];
      ordered = isOrdered;
      list!.add(parseInline(bullet ?? numbered!));
      continue;
    }
    flushList();
    para.add(line.trim());
  }
  flushPara();
  flushList();
  return blocks;
}
