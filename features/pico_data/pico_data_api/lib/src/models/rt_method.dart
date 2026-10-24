/// How the API computes Rt (EpiEstim). The one source of these numbers: the Rt
/// page (S32c) and the Metodologi text (S42) both read them from here, so the
/// two texts cannot drift apart.
abstract final class RtMethod {
  /// Sliding window in days. Each value is labelled at the end of its window.
  static const int windowDays = 7;

  /// Mean of the serial interval in days.
  static const double serialIntervalMean = 7.5;

  /// Standard deviation of the serial interval in days.
  static const double serialIntervalSd = 3.4;

  /// A window with fewer cases than this gives no Rt.
  static const int minCasesInWindow = 12;

  /// Last day with a national Rt.
  static final DateTime nationalLastDay = DateTime(2023, 7, 9);

  /// Credible interval of the band, in percent.
  static const int credibleIntervalPercent = 95;
}
