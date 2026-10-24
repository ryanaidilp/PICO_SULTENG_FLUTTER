/// Which `InjectableInit` list a declared DI module belongs in.
///
/// Corresponds 1:1 to `InjectableInit`'s `externalPackageModulesBefore`
/// (`before`) and `externalPackageModulesAfter` (`after`) parameters.
enum ModuleScope() {
  /// Registered via `externalPackageModulesBefore`. The default when a
  /// manifest entry omits `scope`.
  before,

  /// Registered via `externalPackageModulesAfter`.
  after;

  /// Parses the `scope:` YAML value (`'before'` or `'after'`).
  ///
  /// Returns [ModuleScope.before] when [value] is `null` (the documented
  /// default). Throws a [FormatException] for any other unrecognized value
  /// so a typo (e.g. `befor`) fails loudly instead of silently defaulting.
  static ModuleScope parse(String? value) {
    if (value == null) return ModuleScope.before;
    switch (value) {
      case 'before':
        return ModuleScope.before;
      case 'after':
        return ModuleScope.after;
      default:
        throw FormatException(
          'Invalid archipelago di_modules "scope" value: "$value". '
          'Expected "before" or "after".',
        );
    }
  }
}
