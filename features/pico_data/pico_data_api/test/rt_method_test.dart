import 'package:flutter_test/flutter_test.dart';
import 'package:pico_data_api/pico_data_api.dart';

void main() {
  archiveFacts();
  test('the Rt method numbers are the verified ones', () {
    expect(RtMethod.windowDays, 7);
    expect(RtMethod.serialIntervalMean, 7.5);
    expect(RtMethod.serialIntervalSd, 3.4);
    expect(RtMethod.minCasesInWindow, 12);
    expect(RtMethod.nationalLastDay, DateTime(2023, 7, 9));
    expect(RtMethod.credibleIntervalPercent, 95);
  });
}

void archiveFacts() {
  test('archive facts match the verified Metodologi dates', () {
    expect(ArchiveFacts.sultengRtLastDay, DateTime(2023, 6, 24));
    expect(ArchiveFacts.odpLastDay, DateTime(2022, 5, 8));
    expect(ArchiveFacts.testsLastDay, DateTime(2020, 9, 28));
    expect(ArchiveFacts.vaccinationLastDay, DateTime(2022, 3, 25));
    expect(kDataStart, DateTime(2020, 3, 2));
    expect(kDataEnd, DateTime(2024, 1, 14));
  });
}
