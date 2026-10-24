/// Slugs of the bundled articles, in the order of the list.
const kTipSlugs = [
  'cuci-tangan',
  'pakai-masker',
  'jaga-jarak',
  'vaksinasi',
  'gejala',
  'isolasi-mandiri',
];

/// Locales an article exists in.
const kTipLocales = ['id', 'en'];

/// One bundled article: front matter plus the Markdown body.
class Tip {
  const new({
    required this.slug,
    required this.title,
    required this.body,
    required this.reviewed,
    required this.sources,
    this.illustration,
    this.icon,
  });

  final String slug;
  final String title;
  final String body;

  /// False until a health professional reviews it (O-11).
  final bool reviewed;
  final List<Uri> sources;

  /// Brand illustration name, for example `pico-tip-wash-hands`.
  final String? illustration;

  /// Brand icon key, used when there is no illustration.
  final String? icon;
}

/// Parses `---` front matter (`title`, `illustration`, `icon`, `reviewed`,
/// `sources:` with `  - url` lines) and the body. Throws [FormatException] on
/// a file with no front matter or no title.
Tip parseTip(String slug, String raw) {
  final lines = raw.replaceAll('\r\n', '\n').split('\n');
  if (lines.isEmpty || lines.first.trim() != '---') {
    throw FormatException('No front matter in $slug');
  }
  final end = lines.indexWhere((l) => l.trim() == '---', 1);
  if (end < 0) throw FormatException('Front matter not closed in $slug');
  final fields = <String, String>{};
  final sources = <Uri>[];
  var inSources = false;
  for (final l in lines.sublist(1, end)) {
    if (l.trim().isEmpty) continue;
    if (inSources && l.trimLeft().startsWith('- ')) {
      final u = Uri.tryParse(l.trimLeft().substring(2).trim());
      if (u != null && u.hasScheme) sources.add(u);
      continue;
    }
    inSources = false;
    final i = l.indexOf(':');
    if (i < 0) continue;
    final key = l.substring(0, i).trim();
    final value = l.substring(i + 1).trim();
    if (key == 'sources') {
      inSources = true;
    } else {
      fields[key] = value;
    }
  }
  final title = fields['title'];
  if (title == null || title.isEmpty) {
    throw FormatException('No title in $slug');
  }
  return Tip(
    slug: slug,
    title: title,
    body: lines.sublist(end + 1).join('\n').trim(),
    reviewed: fields['reviewed'] == 'true',
    sources: sources,
    illustration: fields['illustration'],
    icon: fields['icon'],
  );
}
