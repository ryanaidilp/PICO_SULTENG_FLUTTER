/// A commit parsed per Conventional Commits 1.0.
class const ConventionalCommit({
  /// The text after the header colon, or the whole subject when [type] is null.
  required final String description,

  /// Lowercased type, or `null` when the subject is not a conventional header.
  final String? type,

  /// Optional scope in parentheses.
  final String? scope,

  /// True for a `!` header marker or a `BREAKING CHANGE:` footer.
  final bool isBreaking = false,

  /// The `BREAKING CHANGE:` footer text, when there is one.
  final String? breakingNote,
}) {
  /// Creates a [ConventionalCommit].
  this;

  static final _header = RegExp(r'^(\w+)(?:\(([^)]+)\))?(!)?: (.+)$');
  static final _footer = RegExp(r'^BREAKING[ -]CHANGE: (.+)$', multiLine: true);

  /// Parses a commit [subject] and optional [body].
  // ignore: unnecessary_type_name_in_constructor, `factory .parse` does not compile on 3.13.
  factory ConventionalCommit.parse(String subject, [String body = '']) {
    final note = _footer.firstMatch(body)?.group(1)?.trim();
    final match = _header.firstMatch(subject.trim());
    if (match == null) {
      return ConventionalCommit(
        description: subject.trim(),
        isBreaking: note != null,
        breakingNote: note,
      );
    }
    return ConventionalCommit(
      type: match.group(1)!.toLowerCase(),
      scope: match.group(2),
      description: match.group(4)!.trim(),
      isBreaking: match.group(3) != null || note != null,
      breakingNote: note,
    );
  }
}
