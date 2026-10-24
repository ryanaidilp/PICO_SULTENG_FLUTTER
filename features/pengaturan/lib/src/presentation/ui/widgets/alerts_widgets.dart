import 'package:flutter/material.dart';
import 'package:pengaturan/src/l10n/translations.g.dart';
import 'package:pico_ui_kit/pico_ui_kit.dart';

/// The "Kabar pembaruan data" switch row: one semantics node that reads the
/// label, the hint and the on/off state, with a 48 dp target.
class AlertsSwitchTile extends StatelessWidget {
  /// Creates the row.
  const new({
    required this.value,
    required this.busy,
    required this.onChanged,
    super.key,
  });

  /// Whether alerts are on.
  final bool value;

  /// A change is running: the row ignores taps.
  final bool busy;

  /// Called with the wanted value.
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final colors = context.colors;
    final typography = context.typography;
    void toggle() {
      if (!busy) onChanged(!value);
    }

    return Semantics(
      container: true,
      toggled: value,
      label: '${t.alertsTitle}. ${t.alertsHint}',
      onTap: busy ? null : toggle,
      excludeSemantics: true,
      child: InkWell(
        onTap: busy ? null : toggle,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.alertsTitle,
                        style: typography.body.regular.copyWith(
                          color: colors.foreground.main,
                        ),
                      ),
                      Text(
                        t.alertsHint,
                        style: typography.body.small.copyWith(
                          color: colors.foreground.subtle,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                IgnorePointer(
                  child: Switch.adaptive(value: value, onChanged: (_) {}),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A full-width text row that acts as a link or a button (48 dp).
class AlertsActionRow extends StatelessWidget {
  /// Creates the row.
  const new({
    required this.label,
    required this.icon,
    required this.onTap,
    super.key,
  });

  /// Visible and spoken label.
  final String label;

  /// Leading icon.
  final IconData icon;

  /// Tap handler.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
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
              Icon(icon, color: context.colors.foreground.main),
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

/// The explain sheet of ADR-0112 step 3. Pops `true` on "Izinkan" and `false`
/// on "Nanti saja". Lives in the root overlay, so the strings travel as [t].
class AlertsExplainSheet extends StatelessWidget {
  /// Creates the sheet.
  const new({required this.t, super.key});

  /// The feature strings.
  final Translations t;

  @override
  Widget build(BuildContext context) {
    final typography = context.typography;
    final fg = context.colors.foreground.main;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              header: true,
              child: Text(
                t.alertsTitle,
                style: typography.heading.h3.copyWith(color: fg),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              t.alertsSheetBody,
              style: typography.body.regular.copyWith(color: fg),
            ),
            const SizedBox(height: 8),
            Text(
              t.alertsSheetDevice,
              style: typography.body.regular.copyWith(color: fg),
            ),
            const SizedBox(height: 16),
            PicoButton(
              label: t.alertsAllow,
              isExpanded: true,
              onPressed: () => Navigator.pop(context, true),
            ),
            const SizedBox(height: 8),
            PicoButton(
              label: t.alertsLater,
              isExpanded: true,
              style: PicoButtonStyle.outlined,
              onPressed: () => Navigator.pop(context, false),
            ),
          ],
        ),
      ),
    );
  }
}
