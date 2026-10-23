import 'package:flutter/material.dart';

/// A single-choice segmented control (case type, daily or cumulative, level).
/// Every segment is at least 48 dp tall.
class PicoSegmented<T> extends StatelessWidget {
  /// Creates the control.
  const new({
    required this.values,
    required this.selected,
    required this.label,
    required this.onChanged,
    super.key,
  });

  /// Choices in order.
  final List<T> values;

  /// The chosen value.
  final T selected;

  /// Visible label of a value.
  final String Function(T value) label;

  /// Called with the new choice.
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => SegmentedButton<T>(
    showSelectedIcon: false,
    segments: [
      for (final v in values) ButtonSegment<T>(value: v, label: Text(label(v))),
    ],
    selected: {selected},
    onSelectionChanged: (s) => onChanged(s.first),
    style: const ButtonStyle(minimumSize: WidgetStatePropertyAll(Size(48, 48))),
  );
}
