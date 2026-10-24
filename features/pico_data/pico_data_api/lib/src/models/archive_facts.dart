/// Dates the Metodologi text states, in one place (checked against the web
/// FACTS of PICO_SULTENG_WEB, which tests them against the data).
abstract final class ArchiveFacts {
  /// Last day with a Sulawesi Tengah Rt.
  static final DateTime sultengRtLastDay = DateTime(2023, 6, 24);

  /// Last day with ODP and PDP numbers for Sulawesi Tengah.
  static final DateTime odpLastDay = DateTime(2022, 5, 8);

  /// Start date of the last test period.
  static final DateTime testsLastDay = DateTime(2020, 9, 28);

  /// Last vaccination day.
  static final DateTime vaccinationLastDay = DateTime(2022, 3, 25);

  /// The open API, as the Metodologi text names it.
  static const String apiBase = 'https://pico-api.banuacoder.com/api/v1';
}
