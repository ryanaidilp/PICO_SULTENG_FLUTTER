import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/file_system/file_system.dart';

/// Monorepo layers, lowest first. Dependencies may only flow downward.
enum Layer() {
  /// `shared/` and `utilities/`.
  shared,

  /// `packages/`.
  packages,

  /// `infrastructure/`.
  infrastructure,

  /// `features/`.
  features,

  /// `apps/`.
  apps,
}

/// The layer of the file at [path] in the workspace rooted at [root].
///
/// Decided by the top-level folder the file sits in, never by package name,
/// so renamed packages classify correctly. Null for anything outside the
/// workspace (pub cache, SDK) or outside the layer folders (`devtools/`,
/// `third_party/`): those are not part of the dependency flow.
Layer? layerOf(String path, String root) {
  final file = path.replaceAll(r'\', '/');
  final prefix = '${root.replaceAll(r'\', '/')}/';
  if (!file.startsWith(prefix)) return null;
  return switch (file.substring(prefix.length).split('/').first) {
    'shared' || 'utilities' => Layer.shared,
    'packages' => Layer.packages,
    'infrastructure' => Layer.infrastructure,
    'features' => Layer.features,
    'apps' => Layer.apps,
    _ => null,
  };
}

final _workspaceKey = RegExp('^workspace:', multiLine: true);

/// The nearest folder above [folder] whose `pubspec.yaml` declares
/// `workspace:`, or null when the package is not in a pub workspace.
String? workspaceRootOf(Folder folder) {
  for (var dir = folder; ; dir = dir.parent) {
    final pubspec = dir.getFile('pubspec.yaml');
    if (pubspec.exists && _workspaceKey.hasMatch(pubspec.readAsStringSync())) {
      return dir.path;
    }
    if (dir.isRoot) return null;
  }
}

/// Where a library sits: its workspace root, layer and package name.
typedef Location = ({String root, Layer layer, String package});

/// Where the library under analysis sits, or null outside a workspace layer.
Location? currentLocation(RuleContext context) {
  final uri = context.libraryElement?.uri;
  if (uri == null || !uri.isScheme('package')) return null;
  final file = context.definingUnit.file;
  final root = workspaceRootOf(file.parent);
  if (root == null) return null;
  final layer = layerOf(file.path, root);
  if (layer == null) return null;
  return (root: root, layer: layer, package: uri.pathSegments.first);
}

/// The package name and layer of a resolved `package:` import.
///
/// The layer comes from the file the import resolves to, and is null for pub
/// and SDK packages. Returns null for other imports and for imports that do
/// not resolve: the analyzer already reports those.
({String package, Layer? layer})? importedPackage(
  ImportDirective node,
  String root,
) {
  final uri = Uri.tryParse(node.uri.stringValue ?? '');
  if (uri == null || !uri.isScheme('package')) return null;
  final path =
      node.libraryImport?.importedLibrary?.firstFragment.source.fullName;
  if (path == null) return null;
  return (package: uri.pathSegments.first, layer: layerOf(path, root));
}
