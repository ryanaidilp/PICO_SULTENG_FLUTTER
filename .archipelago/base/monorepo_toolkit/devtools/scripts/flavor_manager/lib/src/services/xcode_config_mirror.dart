/// Gives every native target of an Xcode project the build configurations
/// the project has (`Debug-development`, ...).
///
/// flutter_flavorizr adds the flavored configurations to the project and to
/// the `Runner` target only. A target added before it, such as Patrol's
/// `RunnerUITests`, keeps only `Debug`/`Release`/`Profile`, and
/// `patrol test --flavor` then fails with "No target application path
/// specified". Each missing configuration is a copy of the target's own
/// `Debug`, `Profile` or `Release` (by the name's first word), renamed.
/// Returns [pbxproj] unchanged when nothing is missing.
String mirrorProjectConfigsToTargets(String pbxproj) {
  final lists = RegExp(
    r'\t\t\w{24} /\* Build configuration list for (PBXProject|PBXNativeTarget) '
    r'"([^"]+)" \*/ = \{\n\t\t\tisa = XCConfigurationList;\n'
    r'\t\t\tbuildConfigurations = \(\n((?:\t\t\t\t\w{24} /\* [^*]+ \*/,\n)*)'
    r'\t\t\t\);',
  ).allMatches(pbxproj).toList();
  final entry = RegExp(r'\t\t\t\t(\w{24}) /\* ([^*]+) \*/,\n');
  Map<String, String> configs(RegExpMatch list) => {
    for (final e in entry.allMatches(list[3]!)) e[2]!: e[1]!,
  };

  final project = lists.where((l) => l[1] == 'PBXProject').firstOrNull;
  final end = pbxproj.indexOf('/* End XCBuildConfiguration section */');
  if (project == null || end < 0) return pbxproj;
  final names = configs(project).keys;

  final inserts = <(int, String)>[];
  final blocks = StringBuffer();
  var serial = 0;
  for (final list in lists.where((l) => l[1] == 'PBXNativeTarget')) {
    final own = configs(list);
    final refs = StringBuffer();
    for (final name in names.where((n) => !own.containsKey(n))) {
      final sourceId = own[name.split('-').first];
      if (sourceId == null) continue;
      final source = RegExp(
        '\\t\\t$sourceId /\\* [^*]+ \\*/ = \\{\\n.*?\\n\\t\\t\\};\\n',
        dotAll: true,
      ).firstMatch(pbxproj);
      if (source == null) continue;
      String id;
      do {
        id = 'F1A0C0DE${(serial++).toRadixString(16).padLeft(16, '0')}'
            .toUpperCase();
      } while (pbxproj.contains(id));
      blocks.write(
        source[0]!
            .replaceFirst(sourceId, id)
            .replaceFirst(RegExp(r'/\* [^*]+ \*/'), '/* $name */')
            .replaceFirst(
              RegExp(r'\t\t\tname = [^;]+;\n\t\t\};\n$'),
              '\t\t\tname = "$name";\n\t\t};\n',
            ),
      );
      refs.write('\t\t\t\t$id /* $name */,\n');
    }
    if (refs.isNotEmpty) {
      inserts.add((list.end - '\t\t\t);'.length, refs.toString()));
    }
  }
  if (blocks.isEmpty) return pbxproj;
  inserts.add((end, blocks.toString()));

  var out = pbxproj;
  for (final (at, text) in inserts..sort((a, b) => b.$1.compareTo(a.$1))) {
    out = out.replaceRange(at, at, text);
  }
  return out;
}
