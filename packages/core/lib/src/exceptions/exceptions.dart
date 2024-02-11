class PicoException implements Exception {
  const PicoException({
    required this.message,
  });
  final String message;

  @override
  String toString() => message;
}
