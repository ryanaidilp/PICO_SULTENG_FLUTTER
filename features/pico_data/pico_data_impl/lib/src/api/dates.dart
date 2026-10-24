/// Parses an API date to a local calendar date (C01): only the first 10
/// characters (`YYYY-MM-DD`) count, so `2021-07-15T16:53:00+07:00` is
/// 2021-07-15.
DateTime parseApiDate(String raw) {
  final d = raw.substring(0, 10).split('-');
  return DateTime(int.parse(d[0]), int.parse(d[1]), int.parse(d[2]));
}

/// Formats a date for a query parameter: plain `YYYY-MM-DD`, never a datetime.
String formatApiDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// `"NULL"` and blank strings are null (C04 quirk); other values are trimmed.
String? cleanString(Object? v) {
  if (v == null) return null;
  final s = '$v'.trim();
  return s.isEmpty || s == 'NULL' ? null : s;
}
