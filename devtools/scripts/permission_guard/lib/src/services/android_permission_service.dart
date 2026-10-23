import 'package:shared_scripts/shared_scripts.dart';

class const AndroidPermissionService() {
  Future<List<String>> extractPermissions(String apkPath) async {
    final result = await ShellRunner.run(
      'apkanalyzer manifest permissions $apkPath',
    );
    if (result.exitCode != 0) {
      throw Exception(
        'apkanalyzer failed (exit ${result.exitCode}): ${result.stderr}',
      );
    }
    final lines =
        result.stdout
            .toString()
            .split('\n')
            .map((l) => l.trim())
            .where((l) => l.isNotEmpty)
            .toList()
          ..sort();
    return lines;
  }
}
