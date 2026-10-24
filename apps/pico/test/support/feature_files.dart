import 'dart:io';

/// Files under the monorepo's `features/` whose path ends with [suffix].
///
/// `features/` is found by walking up from the test's working directory;
/// with none (no feature generated yet) there are no files. Build output is
/// skipped: a Flutter build can leave plugin example packages in `build/`.
Iterable<File> featureFiles(String suffix) {
  var dir = Directory.current.absolute;
  while (!Directory('${dir.path}/features').existsSync()) {
    if (dir.parent.path == dir.path) return const [];
    dir = dir.parent;
  }
  return Directory('${dir.path}/features')
      .listSync(recursive: true)
      .whereType<File>()
      .where(
        (file) =>
            file.path.endsWith(suffix) &&
            !file.path.contains('/build/') &&
            !file.path.contains('/.dart_tool/'),
      );
}
