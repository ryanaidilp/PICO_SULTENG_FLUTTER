import 'package:flutter/material.dart';
import 'package:pengaturan/src/l10n/translations.g.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

/// One choice of a single-choice group. A single semantics node that reads
/// "Gelap, dipilih" when chosen, and is never colour only (filled radio).
class OptionTile extends StatelessWidget {
  /// Creates the tile.
  const new({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  /// Visible label.
  final String label;

  /// Whether this choice is the current one.
  final bool selected;

  /// Tap handler.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    inMutuallyExclusiveGroup: true,
    label: selected ? '$label, ${context.t.selected}' : label,
    excludeSemantics: true,
    onTap: onTap,
    child: InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: context.colors.foreground.main,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: context.typography.body.regular.copyWith(
                    color: context.colors.foreground.main,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
