import 'package:network_sdk_api/network_sdk_api.dart';
import 'package:test/test.dart';

void main() {
  group('NetworkInjectorKey', () {
    test('exposes stable string keys', () {
      expect(NetworkInjectorKey.defaultClient, 'default');
      expect(NetworkInjectorKey.authClient, 'auth');
      expect(NetworkInjectorKey.cdnClient, 'cdn');
      expect(NetworkInjectorKey.analyticsClient, 'analytics');
    });

    test('allClientNames contains every defined key', () {
      expect(
        NetworkInjectorKey.allClientNames,
        containsAll([
          NetworkInjectorKey.defaultClient,
          NetworkInjectorKey.authClient,
          NetworkInjectorKey.cdnClient,
          NetworkInjectorKey.analyticsClient,
        ]),
      );
    });

    test('allClientNames has no duplicates', () {
      expect(
        NetworkInjectorKey.allClientNames.toSet(),
        hasLength(NetworkInjectorKey.allClientNames.length),
      );
    });
  });
}
