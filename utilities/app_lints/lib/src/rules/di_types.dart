import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

/// Whether [type] is [name], or extends or implements it.
///
/// With [package], the type must come from `package:<package>/`, so a
/// workspace class that happens to share a pub type's name never matches.
bool isOrExtends(DartType? type, String name, {String? package}) =>
    type is InterfaceType &&
    [type, ...type.allSupertypes].any((t) => _is(t.element, name, package));

bool _is(InterfaceElement element, String name, String? package) =>
    element.name == name &&
    (package == null ||
        element.library.uri.toString().startsWith('package:$package/'));

/// Whether [type] is get_it's `GetIt`, however the value was reached.
bool isGetIt(DartType? type) => isOrExtends(type, 'GetIt', package: 'get_it');

/// Whether [node] sits inside a class extending injectable's
/// `MicroPackageModule`.
bool inMicroPackageModule(AstNode node) {
  final type = node
      .thisOrAncestorOfType<ClassDeclaration>()
      ?.declaredFragment
      ?.element
      .thisType;
  return isOrExtends(type, 'MicroPackageModule', package: 'injectable');
}

/// Whether [path] is a DI file: anything under a package's `lib/src/di/`.
bool isDiFile(String path) =>
    path.replaceAll(r'\', '/').contains('/lib/src/di/');
