import 'dart:convert';
import 'dart:io';

import 'package:shared_scripts/shared_scripts.dart';
import 'package:xml/xml.dart';

class const IosPermissionService() {
  Future<List<String>> extractPermissions(String ipaPath) async {
    final tempDir = Directory.systemTemp.createTempSync(
      'permission_guard_ipa_',
    );
    try {
      final result = await ShellRunner.run(
        'unzip -o "$ipaPath" -d "${tempDir.path}"',
      );
      if (result.exitCode != 0) {
        throw Exception(
          'unzip failed (exit ${result.exitCode}): ${result.stderr}',
        );
      }

      final permissions = <String>{};
      final payloadDir = Directory('${tempDir.path}/Payload');
      if (!payloadDir.existsSync()) return [];

      final plistFiles = payloadDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('Info.plist'));

      for (final plist in plistFiles) {
        // Check magic bytes before reading as string
        final bytes = plist.readAsBytesSync();
        final hasBplistMagic =
            bytes.length >= 6 &&
            bytes[0] == 0x62 && // 'b'
            bytes[1] == 0x70 && // 'p'
            bytes[2] == 0x6C && // 'l'
            bytes[3] == 0x69 && // 'i'
            bytes[4] == 0x73 && // 's'
            bytes[5] == 0x74; // 't'
        if (hasBplistMagic) continue;
        String content;
        try {
          content = utf8.decode(bytes);
        } catch (_) {
          continue; // not valid UTF-8, skip
        }
        try {
          final keys = extractUsageDescriptionKeys(content);
          permissions.addAll(keys);
        } catch (_) {
          // Skip malformed plists silently.
        }
      }

      return permissions.toList()..sort();
    } finally {
      tempDir.deleteSync(recursive: true);
    }
  }

  static List<String> extractUsageDescriptionKeys(String plistXml) {
    final doc = XmlDocument.parse(plistXml);
    final dict = doc.findAllElements('dict').firstOrNull;
    if (dict == null) return [];

    final children = dict.childElements.toList();
    final keys = <String>[];

    for (var i = 0; i + 1 < children.length; i += 2) {
      final keyElement = children[i];
      if (keyElement.name.local != 'key') continue;
      final keyName = keyElement.innerText;
      if (keyName.toLowerCase().contains('usagedescription')) {
        keys.add(keyName);
      }
    }

    return keys..sort();
  }
}
