import 'package:flutter/material.dart';
import 'package:pico_ui_kit/src/extensions/build_context_extensions.dart';
import 'package:pico_ui_kit/src/foundations/radius/pico_radius_token.dart';

/// One entry of a [PicoDropdown].
class PicoDropdownItem<T> {
  /// Creates an entry.
  const PicoDropdownItem(this.value, this.label);

  /// The value it stands for.
  final T value;

  /// Visible and spoken text.
  final String label;
}

/// The original PICO dropdown: an outlined rounded field with the chosen label
/// and a chevron, opening a card-coloured menu. At least 48 dp high (the first
/// app had 32 dp). It is one semantics node that reads [semanticLabel] and the
/// chosen entry.
class PicoDropdown<T> extends StatelessWidget {
  /// Creates the dropdown. [value] must be one of [items] or null.
  const PicoDropdown({
    required this.items,
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
    this.leading,
    this.minWidth = 96,
    super.key,
  });

  /// The entries.
  final List<PicoDropdownItem<T>> items;

  /// The chosen value.
  final T? value;

  /// Called with the new value.
  final ValueChanged<T> onChanged;

  /// What the field is for ("Jenis kasus").
  final String semanticLabel;

  /// Optional icon before the label.
  final Widget? leading;

  /// Minimum width of the field.
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final style = context.typography.body.small.copyWith(
      color: colors.foreground.main,
    );
    final chosen = items.where((i) => i.value == value).firstOrNull;
    return Semantics(
      container: true,
      label: semanticLabel,
      value: chosen?.label,
      child: ExcludeSemantics(
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: minWidth, minHeight: 48),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: PicoRadiusToken.borderSm,
              border: Border.all(color: colors.outline.main),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<T>(
                  value: value,
                  isDense: true,
                  isExpanded: false,
                  style: style,
                  dropdownColor: colors.background.card,
                  borderRadius: PicoRadiusToken.borderSm,
                  icon: Icon(
                    Icons.expand_more_rounded,
                    color: colors.foreground.subtle,
                  ),
                  selectedItemBuilder: (context) => [
                    for (final i in items)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (leading != null) ...[
                            leading!,
                            const SizedBox(width: 8),
                          ],
                          Text(i.label, style: style),
                        ],
                      ),
                  ],
                  items: [
                    for (final i in items)
                      DropdownMenuItem<T>(
                        value: i.value,
                        child: Text(
                          i.label,
                          style: style.copyWith(
                            fontWeight: i.value == value
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                  ],
                  onChanged: (v) {
                    if (v != null) onChanged(v);
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
