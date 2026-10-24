import 'package:flutter/material.dart';
import 'package:pico_ui_kit/src/components/utilities/pico_kit_text.dart';
import 'package:pico_ui_kit/src/extensions/build_context_extensions.dart';

/// The "Data per ..." line under a data block. It tells the truth in each
/// state:
///
/// - fresh copy (network, or saved and inside its lifetime):
///   "Data per 14 Jan 2024 · diperbarui 3 jam lalu"
/// - saved copy past its lifetime, refresh pending or not tried:
///   "Data per 14 Jan 2024 · data tersimpan, 8 hari lalu"
/// - refresh failed with no network: adds the cloud-off icon and "Tidak
///   terhubung"
/// - refresh failed for another reason: adds the warning icon and "Gagal
///   memperbarui"
///
/// A saved copy that is still fresh by policy is NOT offline: the app simply
/// did not need the network. The text is a live region, so a change is
/// announced.
class PicoDataStamp extends StatelessWidget {
  /// Creates a stamp. [dataDate] is the date of the data, [fetchedAt] when the
  /// copy was fetched (or last confirmed). [now] is for tests.
  const new({
    required this.dataDate,
    required this.fetchedAt,
    this.isStale = false,
    this.offline = false,
    this.refreshFailed = false,
    this.now,
    super.key,
  });

  /// Date of the newest data row.
  final DateTime dataDate;

  /// When this copy was fetched.
  final DateTime fetchedAt;

  /// The copy is older than its lifetime.
  final bool isStale;

  /// The last refresh failed because there is no network.
  final bool offline;

  /// The last refresh failed for another reason.
  final bool refreshFailed;

  /// Clock override.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final t = PicoKitText.of(context);
    final age = (now ?? DateTime.now()).difference(fetchedAt);
    final saved = isStale || offline || refreshFailed;
    final line = [
      t.dataAsOf(dataDate),
      if (saved) t.saved(age) else t.updated(age),
      if (offline) t.offline else if (refreshFailed) t.refreshFailed,
    ].join(' · ');
    final problem = offline || refreshFailed;
    return Semantics(
      liveRegion: true,
      label: line,
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (problem) ...[
              Icon(
                offline ? Icons.cloud_off_outlined : Icons.error_outline,
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
