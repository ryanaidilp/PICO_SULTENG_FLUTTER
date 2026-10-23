import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pico/host/services/deeplink_service.dart';

// ---------------------------------------------------------------------------
// Test doubles — pure-Dart unit test without mockito/mocktail.
// ---------------------------------------------------------------------------

VoidCallback _stubMethodChannel(
  String channelName,
  Future<dynamic> Function(String method) handler,
) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        MethodChannel(channelName),
        (call) => handler(call.method),
      );
  return () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(MethodChannel(channelName), null);
}

Future<void> _sendEventChannelEvent(String channelName, dynamic event) async {
  const codec = StandardMethodCodec();
  final data = codec.encodeSuccessEnvelope(event);
  await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .handlePlatformMessage(channelName, data, (_) {});
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const initialChannelName = 'archipelago/deeplink/initial';
  const eventsChannelName = 'archipelago/deeplink/events';

  group('DeeplinkService.getInitialLink', () {
    late DeeplinkService service;
    late VoidCallback teardownMethod;

    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel(eventsChannelName),
            (_) async => null,
          );
      teardownMethod = () {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              const MethodChannel(eventsChannelName),
              null,
            );
      };
    });

    tearDown(() {
      teardownMethod();
      service.dispose();
    });

    test('returns parsed URI when channel returns a valid string', () async {
      _stubMethodChannel(
        initialChannelName,
        (method) async => 'myapp://home/profile?id=42',
      );

      service = DeeplinkService();
      final uri = await service.getInitialLink();

      expect(uri, isNotNull);
      expect(uri!.scheme, 'myapp');
      expect(uri.host, 'home');
      expect(uri.pathSegments, contains('profile'));
      expect(uri.queryParameters['id'], '42');
    });

    test('returns null when channel returns null', () async {
      _stubMethodChannel(initialChannelName, (method) async => null);

      service = DeeplinkService();
      final uri = await service.getInitialLink();

      expect(uri, isNull);
    });

    test('returns null when channel returns an invalid URI string', () async {
      _stubMethodChannel(initialChannelName, (method) async => ':::invalid:::');

      service = DeeplinkService();
      final uri = await service.getInitialLink();

      expect(uri, isNull);
    });
  });

  group('DeeplinkService.deeplinkStream', () {
    late DeeplinkService service;

    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel(initialChannelName),
            (_) async => null,
          );
    });

    tearDown(() {
      service.dispose();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel(initialChannelName),
            null,
          );
    });

    test('emits a parsed Uri when a valid string event arrives', () async {
      service = DeeplinkService();

      final future = service.deeplinkStream.first;

      await _sendEventChannelEvent(eventsChannelName, 'myapp://offers/123');

      final uri = await future;
      expect(uri.scheme, 'myapp');
      expect(uri.host, 'offers');
      expect(uri.pathSegments, contains('123'));
    });

    test('drops events that are not valid URIs', () async {
      service = DeeplinkService();

      await _sendEventChannelEvent(eventsChannelName, ':::not_a_uri:::');
      final validFuture = service.deeplinkStream.first;
      await _sendEventChannelEvent(eventsChannelName, 'myapp://valid');

      final uri = await validFuture;
      expect(uri.scheme, 'myapp');
    });
  });

  group('DeeplinkService.dispose', () {
    test('cancels event subscription without throwing', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel(initialChannelName),
            (_) async => null,
          );
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              const MethodChannel(initialChannelName),
              null,
            ),
      );

      final service = DeeplinkService();
      await expectLater(service.dispose(), completes);
    });
  });
}
