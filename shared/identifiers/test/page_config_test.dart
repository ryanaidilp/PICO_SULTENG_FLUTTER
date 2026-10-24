import 'package:identifiers/identifiers.dart';
import 'package:test/test.dart';

void main() {
  group('PageConfig', () {
    test('defaults requiresAuth=false and tags=[]', () {
      const config = PageConfig(deeplinkPath: '/home');
      expect(config.deeplinkPath, '/home');
      expect(config.requiresAuth, isFalse);
      expect(config.analyticsName, isNull);
      expect(config.tags, isEmpty);
    });

    test('preserves all fields', () {
      const config = PageConfig(
        deeplinkPath: '/assignment/:id',
        requiresAuth: true,
        analyticsName: 'assignment_detail',
        tags: ['experimental'],
      );
      expect(config.deeplinkPath, '/assignment/:id');
      expect(config.requiresAuth, isTrue);
      expect(config.analyticsName, 'assignment_detail');
      expect(config.tags, ['experimental']);
    });
  });
}
