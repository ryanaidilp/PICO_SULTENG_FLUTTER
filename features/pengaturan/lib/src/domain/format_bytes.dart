/// "0 B", "512 B", "12,4 KB", "3,0 MB". [comma] picks the decimal comma (id).
String formatBytes(int bytes, {required bool comma}) {
  if (bytes < 1024) return '$bytes B';
  const units = ['KB', 'MB', 'GB'];
  var v = bytes / 1024;
  var i = 0;
  while (v >= 1024 && i < units.length - 1) {
    v /= 1024;
    i++;
  }
  final s = v.toStringAsFixed(1);
  return '${comma ? s.replaceFirst('.', ',') : s} ${units[i]}';
}
