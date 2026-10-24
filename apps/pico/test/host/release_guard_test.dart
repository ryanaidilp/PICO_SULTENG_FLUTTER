import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pico/host/release_guard.dart';

void main() {
  test('a release-content build with open markers is blocked', () {
    final p = releaseContentProblem(release: true, open: ['metodologi-peta']);
    expect(p, contains('metodologi-peta'));
    expect(p, contains('Dalam peninjauan'));
  });

  test('no open markers, or a normal build, is not blocked', () {
    expect(releaseContentProblem(release: true, open: const []), isNull);
    expect(releaseContentProblem(release: false, open: ['x']), isNull);
  });

  test('the shipped list still has the two owner items (O-7, O-12)', () {
    // This is why a PICO_RELEASE_CONTENT=true build must stop today.
    expect(releaseContentProblem(release: true), isNotNull);
  });

  testWidgets('the blocked screen shows the reason', (tester) async {
    await tester.pumpWidget(const ReleaseContentBlockedApp('stop here'));
    expect(find.text('stop here'), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
