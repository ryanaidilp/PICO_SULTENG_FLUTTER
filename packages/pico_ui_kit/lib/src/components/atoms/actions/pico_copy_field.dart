import 'package:flutter/material.dart';
import 'package:pico_ui_kit/src/components/atoms/actions/pico_contact_actions.dart';
import 'package:pico_ui_kit/src/components/atoms/brand/pico_brand_icon.dart';
import 'package:pico_ui_kit/src/components/utilities/pico_kit_text.dart';
import 'package:pico_ui_kit/src/extensions/build_context_extensions.dart';

/// A label and a value with a copy button (for example a bank account number).
/// Copying shows "Disalin" in a snack bar and announces it.
class PicoCopyField extends StatelessWidget {
  /// Creates the field.
  const new({
    required this.label,
    required this.value,
    this.copyValue,
    this.copiedMessage,
    super.key,
  });

  /// What the value is.
  final String label;

  /// The value shown.
  final String value;

  /// What goes on the clipboard when it differs from [value] (for example the
  /// digits of an account number shown with spaces). Defaults to [value].
  final String? copyValue;

  /// What the snack bar and the announcement say. Defaults to "Disalin".
  final String? copiedMessage;

  @override
  Widget build(BuildContext context) {
    final t = PicoKitText.of(context);
    return Row(
      children: [
        Expanded(
          child: Semantics(
            container: true,
            label: '$label, $value',
            child: ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: context.typography.label.caption.copyWith(
                      color: context.colors.foreground.subtle,
                    ),
                  ),
                  Text(
                    value,
                    style: context.typography.body.large.copyWith(
                      color: context.colors.foreground.main,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: '${t.copy} $label',
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          onPressed: () => picoCopyToClipboard(
            context,
            copyValue ?? value,
            message: copiedMessage,
          ),
          icon: PicoBrandIcon(
            'action.copy',
            color: context.colors.foreground.main,
          ),
        ),
      ],
    );
  }
}
