import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:shared_scripts/src/models/package_info.dart';

/// A single `package:` import found while scanning a package's source.
class const ImportReference({
  /// Name of the imported package (e.g. `home_impl` for
  /// `package:home_impl/home_impl.dart`).
  required final String importedPackage,

  /// Absolute path of the file containing the import.
  required final String filePath,

  /// 1-based line number of the import statement.
  required final int line,
}) {
  /// Creates a new [ImportReference].
  this;

  @override
  String toString() => '$filePath:$line -> package:$importedPackage';
}

/// Scans a package's `lib/` source for `package:` import statements.
///
/// Unlike [PackageInfo.dependencies] (which reflects only what is
/// *declared* in `pubspec.yaml`), this reflects what packages are
/// *actually imported* in code. The two can diverge: this workspace uses
/// Dart's `resolution: workspace` pub mode, under which any package can
/// `import` any other workspace package's public API without declaring it
/// as a `pubspec.yaml` dependency at all — `dart pub get`/`dart pub
/// upgrade` resolve it fine regardless, since every workspace package
/// shares one resolved `package_config.json`. A pubspec-dependency-only
/// check therefore cannot catch every real boundary violation; this
/// scanner closes that gap by looking at the actual `import` directives.
///
/// This intentionally uses lightweight regex-based line scanning rather
/// than a full `package:analyzer` AST parse, to keep this devtools script
/// dependency-light and fast. It mirrors the scope of the
/// `utilities/app_lints` analyzer plugin rules: only `package:` imports
/// (not relative/`dart:` imports) inside a package's `lib/` directory are
/// considered, since that is what the plugin rules themselves inspect.
class ImportScanner() {
  /// Matches a top-level `import 'package:name/...';` or
  /// `import "package:name/...";` directive and captures the package name.
  /// Deliberately does not match `export`/`part` directives — only
  /// `import` affects the layering rules being enforced.
  static final RegExp _importPattern = RegExp(
    r'''^\s*import\s+['"]package:([a-zA-Z0-9_]+)/''',
  );

  /// File suffixes for generated code, excluded from scanning.
  ///
  /// Mirrors the `analyzer: exclude:` patterns in the root
  /// `analysis_options.yaml` — generated files are not hand-authored and
  /// commonly import many packages for codegen wiring (e.g. an
  /// `injector.module.dart` in an app package), which is expected there.
  static const _generatedSuffixes = [
    '.freezed.dart',
    '.config.dart',
    '.module.dart',
    '.gr.dart',
    '.gm.dart',
    '.g.dart',
  ];

  /// Scans every non-generated `.dart` file under `<packagePath>/lib/`
  /// and returns each `package:` import found, in file-then-line order.
  ///
  /// Returns an empty list if the package has no `lib/` directory.
  static List<ImportReference> scanPackageImports(String packagePath) {
    final libDir = Directory(p.join(packagePath, 'lib'));
    if (!libDir.existsSync()) return const [];

    final references = <ImportReference>[];

    final dartFiles =
        libDir
            .listSync(recursive: true, followLinks: false)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))
            .where((f) => !_isGenerated(f.path))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));

    for (final file in dartFiles) {
      references.addAll(_scanFile(file));
    }

    return references;
  }

  /// Convenience wrapper returning just the set of distinct imported
  /// package names (loses file/line detail from [scanPackageImports]).
  static Set<String> scanPackageImportNames(String packagePath) =>
      scanPackageImports(packagePath).map((r) => r.importedPackage).toSet();

  static bool _isGenerated(String filePath) =>
      _generatedSuffixes.any(filePath.endsWith);

  static List<ImportReference> _scanFile(File file) {
    final references = <ImportReference>[];

    List<String> lines;
    try {
      lines = file.readAsLinesSync();
    } on Exception {
      // Skip unreadable (e.g. binary/invalid-encoding) files rather than
      // failing the whole scan.
      return references;
    }

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trimLeft();

      // Skip commented-out imports.
      if (trimmed.startsWith('//')) continue;

      final match = _importPattern.firstMatch(line);
      if (match == null) continue;

      references.add(
        ImportReference(
          importedPackage: match.group(1)!,
          filePath: file.path,
          line: i + 1,
        ),
      );
    }

    return references;
  }
}
