import 'dart:convert';

import 'package:consent_api/consent_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A [ScopedConsentStore] backed by `SharedPreferences`.
///
/// All decisions are one JSON list under one key, so a write is atomic. It is
/// independent of the [ConsentState] record. Like that store it is not
/// encrypted: it holds subjects, scope keys, booleans and timestamps only.
class const SharedPreferencesScopedConsentStore(
  final SharedPreferences _preferences,
) implements ScopedConsentStore {
  /// Creates a store over a resolved `SharedPreferences` instance.
  this;

  /// Preferences key holding the serialised decision list.
  static const String storageKey = 'archipelago.consent.scoped.v1';

  @override
  Future<List<ScopedConsentDecision>> read() async {
    final raw = _preferences.getString(storageKey);
    if (raw == null || raw.isEmpty) return const [];

    final decoded = jsonDecode(raw);
    if (decoded is! List<dynamic>) return const [];
    // Unusable entries are dropped, which reads as "not granted".
    return [
      for (final entry in decoded)
        if (entry is Map<String, dynamic>)
          ?ScopedConsentDecision.fromJson(entry),
    ];
  }

  @override
  Future<void> write(List<ScopedConsentDecision> all) async {
    await _preferences.setString(
      storageKey,
      jsonEncode([for (final d in all) d.toJson()]),
    );
  }

  @override
  Future<void> clear() async {
    await _preferences.remove(storageKey);
  }
}
