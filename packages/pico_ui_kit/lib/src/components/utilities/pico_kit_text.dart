import 'package:flutter/widgets.dart';
import 'package:pico_ui_kit/src/foundations/colors/pico_brand_palette.dart';

/// Kit-owned strings and number and date formats in Bahasa Indonesia (default)
/// and English. The language comes from the app's `Localizations`, so it
/// follows `locale_core` once the app wires `MaterialApp.locale`.
///
/// Numbers use locale grouping (`64.718` id, `64,718` en) and dates use short
/// month names (`14 Jan 2024`, `Jan 14, 2024`). Text never builds these by hand
/// in features: it calls the kit.
class PicoKitText {
  /// Creates the table for [english] or Indonesian.
  const new({this.english = false});

  /// Resolves from the ambient [Localizations]. Indonesian unless `en`.
  factory of(BuildContext context) => PicoKitText(
    english: Localizations.maybeLocaleOf(context)?.languageCode == 'en',
  );

  /// True for English.
  final bool english;

  static const _monthsId = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  static const _monthsEn = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String _t(String id, String en) => english ? en : id;

  /// Retry button.
  String get retry => _t('Coba lagi', 'Try again');

  /// A figure with no data.
  String get noData => _t('Tidak ada data', 'No data');

  /// Offline label. Always text, never only an icon.
  String get offline => _t('Tidak terhubung', 'Offline');

  /// A refresh failed for a reason other than no network.
  String get refreshFailed => _t('Gagal memperbarui', 'Refresh failed');

  /// Copy confirmation.
  String get copied => _t('Disalin', 'Copied');

  /// Copy action.
  String get copy => _t('Salin', 'Copy');

  /// Loading state message.
  String get loading => _t('Memuat data', 'Loading data');

  /// Empty state default message.
  String get empty => _t('Belum ada data', 'No data yet');

  /// Offline state message.
  String get offlineMessage => _t(
    'Tidak ada koneksi. Coba lagi saat sudah terhubung.',
    'No connection. Try again when you are online.',
  );

  /// Generic error message.
  String get errorMessage => _t(
    'Data belum bisa dimuat. Coba lagi sebentar lagi.',
    'The data could not be loaded. Please try again shortly.',
  );

  /// Not found message.
  String get notFoundMessage =>
      _t('Halaman atau data tidak ditemukan.', 'Page or data not found.');

  /// "Lihat sebagai tabel" button of charts.
  String get viewAsTable => _t('Lihat sebagai tabel', 'View as table');

  /// Back to the chart from the table view.
  String get viewAsChart => _t('Kembali ke grafik', 'Back to chart');

  /// Joins a range in a summary: "2 Mar 2020 sampai 14 Jan 2024".
  String range(DateTime a, DateTime b) =>
      _t('${date(a)} sampai ${date(b)}', '${date(a)} to ${date(b)}');

  /// "puncak 64.718 pada 16 Feb 2022".
  String peak(String value, DateTime d) =>
      _t('puncak $value pada ${date(d)}', 'peak $value on ${date(d)}');

  /// Date range preset labels.
  String presetDays(int days) => _t('$days hari', '$days days');

  /// All data preset.
  String get presetAll => _t('Semua', 'All');

  /// Custom range button label.
  String get customRange => _t('Pilih rentang tanggal', 'Choose a date range');

  /// Label of a data state.
  String stateLabel(PicoState s) => english ? s.labelEn : s.labelId;

  /// Locale grouped integer: `64.718` (id), `64,718` (en). Keeps the sign.
  String number(int n) {
    final digits = n.abs().toString();
    final sep = english ? ',' : '.';
    final b = StringBuffer(n < 0 ? '-' : '');
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) b.write(sep);
      b.write(digits[i]);
    }
    return b.toString();
  }

  /// Compact axis number: `12 rb`, `1,2 jt` (id), `12K`, `1.2M` (en).
  String compact(num v) {
    final a = v.abs();
    String trim(double x) {
      final s = x.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');
      return english ? s : s.replaceFirst('.', ',');
    }

    final sign = v < 0 ? '-' : '';
    if (a >= 1000000)
      return '$sign${trim(a / 1000000)}${english ? 'M' : ' jt'}';
    if (a >= 1000) return '$sign${trim(a / 1000)}${english ? 'K' : ' rb'}';
    return '$sign${trim(a.toDouble())}';
  }

  /// Decimal with [digits] places and the locale separator: `0,46` (id),
  /// `0.46` (en).
  String decimal(double v, {int digits = 2}) {
    final s = v.toStringAsFixed(digits);
    return english ? s : s.replaceFirst('.', ',');
  }

  /// Axis date: the year for yearly ticks, otherwise the month (with the year
  /// in January).
  String axisDate(DateTime d, {bool yearOnly = false}) {
    if (yearOnly) return '${d.year}';
    final m = (english ? _monthsEn : _monthsId)[d.month - 1];
    return d.month == 1 ? '$m ${d.year}' : m;
  }

  /// Short date: `14 Jan 2024` (id), `Jan 14, 2024` (en).
  String date(DateTime d) {
    final m = (english ? _monthsEn : _monthsId)[d.month - 1];
    return english ? '$m ${d.day}, ${d.year}' : '${d.day} $m ${d.year}';
  }

  /// "Data per 14 Jan 2024".
  String dataAsOf(DateTime d) =>
      _t('Data per ${date(d)}', 'Data as of ${date(d)}');

  /// Age of a copy: `3 jam lalu` / `3 hours ago`.
  String ago(Duration d) {
    if (d.inMinutes < 1) return _t('baru saja', 'just now');
    if (d.inMinutes < 60) {
      final n = d.inMinutes;
      return _t('$n menit lalu', n == 1 ? '1 minute ago' : '$n minutes ago');
    }
    if (d.inHours < 24) {
      final n = d.inHours;
      return _t('$n jam lalu', n == 1 ? '1 hour ago' : '$n hours ago');
    }
    final n = d.inDays;
    return _t('$n hari lalu', n == 1 ? '1 day ago' : '$n days ago');
  }

  /// "diperbarui 3 jam lalu" (network copy).
  String updated(Duration d) => _t('diperbarui ${ago(d)}', 'updated ${ago(d)}');

  /// "data tersimpan, 2 hari lalu" (cached copy).
  String saved(Duration d) =>
      _t('data tersimpan, ${ago(d)}', 'saved data, ${ago(d)}');
}
