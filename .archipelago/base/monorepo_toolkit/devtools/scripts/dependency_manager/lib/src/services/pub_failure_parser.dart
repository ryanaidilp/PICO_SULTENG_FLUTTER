/// One package that several dependents constrain differently:
/// constraint -> who asked for it.
class PubConflict({
  required final String package,
  required final Map<String, Set<String>> requirements,
}) {
  /// Creates a conflict.
  this;
}

const _constraint = r'(?:any|[\^<>=]*\d[^\s,]*(?: <[^\s,]+)?)';
// "[every version of] a [>=1.0.0 <2.0.0] [from sdk] depends on b ^1.0.0"
final _depends = RegExp(
  r'([a-z][a-z0-9_]*)(?: from \w+)?(?: (?:any|[\^<>=]+\S*|\d\S*))*'
  ' depends on ([a-z][a-z0-9_]*) ($_constraint)',
);

/// Reads the dependents and constraints out of a `pub get` version-solving
/// failure and returns the packages asked for with more than one constraint.
///
/// Pub's wording varies (direct and transitive conflicts, SDK constraints),
/// so only the stable "X depends on Y C" clause is parsed. Failures without
/// such a pair, such as a null-safety or SDK mismatch, return an empty list.
List<PubConflict> parsePubFailure(String output) {
  final text = output.replaceAll(RegExp(r'\s+'), ' ');
  final byPackage = <String, Map<String, Set<String>>>{};
  for (final m in _depends.allMatches(text)) {
    final constraint = m.group(3)!.replaceFirst(RegExp(r'\.$'), '');
    byPackage
        .putIfAbsent(m.group(2)!, () => {})
        .putIfAbsent(constraint, () => {})
        .add(m.group(1)!);
  }
  return [
    for (final e in byPackage.entries)
      if (e.value.length > 1)
        PubConflict(package: e.key, requirements: e.value),
  ];
}
