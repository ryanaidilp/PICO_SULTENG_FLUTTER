import 'package:network_sdk_api/network_sdk_api.dart';
import 'package:test/test.dart';

void main() {
  final registry = NetworkInterceptorRegistry.instance;
  setUp(registry.clear);
  tearDown(registry.clear);

  test('listen replays earlier registrations', () {
    final seen = <Object>[];
    registry.register('a');
    registry.listen(seen.add);
    expect(seen, ['a']);
  });

  test('listen receives later registrations', () {
    final seen = <Object>[];
    registry.listen(seen.add);
    registry.register('b');
    expect(seen, ['b']);
  });
}
