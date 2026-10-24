/// Content that an owner has not decided or a reviewer has not checked yet.
/// Each shows as "Dalam peninjauan" in the app. They mirror the `data-todo`
/// markers of the web Metodologi page (specs/web/REVIEW-MARKERS.md).
///
/// Release builds must not ship with any of them open. A build for release
/// passes `--dart-define=PICO_RELEASE_CONTENT=true`; the app then fails at
/// boot (and this package's tests fail) while this list is not empty. Remove a
/// marker here only when its text has been replaced with the final outcome.
const List<String> kOpenReviewMarkers = [
  // Origin and licence of the old boundary files.
  'metodologi-peta',
  // Cultural review of the Kaili motifs (pico-jlc.8, O-12).
  'metodologi-budaya',
];

/// True in a build made for release.
const bool kReleaseContent = bool.fromEnvironment('PICO_RELEASE_CONTENT');

/// Throws when a release build still has an open review marker.
void assertNoOpenReviewMarkers({
  bool release = kReleaseContent,
  List<String> open = kOpenReviewMarkers,
}) {
  if (release && open.isNotEmpty) {
    throw StateError(
      'Release content is not final: ${open.join(', ')} are still '
      '"Dalam peninjauan". Resolve them or build without '
      'PICO_RELEASE_CONTENT=true.',
    );
  }
}
