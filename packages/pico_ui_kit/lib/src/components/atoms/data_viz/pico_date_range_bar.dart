import 'package:flutter/material.dart';
import 'package:pico_ui_kit/src/components/atoms/brand/pico_brand_icon.dart';
import 'package:pico_ui_kit/src/components/utilities/pico_kit_text.dart';
import 'package:pico_ui_kit/src/extensions/build_context_extensions.dart';

/// Preset windows ending at the end of the data: 7, 30, 90 days and all.
/// A custom range opens the adaptive date range picker, bounded to the data.
class PicoDateRangeBar extends StatelessWidget {
  /// Creates the bar. [bounds] is the whole data range.
  const new({
    required this.range,
    required this.bounds,
    required this.onChanged,
    this.presets = const [7, 30, 90],
    super.key,
  });

  /// Current range.
  final DateTimeRange range;

  /// Data bounds. Presets end at `bounds.end`.
  final DateTimeRange bounds;

  /// Called with the new range.
  final ValueChanged<DateTimeRange> onChanged;

  /// Preset lengths in days.
  final List<int> presets;

  DateTimeRange _last(int days) => DateTimeRange(
    start:
        DateUtils.dateOnly(bounds.end.subtract(Duration(days: days - 1)))
            .isBefore(bounds.start)
        ? bounds.start
        : DateUtils.dateOnly(bounds.end.subtract(Duration(days: days - 1))),
    end: bounds.end,
  );

  bool _same(DateTimeRange a, DateTimeRange b) =>
      DateUtils.isSameDay(a.start, b.start) &&
      DateUtils.isSameDay(a.end, b.end);

  Future<void> _custom(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: bounds.start,
      lastDate: bounds.end,
      initialDateRange: range,
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final t = PicoKitText.of(context);
    final all = DateTimeRange(start: bounds.start, end: bounds.end);
    Widget chip(String label, DateTimeRange r) => ChoiceChip(
      label: Text(label),
      selected: _same(range, r),
      materialTapTargetSize: MaterialTapTargetSize.padded,
      onSelected: (_) => onChanged(r),
    );
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final d in presets) chip(t.presetDays(d), _last(d)),
        chip(t.presetAll, all),
        Semantics(
          button: true,
          label: t.customRange,
          child: IconButton(
            onPressed: () => _custom(context),
            tooltip: t.customRange,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            icon: PicoBrandIcon(
              'calendar.range',
              color: context.colors.foreground.main,
            ),
          ),
        ),
      ],
    );
  }
}
