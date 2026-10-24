import 'dart:async';

import 'package:dependencies/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:locale_core/locale_core.dart' as app_l10n;
import 'package:pico_ui_kit/pico_ui_kit.dart';
import 'package:push_notification_api/push_notification_api.dart';
import 'package:push_notification_impl/src/l10n/push_translations.g.dart';

/// The push strings in the app's current locale (`locale_core`), English
/// when this package has no translation for it. The page is not under a
/// feature shell, so there is no `TranslationProvider` to sync.
PushTranslations pushStrings() {
  final tag = app_l10n.LocaleSettings.currentLocale.languageTag;
  return PushLocale.values
      .firstWhere((l) => l.languageTag == tag, orElse: () => PushLocale.en)
      .translations;
}

/// Quiet hours and the marketing opt-out, read and written through [sdk].
/// Registered at `PushNotificationSDK.settingsPath`.
class const NotificationSettingsPage({
  required final PushNotificationSDK sdk,
  super.key,
}) extends StatefulWidget {
  /// Window applied when the user turns quiet hours on: 22:00-07:00.
  static const QuietHours defaultQuietHours = QuietHours(
    startMinute: 22 * 60,
    endMinute: 7 * 60,
  );

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState() extends State<NotificationSettingsPage> {
  QuietHours? _quietHours;
  bool _loaded = false;
  late bool _marketing = widget.sdk.marketingEnabled;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final quietHours = await widget.sdk.getQuietHours();
    if (!mounted) return;
    setState(() {
      _quietHours = quietHours;
      _loaded = true;
    });
  }

  Future<void> _setQuietHours(QuietHours? quietHours) async {
    setState(() => _quietHours = quietHours);
    await widget.sdk.setQuietHours(quietHours);
  }

  Future<void> _setMarketing(bool enabled) async {
    setState(() => _marketing = enabled);
    try {
      await widget.sdk.setMarketingEnabled(enabled: enabled);
    } finally {
      // Shows the stored decision, also when recording it failed.
      if (mounted) setState(() => _marketing = widget.sdk.marketingEnabled);
    }
  }

  Future<void> _pickTime({required bool start}) async {
    final current = _quietHours!;
    final minute = start ? current.startMinute : current.endMinute;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minute ~/ 60, minute: minute % 60),
    );
    if (picked == null || !mounted) return;
    final value = picked.hour * 60 + picked.minute;
    await _setQuietHours(
      QuietHours(
        startMinute: start ? value : current.startMinute,
        endMinute: start ? current.endMinute : value,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = pushStrings().settings;
    final quietHours = _quietHours;
    return Scaffold(
      appBar: PicoAppBar(
        title: t.title,
        showBackButton: true,
        onBackPressed: () => context.router.maybePop(),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.symmetric(vertical: context.spacing.md),
          children: [
            SwitchListTile(
              key: const Key('notification_settings.quiet_hours'),
              title: Text(t.quietHours),
              subtitle: Text(t.quietHoursSubtitle),
              value: quietHours != null,
              onChanged: _loaded
                  ? (on) => _setQuietHours(
                      on ? NotificationSettingsPage.defaultQuietHours : null,
                    )
                  : null,
            ),
            if (quietHours != null) ...[
              _TimeTile(
                key: const Key('notification_settings.quiet_hours.start'),
                label: t.starts,
                minute: quietHours.startMinute,
                onTap: () => _pickTime(start: true),
              ),
              _TimeTile(
                key: const Key('notification_settings.quiet_hours.end'),
                label: t.ends,
                minute: quietHours.endMinute,
                onTap: () => _pickTime(start: false),
              ),
            ],
            const Divider(),
            SwitchListTile(
              key: const Key('notification_settings.marketing'),
              title: Text(t.marketing),
              subtitle: Text(t.marketingSubtitle),
              value: _marketing,
              onChanged: _setMarketing,
            ),
            Padding(
              padding: EdgeInsets.all(context.spacing.lg),
              child: Text(
                t.alwaysSent,
                style: context.typography.body.small.copyWith(
                  color: context.colors.foreground.subtle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class const _TimeTile({
  required final String label,
  required final int minute,
  required final VoidCallback onTap,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(label),
    trailing: Text(
      MaterialLocalizations.of(context)
          .formatTimeOfDay(TimeOfDay(hour: minute ~/ 60, minute: minute % 60)),
    ),
    onTap: onTap,
  );
}
