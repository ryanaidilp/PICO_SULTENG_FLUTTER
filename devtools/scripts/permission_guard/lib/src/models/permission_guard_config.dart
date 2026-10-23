class const PermissionGuardConfig({
  final bool failOnNew = true,
  final bool warnOnRemoved = false,
  final String androidBaselinePath = 'permission_baseline/android.txt',
  final String iosBaselinePath = 'permission_baseline/ios.txt',
}) {
  factory fromYaml(Map<dynamic, dynamic> yaml) => PermissionGuardConfig(
    failOnNew: (yaml['fail_on_new'] as bool?) ?? true,
    warnOnRemoved: (yaml['warn_on_removed'] as bool?) ?? false,
    androidBaselinePath:
        (yaml['android_baseline_path'] as String?) ??
        'permission_baseline/android.txt',
    iosBaselinePath:
        (yaml['ios_baseline_path'] as String?) ?? 'permission_baseline/ios.txt',
  );
}
