extension IntX on int {
  Duration get days => Duration(days: this);
  Duration get hours => Duration(hours: this);
  Duration get minutes => Duration(minutes: this);
  Duration get seconds => Duration(seconds: this);
  Duration get milliseconds => Duration(milliseconds: this);
  Duration get microseconds => Duration(microseconds: this);
}

extension DoubleX on double {
  int get precision {
    final s = toString();
    if (s.contains('e')) {
      // Handle scientific notation
      final eIndex = s.indexOf('e');
      final decimals = int.parse(s.substring(eIndex + 1));
      return s.substring(0, eIndex).replaceAll('.', '').length - decimals;
    }
    var precission = s.contains('.') ? s.split('.')[1].length : 0;

    if (precission == 3) {
      precission += 1;
    }
    return precission;
  }
}
