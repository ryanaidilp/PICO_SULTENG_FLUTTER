import 'package:identifiers/identifiers.dart';
import 'package:test/test.dart';

enum _TestPage(@override final PageConfig config) implements PageIdentifier {
  home(PageConfig(deeplinkPath: '/home')),
  profile(PageConfig(deeplinkPath: '/profile', requiresAuth: true));

  @override
  String get name => toString().split('.').last;
}

enum _OtherPage(@override final PageConfig config) implements PageIdentifier {
  settings(PageConfig(deeplinkPath: '/settings'));

  @override
  String get name => toString().split('.').last;
}

void main() {
  group('PageIdentifierRegistry', () {
    late PageIdentifierRegistry registry;

    setUp(() => registry = PageIdentifierRegistry());

    test('starts empty', () {
      expect(registry.all, isEmpty);
    });

    test('register adds identifiers', () {
      registry.register(_TestPage.values);
      expect(registry.all, hasLength(2));
    });

    test('register from multiple features aggregates', () {
      registry
        ..register(_TestPage.values)
        ..register(_OtherPage.values);
      expect(registry.all, hasLength(3));
    });

    test('register is idempotent on duplicate names', () {
      registry
        ..register(_TestPage.values)
        ..register(_TestPage.values);
      expect(registry.all, hasLength(2));
    });

    test('findByName returns identifier or null', () {
      registry.register(_TestPage.values);
      expect(registry.findByName('home'), _TestPage.home);
      expect(registry.findByName('missing'), isNull);
    });

    test('findByDeeplinkPath returns identifier or null', () {
      registry.register(_TestPage.values);
      expect(registry.findByDeeplinkPath('/profile'), _TestPage.profile);
      expect(registry.findByDeeplinkPath('/nope'), isNull);
    });

    test('all is unmodifiable', () {
      registry.register(_TestPage.values);
      expect(
        () => registry.all.add(_OtherPage.settings),
        throwsUnsupportedError,
      );
    });

    test('clear empties the registry', () {
      registry
        ..register(_TestPage.values)
        ..clear();
      expect(registry.all, isEmpty);
    });
  });
}
