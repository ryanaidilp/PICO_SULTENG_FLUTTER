import 'package:consent_api/consent_api.dart';
import 'package:feature_sdk/feature_sdk.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_notification_api/push_notification_api.dart';
import 'package:push_notification_impl/push_notification_impl.dart';

class _Store(final QuietHours? quietHours) extends NotificationPolicyStore {
  @override
  Future<QuietHours?> readQuietHours() async => quietHours;
}

class _Gate(final bool marketing) extends Fake implements ConsentGate {
  @override
  bool isGranted(ConsentPurpose purpose) =>
      purpose == ConsentPurpose.marketing && marketing;
}

/// The device's keys from `docs/specs/notification-policy/vectors.json`
/// case `untagged-missing-tier`; `digest` and `region` come from the server.
const _vectorPrefs = {
  'v': 1,
  'tz': 'Asia/Jakarta',
  'quiet_hours': {'start': '22:00', 'end': '07:00'},
  'marketing': false,
};

final _hhmm = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');

/// The contract v1 device record: exactly these keys and types.
void _expectContractShape(Map<String, Object?> json) {
  expect(json.keys.toSet(), {'v', 'tz', 'quiet_hours', 'marketing'});
  expect(json['v'], 1);
  expect(json['tz'], isA<String>().having((tz) => tz, 'tz', isNotEmpty));
  expect(json['marketing'], isA<bool>());
  final quietHours = json['quiet_hours'];
  if (quietHours == null) return;
  expect(quietHours, isA<Map<String, Object?>>());
  quietHours as Map<String, Object?>;
  expect(quietHours.keys.toSet(), {'start', 'end'});
  for (final value in quietHours.values) {
    expect(value, isA<String>().having(_hhmm.hasMatch, 'HH:MM', isTrue));
  }
}

void main() {
  tearDown(() {
    ConsentGateRegistry.instance.reset();
    FeatureSDKRegistry.instance.clear();
  });

  Future<NotificationPreferences> snapshot({
    QuietHours? quietHours,
    bool marketing = false,
    String zone = 'Asia/Jakarta',
  }) {
    ConsentGateRegistry.instance.install(_Gate(marketing));
    return PushNotificationSDKImpl.create(
      handlers: const [],
      store: _Store(quietHours),
      localTimezone: () async => zone,
    ).notificationPreferences();
  }

  test('matches the contract vector prefs for the device keys', () async {
    final prefs = await snapshot(
      quietHours: const QuietHours(startMinute: 22 * 60, endMinute: 7 * 60),
    );

    _expectContractShape(_vectorPrefs);
    _expectContractShape(prefs.toJson());
    expect(prefs.toJson(), _vectorPrefs);
  });

  test('no quiet hours is null; marketing reads the consent gate', () async {
    final json = (await snapshot(
      marketing: true,
      zone: 'America/New_York',
    )).toJson();

    _expectContractShape(json);
    expect(json, {
      'v': 1,
      'tz': 'America/New_York',
      'quiet_hours': null,
      'marketing': true,
    });
  });

  test('pads minutes at the day edges', () {
    const prefs = NotificationPreferences(
      timeZone: 'UTC',
      quietHours: QuietHours(startMinute: 0, endMinute: 1439),
      marketing: false,
    );

    expect(prefs.toJson()['quiet_hours'], {'start': '00:00', 'end': '23:59'});
  });

  test('with no gate installed marketing is false (fail closed)', () async {
    final prefs = await PushNotificationSDKImpl.create(
      handlers: const [],
      store: _Store(null),
      localTimezone: () async => 'UTC',
    ).notificationPreferences();

    expect(prefs.marketing, isFalse);
  });
}
