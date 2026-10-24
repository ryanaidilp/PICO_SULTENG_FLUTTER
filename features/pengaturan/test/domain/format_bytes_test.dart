import 'package:flutter_test/flutter_test.dart';
import 'package:pengaturan/src/domain/format_bytes.dart';

void main() {
  test('sizes read 0 B, B, KB, MB with the locale decimal mark', () {
    expect(formatBytes(0, comma: true), '0 B');
    expect(formatBytes(512, comma: true), '512 B');
    expect(formatBytes(12700000, comma: true), '12,1 MB');
    expect(formatBytes(12700000, comma: false), '12.1 MB');
    expect(formatBytes(1536, comma: false), '1.5 KB');
  });
}
