class const NewLibraryConfig({
  final String? baseBranch,
  final bool failOnNew = false,
  final List<String> ignoredPackages = const ['flutter', 'dart'],
}) {
  factory fromYaml(Map<dynamic, dynamic> yaml) => NewLibraryConfig(
    baseBranch: yaml['base_branch'] as String?,
    failOnNew: (yaml['fail_on_new'] as bool?) ?? false,
    ignoredPackages:
        (yaml['ignored_packages'] as List?)?.map((e) => e as String).toList() ??
        const ['flutter', 'dart'],
  );
}
