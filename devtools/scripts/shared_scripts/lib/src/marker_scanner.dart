import 'package:meta/meta.dart';

/// Matches a single `archipelago:<slot>:start` or `archipelago:<slot>:end`
/// comment line, in either Dart (`//`) or YAML (`#`) comment style.
///
/// `<slot>` is captured non-greedily-from-the-right so slot names that
/// themselves contain colons (e.g. `app_debugger:pre_init`) are captured
/// whole rather than truncated at the first colon.
final _markerPattern = RegExp(
  r'^(\s*)(?://|#)\s*archipelago:(.+):(start|end)\s*$',
);

/// A single `archipelago:<slot>:start`/`:end` line found in a file.
@immutable
class const MarkerToken({
  /// The marker slot name (everything between `archipelago:` and the
  /// trailing `:start`/`:end`). May itself contain colons.
  required final String slot,

  /// Whether this token is the `:start` (true) or `:end` (false) half.
  required final bool isStart,

  /// Zero-based line index (after splitting the file content on `\n`).
  required final int lineIndex,

  /// Leading whitespace of the line the marker appears on, used to
  /// re-indent generated content inserted between a matching pair.
  required final String indent,
}) {
  /// Creates a new [MarkerToken].
  this;

  @override
  String toString() =>
      'MarkerToken(archipelago:$slot:${isStart ? 'start' : 'end'} '
      '@line ${lineIndex + 1})';
}

/// A balanced `archipelago:<slot>:start` … `:end` pair within one file.
@immutable
class const MarkerBlock({
  /// The marker slot name shared by both the start and end token.
  required final String slot,

  /// Zero-based line index of the `:start` token.
  required final int startLine,

  /// Zero-based line index of the `:end` token.
  required final int endLine,

  /// Leading whitespace of the `:start` line.
  required final String indent,
}) {
  /// Creates a new [MarkerBlock].
  this;

  /// The (possibly empty) inner lines strictly between the marker pair,
  /// excluding the marker lines themselves.
  List<String> innerLines(List<String> fileLines) =>
      fileLines.sublist(startLine + 1, endLine);

  @override
  String toString() => 'MarkerBlock(archipelago:$slot, $startLine-$endLine)';
}

/// Thrown when marker pairs in a file are unbalanced, nested, or
/// interleaved.
class const MarkerImbalanceException(
  /// A clear, actionable description of the violation, including the
  /// offending line number(s).
  final String message,
) implements Exception {
  /// Creates a new [MarkerImbalanceException] with a human-readable
  /// [message].
  this;

  @override
  String toString() => message;
}

/// Parses and rewrites `// archipelago:<slot>:start` / `:end` marker pairs
/// (the convention documented in
/// `template_base/.claude/skills/generator-markers/SKILL.md`).
///
/// Marker pairs in this codebase are always siblings within a file — never
/// nested. [scanBlocks] enforces that: a `:start` must be closed by its own
/// `:end` before any other slot's `:start` may open.
class const MarkerScanner._() {
  /// Finds every marker token (`:start` or `:end` line) in [content], in
  /// file order.
  static List<MarkerToken> scanTokens(String content) {
    final lines = content.split('\n');
    final tokens = <MarkerToken>[];

    for (var i = 0; i < lines.length; i++) {
      final match = _markerPattern.firstMatch(lines[i]);
      if (match == null) continue;

      tokens.add(
        MarkerToken(
          slot: match.group(2)!,
          isStart: match.group(3) == 'start',
          lineIndex: i,
          indent: match.group(1) ?? '',
        ),
      );
    }

    return tokens;
  }

  /// Pairs up marker tokens in [content] into balanced [MarkerBlock]s.
  ///
  /// Throws [MarkerImbalanceException] if:
  /// - a `:start` opens before the previously opened slot's `:end` closes
  ///   (nesting/interleaving of different slots),
  /// - a `:end` appears with no matching `:start`,
  /// - a `:end` closes a different slot than the one currently open,
  /// - a `:start` has no matching `:end` by end of file,
  /// - the same slot name has more than one `:start` in the same file.
  ///
  /// [sourceLabel] (typically a file path) is prefixed to error messages
  /// when provided, so a caller aggregating violations across many files
  /// can tell them apart.
  static List<MarkerBlock> scanBlocks(String content, {String? sourceLabel}) {
    final prefix = sourceLabel == null ? '' : '$sourceLabel: ';
    final tokens = scanTokens(content);
    final blocks = <MarkerBlock>[];
    final seenSlots = <String>{};
    MarkerToken? open;

    for (final token in tokens) {
      if (token.isStart) {
        if (open != null) {
          throw MarkerImbalanceException(
            '${prefix}marker "archipelago:${token.slot}:start" at line '
            '${token.lineIndex + 1} opens before "archipelago:${open.slot}'
            ':end" (opened at line ${open.lineIndex + 1}) closes. Marker '
            'pairs must not nest or interleave.',
          );
        }
        if (!seenSlots.add(token.slot)) {
          throw MarkerImbalanceException(
            '${prefix}marker slot "archipelago:${token.slot}" has more than '
            'one ":start" (duplicate at line ${token.lineIndex + 1}).',
          );
        }
        open = token;
        continue;
      }

      // isStart == false (an :end token).
      if (open == null) {
        throw MarkerImbalanceException(
          '${prefix}unmatched "archipelago:${token.slot}:end" at line '
          '${token.lineIndex + 1} — no preceding ":start".',
        );
      }
      if (open.slot != token.slot) {
        throw MarkerImbalanceException(
          '${prefix}marker "archipelago:${open.slot}:start" at line '
          '${open.lineIndex + 1} is closed by mismatched '
          '"archipelago:${token.slot}:end" at line ${token.lineIndex + 1}.',
        );
      }

      blocks.add(
        MarkerBlock(
          slot: open.slot,
          startLine: open.lineIndex,
          endLine: token.lineIndex,
          indent: open.indent,
        ),
      );
      open = null;
    }

    if (open != null) {
      throw MarkerImbalanceException(
        '${prefix}unmatched "archipelago:${open.slot}:start" at line '
        '${open.lineIndex + 1} — no matching ":end" found.',
      );
    }

    return blocks;
  }

  /// Replaces the content strictly between the `archipelago:<slot>:start`
  /// and `:end` markers in [content] with [lines].
  ///
  /// Each entry in [lines] is indented to match the `:start` marker's own
  /// indentation (empty lines are left as-is). The marker lines themselves
  /// are never modified. Regenerating with the same [lines] twice produces
  /// byte-identical output, which is what makes generators built on this
  /// idempotent.
  ///
  /// Throws [MarkerImbalanceException] if [content]'s markers are
  /// unbalanced, or if [slot] has no marker pair in [content].
  static String replaceBlock({
    required String content,
    required String slot,
    required List<String> lines,
    String? sourceLabel,
  }) {
    final blocks = scanBlocks(content, sourceLabel: sourceLabel);
    final matches = blocks.where((b) => b.slot == slot).toList();

    if (matches.isEmpty) {
      throw MarkerImbalanceException(
        'No "archipelago:$slot:start/end" marker pair found'
        '${sourceLabel == null ? '' : ' in $sourceLabel'}.',
      );
    }

    final block = matches.single;
    final fileLines = content.split('\n');
    final indented = lines
        .map((line) => line.isEmpty ? line : '${block.indent}$line')
        .toList();

    final rebuilt = [
      ...fileLines.sublist(0, block.startLine + 1),
      ...indented,
      ...fileLines.sublist(block.endLine),
    ];

    return rebuilt.join('\n');
  }
}
