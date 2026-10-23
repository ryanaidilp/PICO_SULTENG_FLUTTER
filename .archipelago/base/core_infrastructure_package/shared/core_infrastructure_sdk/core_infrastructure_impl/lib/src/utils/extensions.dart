/// Common extensions for basic types.
library;

extension StringX on String {
  /// Capitalize first letter.
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }

  /// Convert to title case.
  String get titleCase => split(' ').map((word) => word.capitalize).join(' ');
}

extension DateTimeX on DateTime {
  /// Check if date is today.
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Check if date is yesterday.
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// Format as readable string.
  String get readable {
    if (isToday) return 'Today';
    if (isYesterday) return 'Yesterday';
    return '$day/$month/$year';
  }
}
