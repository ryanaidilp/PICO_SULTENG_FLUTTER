import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_data_impl/src/api/dates.dart';

/// Contact type table from C04: id to kind and URI prefix.
const Map<int, (ContactKind, String?)> _types = {
  1: (ContactKind.email, 'mailto:'),
  2: (ContactKind.phone, 'tel:'),
  3: (ContactKind.fax, null),
  4: (ContactKind.web, 'https://'),
  5: (ContactKind.whatsapp, 'https://api.whatsapp.com/send?phone='),
  6: (ContactKind.telegram, 'https://t.me/'),
  7: (ContactKind.twitter, 'https://twitter.com/'),
  8: (ContactKind.instagram, 'https://instagram.com/'),
  9: (ContactKind.line, 'https://line.me/R/ti/p/'),
};

/// Builds a [Contact] from a type id, its label and the raw value.
///
/// The link is `prefix + value`. Fax has no link. A website value that is
/// already a full URL is kept as is. A value that does not parse gives a null
/// link. Returns null for a blank value.
Contact? contactFrom(int typeId, String? label, Object? raw) {
  final value = cleanString(raw);
  if (value == null) return null;
  final (kind, prefix) = _types[typeId] ?? (ContactKind.web, null);
  Uri? uri;
  if (prefix != null) {
    var v = value;
    if (kind == ContactKind.phone || kind == ContactKind.whatsapp) {
      v = v.replaceAll(RegExp(r'[\s\-()]'), '');
    }
    if (kind == ContactKind.web && RegExp('^https?://').hasMatch(v)) {
      uri = Uri.tryParse(v);
    } else {
      if (const {
        ContactKind.telegram,
        ContactKind.twitter,
        ContactKind.instagram,
      }.contains(kind)) {
        v = v.replaceFirst(RegExp('^@'), '');
      }
      uri = Uri.tryParse('$prefix$v');
    }
  }
  return Contact(kind: kind, label: label ?? kind.name, value: value, uri: uri);
}

/// Nested contact `{contact_type: {id, name}, contact}` (content endpoints).
Contact? contactFromNested(Map<String, dynamic> j) {
  final t = j['contact_type'] as Map<String, dynamic>?;
  return contactFrom(
    (t?['id'] as num?)?.toInt() ?? 0,
    t?['name'] as String?,
    j['contact'],
  );
}

/// Flat contact `{contact_type_id, contact_type_name, contact}` (hospitals,
/// task forces).
Contact? contactFromFlat(Map<String, dynamic> j) => contactFrom(
  (j['contact_type_id'] as num?)?.toInt() ?? 0,
  j['contact_type_name'] as String?,
  j['contact'],
);

/// Maps a list of contacts with either shape, dropping blanks.
List<Contact> contactList(Object? rows) => [
  for (final r
      in (rows as List<dynamic>? ?? const []).cast<Map<String, dynamic>>())
    ?(r.containsKey('contact_type')
        ? contactFromNested(r)
        : contactFromFlat(r)),
];
