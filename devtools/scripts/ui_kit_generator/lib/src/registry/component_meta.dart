import 'package:meta/meta.dart';
import 'package:ui_kit_generator/src/registry/layer.dart';

/// Metadata for a UI Kit component.
@immutable
class const ComponentMeta({
  /// The component identifier in kebab-case.
  required final String name,

  /// The human-readable display name.
  required final String displayName,

  /// The atomic design layer.
  required final Layer layer,

  /// The relative path within the components directory.
  required final String path,

  /// The main source files for this component.
  required final List<String> files,

  /// A brief description.
  required final String description,

  /// Other components this component depends on.
  final List<String> dependencies = const [],

  /// Configuration/style files.
  final List<String> configFiles = const [],
}) {
  /// Creates a [ComponentMeta].
  this;

  /// Whether this component has implementation files.
  bool get hasImplementation => files.isNotEmpty;

  /// The full list of all files including config files.
  List<String> get allFiles => [...files, ...configFiles];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ComponentMeta &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => 'ComponentMeta($name)';
}
