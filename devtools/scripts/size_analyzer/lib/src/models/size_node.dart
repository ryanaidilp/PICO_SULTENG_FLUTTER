class const SizeNode({required final String name, required final int bytes}) {
  double get kb => bytes / 1024;
  double get mb => bytes / 1024 / 1024;

  String get formatted {
    if (bytes >= 1024 * 1024) return '${mb.toStringAsFixed(2)} MB';
    return '${kb.toStringAsFixed(1)} KB';
  }
}

class const SizeNodeDiff({
  required final String name,
  required final int bytes,
  required final int delta,
}) {
  bool get isNew => delta == bytes;
  bool get isIncrease => delta > 0;

  String get deltaFormatted {
    final prefix = delta >= 0 ? '+' : '-';
    final abs = delta.abs();
    if (abs >= 1024 * 1024) {
      return '$prefix${(abs / 1024 / 1024).toStringAsFixed(2)} MB';
    }
    return '$prefix${(abs / 1024).toStringAsFixed(1)} KB';
  }
}
