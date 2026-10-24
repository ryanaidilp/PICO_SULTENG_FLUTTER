import 'package:push_notification_api/push_notification_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's quiet hours and recent deliveries per tier, which
/// the caps count.
class const NotificationPolicyStore() {
  /// Creates a store over `SharedPreferences`.
  this;

  /// Key holding `"<startMinute>-<endMinute>"`.
  static const String quietHoursKey = 'archipelago.push.quiet_hours.v1';

  /// Key holding the delivery times of [tier], ms since epoch.
  static String deliveriesKey(NotificationTier tier) =>
      'archipelago.push.deliveries.${tier.name}.v1';

  /// The stored quiet hours, or `null` when unset or unreadable.
  Future<QuietHours?> readQuietHours() async {
    final raw = (await SharedPreferences.getInstance()).getString(
      quietHoursKey,
    );
    final parts = raw?.split('-').map(int.tryParse).toList();
    if (parts == null || parts.length != 2) return null;
    final [start, end] = parts;
    if (start == null || end == null) return null;
    if (start < 0 || start >= 1440 || end < 0 || end >= 1440) return null;
    return QuietHours(startMinute: start, endMinute: end);
  }

  /// Stores [quietHours]; `null` clears them.
  Future<void> writeQuietHours(QuietHours? quietHours) async {
    final preferences = await SharedPreferences.getInstance();
    if (quietHours == null) {
      await preferences.remove(quietHoursKey);
    } else {
      await preferences.setString(
        quietHoursKey,
        '${quietHours.startMinute}-${quietHours.endMinute}',
      );
    }
  }

  /// Recent delivery times of [tier].
  Future<List<DateTime>> readDeliveries(NotificationTier tier) async {
    final raw =
        (await SharedPreferences.getInstance()).getStringList(
          deliveriesKey(tier),
        ) ??
        const [];
    return [
      for (final value in raw)
        if (int.tryParse(value) case final ms?)
          DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true),
    ];
  }

  /// Replaces the delivery times of [tier].
  Future<void> writeDeliveries(
    NotificationTier tier,
    List<DateTime> deliveries,
  ) async {
    await (await SharedPreferences.getInstance()).setStringList(
      deliveriesKey(tier),
      [for (final at in deliveries) '${at.millisecondsSinceEpoch}'],
    );
  }
}
