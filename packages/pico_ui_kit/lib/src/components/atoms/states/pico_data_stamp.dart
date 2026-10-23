import 'package:flutter/material.dart';
import 'package:pico_ui_kit/src/components/utilities/pico_kit_text.dart';
import 'package:pico_ui_kit/src/extensions/build_context_extensions.dart';

/// "Data per 14 Jan 2024 · diperbarui 3 jam lalu". A cached or stale copy says
/// "data tersimpan, 2 hari lalu" and adds the offline icon and the text
/// "Tidak terhubung". The text is a live region, so a change is announced.
class PicoDataStamp extends StatelessWidget {
  /// Creates a stamp. [dataDate] is the date of the data, [fetchedAt] when the
  /// copy came from the network. [now] is for tests.
  const new({
    required this.dataDate,
    required this.fetchedAt,
    required this.fromCache,
    this.isStale = false,
    this.now,
    super.key,
  });

  /// Date of the newest data row.
  final DateTime dataDate;

  /// When this copy was fetched.
  final DateTime fetchedAt;

  /// True when the copy came from the offline store.
  final bool fromCache;

  /// Older than the TTL, or a refresh failed.
  final bool isStale;

  /// Clock override.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final t = PicoKitText.of(context);
    final age = (now ?? DateTime.now()).difference(fetchedAt);
    final offline = fromCache || isStale;
    final line = [
      t.dataAsOf(dataDate),
      if (offline) t.saved(age) else t.updated(age),
      if (offline) t.offline,
    ].join(' · ');
    return Semantics(
      liveRegion: true,
      label: line,
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (offline) ...[
              Icon(
                Icons.cloud_off_outlined,
                size: 14,
                color: context.colors.foreground.subtle,
              ),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                line,
                style: context.typography.label.caption.copyWith(
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
