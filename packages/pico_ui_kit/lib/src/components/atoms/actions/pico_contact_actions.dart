import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:pico_data_api/pico_data_api.dart';
import 'package:pico_ui_kit/src/components/atoms/brand/pico_brand_icon.dart';
import 'package:pico_ui_kit/src/components/utilities/pico_kit_text.dart';
import 'package:pico_ui_kit/src/extensions/build_context_extensions.dart';
import 'package:url_launcher/url_launcher.dart';

/// Registry key of the icon for a contact kind (C04 table).
String contactIconKey(ContactKind kind) => switch (kind) {
  ContactKind.email => 'contact.email',
  ContactKind.phone || ContactKind.fax => 'contact.phone',
  ContactKind.whatsapp => 'contact.whatsapp',
  ContactKind.telegram => 'contact.telegram',
  ContactKind.web ||
  ContactKind.twitter ||
  ContactKind.instagram ||
  ContactKind.line => 'contact.web',
};

/// Opens [uri] in an external app. Overridable in tests.
typedef UriLauncher = Future<bool> Function(Uri uri);

Future<bool> _launch(Uri uri) =>
    launchUrl(uri, mode: LaunchMode.externalApplication);

/// Shows "Disalin" and announces it. Used by contact rows and copy fields.
Future<void> picoCopyToClipboard(BuildContext context, String value) async {
  await Clipboard.setData(ClipboardData(text: value));
  if (!context.mounted) return;
  final text = PicoKitText.of(context).copied;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
  await SemanticsService.announce(text, Directionality.of(context));
}

/// One row per contact: icon, label, value. Tap opens the link in an external
/// app, the trailing button copies. Fax and values that do not parse to a link
/// are copy only.
class PicoContactActions extends StatelessWidget {
  /// Creates the list. [launcher] is for tests.
  const new({required this.contacts, this.launcher = _launch, super.key});

  /// Contacts to list.
  final List<Contact> contacts;

  /// Opens a link. Defaults to `url_launcher` in external mode.
  final UriLauncher launcher;

  @override
  Widget build(BuildContext context) {
    final t = PicoKitText.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final c in contacts)
          _Row(contact: c, launcher: launcher, copyLabel: t.copy),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const new({
    required this.contact,
    required this.launcher,
    required this.copyLabel,
  });

  final Contact contact;
  final UriLauncher launcher;
  final String copyLabel;

  @override
  Widget build(BuildContext context) {
    final uri = contact.kind == ContactKind.fax ? null : contact.uri;
    final style = context.typography;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: uri == null
                  ? () => picoCopyToClipboard(context, contact.value)
                  : () => launcher(uri),
              onLongPress: () => picoCopyToClipboard(context, contact.value),
              child: Semantics(
                button: true,
                label: '${contact.label}, ${contact.value}',
                child: ExcludeSemantics(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: Row(
                      children: [
                        PicoBrandIcon(
                          contactIconKey(contact.kind),
                          color: context.colors.action.primary.active,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                contact.label,
                                style: style.label.caption.copyWith(
                                  color: context.colors.foreground.subtle,
                                ),
                              ),
                              Text(
                                contact.value,
                                style: style.body.regular.copyWith(
                                  color: context.colors.foreground.main,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: copyLabel,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: () => picoCopyToClipboard(context, contact.value),
            icon: PicoBrandIcon(
              'action.copy',
              color: context.colors.foreground.main,
            ),
          ),
        ],
      ),
    );
  }
}
