import 'dart:convert';

import 'package:consent_api/consent_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A [ConsentStore] backed by `SharedPreferences`.
///
/// The record is stored as a single JSON document under one key so a decision
/// set is written atomically — a partial write that granted analytics but lost
/// the matching refusal of marketing would be worse than no record at all.
///
/// Note this is *not* encrypted storage. The record contains purposes,
/// booleans and timestamps — no personal data — so plain preferences are
/// appropriate. Do not extend it to hold user identifiers.
class const SharedPreferencesConsentStore(final SharedPreferences _preferences)
    implements ConsentStore {
  /// Creates a store over a resolved `SharedPreferences` instance.
  this;

  /// Preferences key holding the serialised [ConsentState].
  static const String storageKey = 'archipelago.consent.state.v1';

  @override
  Future<ConsentState?> read() async {
    final raw = _preferences.getString(storageKey);
    if (raw == null || raw.isEmpty) return null;

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return null;
    return ConsentState.fromJson(decoded);
  }

  @override
  Future<void> write(ConsentState state) async {
    await _preferences.setString(storageKey, jsonEncode(state.toJson()));
  }

  @override
  Future<void> clear() async {
    await _preferences.remove(storageKey);
  }
}
