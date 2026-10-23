/// Cache lifetimes per resource class (C05, ADR-0109). Constants in one file
/// so live mode can lower them later.
abstract final class PicoTtl {
  /// Cases, statistics and vaccination.
  static const Duration data = Duration(hours: 24);

  /// Directories and content.
  static const Duration content = Duration(hours: 6);
}
