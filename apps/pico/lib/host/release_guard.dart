import 'package:flutter/material.dart';
import 'package:informasi/informasi.dart';

/// The reason a release-content build must not start, or null.
///
/// A build for release passes `--dart-define=PICO_RELEASE_CONTENT=true`. While a
/// review marker is open (O-7 map data author, O-12 cultural review) such a
/// build must stop instead of shipping "Dalam peninjauan" text. This runs in
/// `bootstrap()` before `runApp`; a manifest could not do it, because a
/// manifest that throws is reported and skipped by the pre-launch phase.
String? releaseContentProblem({
  bool release = kReleaseContent,
  List<String> open = kOpenReviewMarkers,
}) {
  try {
    assertNoOpenReviewMarkers(release: release, open: open);
    return null;
  } on StateError catch (e) {
    return e.message;
  }
}

/// The only screen of a blocked build: the reason, in plain text.
class ReleaseContentBlockedApp extends StatelessWidget {
  /// Creates the screen.
  const ReleaseContentBlockedApp(this.message, {super.key});

  /// What [releaseContentProblem] returned.
  final String message;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(child: Text(message)),
        ),
      ),
    ),
  );
}
