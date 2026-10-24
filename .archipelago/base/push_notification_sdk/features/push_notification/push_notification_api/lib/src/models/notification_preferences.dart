import 'package:dependencies_core/equality.dart';
import 'package:push_notification_api/src/policy/notification_policy.dart';

/// The device's part of the server preferences record (ADR-041, contract
/// "Server engine v1"). Send [toJson] to your own backend, which adds
/// `digest` and `region` from its own data.
class const NotificationPreferences({
  /// IANA time zone, for example `Asia/Jakarta`.
  required final String timeZone,

  /// The user's quiet hours in [timeZone], or `null` when none are set.
  required final QuietHours? quietHours,

  /// Marketing consent (`ConsentPurpose.marketing`).
  required final bool marketing,
}) extends Equatable {
  /// Creates a snapshot.
  this;

  /// Record version.
  static const int version = 1;

  /// `{"v": 1, "tz": ..., "quiet_hours": null | {"start": "HH:MM",
  /// "end": "HH:MM"}, "marketing": ...}`.
  Map<String, Object?> toJson() => {
    'v': version,
    'tz': timeZone,
    'quiet_hours': switch (quietHours) {
      null => null,
      final window => {
        'start': _hhmm(window.startMinute),
        'end': _hhmm(window.endMinute),
      },
    },
    'marketing': marketing,
  };

  static String _hhmm(int minute) =>
      '${(minute ~/ 60).toString().padLeft(2, '0')}:'
      '${(minute % 60).toString().padLeft(2, '0')}';

  @override
  List<Object?> get props => [timeZone, quietHours, marketing];
}
