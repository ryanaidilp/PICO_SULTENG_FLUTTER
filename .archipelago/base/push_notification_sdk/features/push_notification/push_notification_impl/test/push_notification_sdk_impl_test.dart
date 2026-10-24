import 'dart:async';

import 'package:feature_sdk/feature_sdk.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:push_notification_api/push_notification_api.dart';
import 'package:push_notification_impl/src/push_notification_sdk_impl.dart';

class _MockFcmHandler()
    extends Mock
    implements PushNotificationProviderHandler {
  @override
  PushNotificationProvider get provider => PushNotificationProvider.fcm;
}

class _MockOneSignalHandler()
    extends Mock
    implements PushNotificationProviderHandler {
  @override
  PushNotificationProvider get provider => PushNotificationProvider.oneSignal;
}

PushNotification _notification({String id = 'msg-1'}) =>
    PushNotification(id: id, receivedAt: DateTime.utc(2026, 2, 3));

void main() {
  late _MockFcmHandler fcmHandler;

  setUp(() {
    fcmHandler = _MockFcmHandler();
    FeatureSDKRegistry.instance.clear();
  });

  PushNotificationSDKImpl makeImpl({
    List<PushNotificationProviderHandler>? handlers,
  }) => PushNotificationSDKImpl.create(handlers: handlers ?? [fcmHandler]);

  group('availableProviders', () {
    test('reflects registered handlers', () {
      final impl = makeImpl();
      expect(impl.availableProviders, {PushNotificationProvider.fcm});
    });

    test('is empty when no handlers are registered', () {
      final impl = makeImpl(handlers: []);
      expect(impl.availableProviders, isEmpty);
    });

    test('reflects multiple handlers', () {
      final oneSignalHandler = _MockOneSignalHandler();
      final impl = makeImpl(handlers: [fcmHandler, oneSignalHandler]);
      expect(
        impl.availableProviders,
        containsAll([
          PushNotificationProvider.fcm,
          PushNotificationProvider.oneSignal,
        ]),
      );
    });
  });

  group('requestPermission', () {
    test('delegates to first handler', () async {
      when(() => fcmHandler.requestPermission())
          .thenAnswer((_) async => PushNotificationPermission.granted);

      final impl = makeImpl();
      final result = await impl.requestPermission();

      expect(result, PushNotificationPermission.granted);
      verify(() => fcmHandler.requestPermission()).called(1);
    });

    test('returns notDetermined when no handler is registered', () async {
      final impl = makeImpl(handlers: []);
      final result = await impl.requestPermission();
      expect(result, PushNotificationPermission.notDetermined);
    });
  });

  group('getPermissionStatus', () {
    test('delegates to first handler', () async {
      when(() => fcmHandler.getPermissionStatus())
          .thenAnswer((_) async => PushNotificationPermission.denied);

      final impl = makeImpl();
      final result = await impl.getPermissionStatus();

      expect(result, PushNotificationPermission.denied);
    });

    test('returns notDetermined when no handler registered', () async {
      final impl = makeImpl(handlers: []);
      expect(
        await impl.getPermissionStatus(),
        PushNotificationPermission.notDetermined,
      );
    });
  });

  group('getToken', () {
    test('delegates to first handler', () async {
      final token = PushToken(
        provider: PushNotificationProvider.fcm,
        token: 'tok-xyz',
        updatedAt: DateTime.utc(2026, 2, 3),
      );
      when(() => fcmHandler.getToken()).thenAnswer((_) async => token);

      final impl = makeImpl();
      final result = await impl.getToken();

      expect(result, token);
    });

    test('returns null when no handler registered', () async {
      final impl = makeImpl(handlers: []);
      expect(await impl.getToken(), isNull);
    });
  });

  group('subscribeToTopic / unsubscribeFromTopic', () {
    test('delegates to first handler', () async {
      when(() => fcmHandler.subscribeToTopic('news')).thenAnswer((_) async {});
      when(() => fcmHandler.unsubscribeFromTopic('news'))
          .thenAnswer((_) async {});

      final impl = makeImpl();
      await impl.subscribeToTopic('news');
      await impl.unsubscribeFromTopic('news');

      verify(() => fcmHandler.subscribeToTopic('news')).called(1);
      verify(() => fcmHandler.unsubscribeFromTopic('news')).called(1);
    });

    test('is a no-op when no handler registered', () async {
      final impl = makeImpl(handlers: []);
      // Must not throw.
      await expectLater(impl.subscribeToTopic('news'), completes);
      await expectLater(impl.unsubscribeFromTopic('news'), completes);
    });
  });

  group('foregroundStream', () {
    test('forwards events from the handler stream', () async {
      final controller = StreamController<PushNotification>.broadcast();
      when(() => fcmHandler.foregroundStream)
          .thenAnswer((_) => controller.stream);

      final impl = makeImpl();
      final events = <PushNotification>[];
      final sub = impl.foregroundStream.listen(events.add);

      final notification = _notification();
      controller.add(notification);
      await Future<void>.delayed(Duration.zero);

      expect(events, [notification]);
      await sub.cancel();
      await controller.close();
    });

    test('emits nothing when no handler registered', () async {
      final impl = makeImpl(handlers: []);
      expect(impl.foregroundStream, emitsDone);
    });

    test('merges events from all registered handlers', () async {
      final h1Controller = StreamController<PushNotification>.broadcast();
      final h2Controller = StreamController<PushNotification>.broadcast();
      final oneSignalHandler = _MockOneSignalHandler();
      when(() => fcmHandler.foregroundStream)
          .thenAnswer((_) => h1Controller.stream);
      when(() => oneSignalHandler.foregroundStream)
          .thenAnswer((_) => h2Controller.stream);

      final impl = makeImpl(handlers: [fcmHandler, oneSignalHandler]);
      final received = <PushNotification>[];
      final sub = impl.foregroundStream.listen(received.add);

      h1Controller.add(_notification(id: 'n1'));
      h2Controller.add(_notification(id: 'n2'));
      await Future<void>.delayed(Duration.zero);

      expect(received.map((e) => e.id), containsAll(['n1', 'n2']));

      await sub.cancel();
      await h1Controller.close();
      await h2Controller.close();
    });
  });

  group('tapStream', () {
    test('forwards tap events from the handler stream', () async {
      final controller = StreamController<PushNotification>.broadcast();
      when(() => fcmHandler.tapStream).thenAnswer((_) => controller.stream);

      final impl = makeImpl();
      final taps = <PushNotification>[];
      final sub = impl.tapStream.listen(taps.add);

      final notification = _notification(id: 'tap-1');
      controller.add(notification);
      await Future<void>.delayed(Duration.zero);

      expect(taps, [notification]);
      await sub.cancel();
      await controller.close();
    });

    test('emits nothing when no handler registered', () async {
      final impl = makeImpl(handlers: []);
      expect(impl.tapStream, emitsDone);
    });

    test('merges tap events from all registered handlers', () async {
      final h1Controller = StreamController<PushNotification>.broadcast();
      final h2Controller = StreamController<PushNotification>.broadcast();
      final oneSignalHandler = _MockOneSignalHandler();
      when(() => fcmHandler.tapStream).thenAnswer((_) => h1Controller.stream);
      when(() => oneSignalHandler.tapStream)
          .thenAnswer((_) => h2Controller.stream);

      final impl = makeImpl(handlers: [fcmHandler, oneSignalHandler]);
      final received = <PushNotification>[];
      final sub = impl.tapStream.listen(received.add);

      h1Controller.add(_notification(id: 't1'));
      h2Controller.add(_notification(id: 't2'));
      await Future<void>.delayed(Duration.zero);

      expect(received.map((e) => e.id), containsAll(['t1', 't2']));

      await sub.cancel();
      await h1Controller.close();
      await h2Controller.close();
    });
  });

  group('clearAll', () {
    test('calls clearAll on all handlers', () async {
      final oneSignalHandler = _MockOneSignalHandler();
      when(() => fcmHandler.clearAll()).thenAnswer((_) async {});
      when(oneSignalHandler.clearAll).thenAnswer((_) async {});

      final impl = makeImpl(handlers: [fcmHandler, oneSignalHandler]);
      await impl.clearAll();

      verify(() => fcmHandler.clearAll()).called(1);
      verify(oneSignalHandler.clearAll).called(1);
    });

    test('swallows per-handler errors so all handlers are attempted', () async {
      final oneSignalHandler = _MockOneSignalHandler();
      when(() => fcmHandler.clearAll()).thenThrow(Exception('fcm error'));
      when(oneSignalHandler.clearAll).thenAnswer((_) async {});

      final impl = makeImpl(handlers: [fcmHandler, oneSignalHandler]);

      // Must not throw.
      await expectLater(impl.clearAll(), completes);
      verify(oneSignalHandler.clearAll).called(1);
    });
  });

  group('FeatureSDK lifecycle', () {
    test('isEnabled is true', () {
      expect(makeImpl().isEnabled, isTrue);
    });

    test('initialize completes without error', () async {
      await expectLater(makeImpl().initialize(), completes);
    });

    test('dispose completes without error', () async {
      await expectLater(makeImpl().dispose(), completes);
    });
  });
}
