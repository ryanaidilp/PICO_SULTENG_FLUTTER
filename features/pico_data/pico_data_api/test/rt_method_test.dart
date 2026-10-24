import 'package:flutter_test/flutter_test.dart';
import 'package:pico_data_api/pico_data_api.dart';

void main() {
  test('the Rt method numbers are the verified ones', () {
    expect(RtMethod.windowDays, 7);
    expect(RtMethod.serialIntervalMean, 7.5);
    expect(RtMethod.serialIntervalSd, 3.4);
    expect(RtMethod.minCasesInWindow, 12);
    expect(RtMethod.nationalLastDay, DateTime(2023, 7, 9));
    expect(RtMethod.credibleIntervalPercent, 95);
  });
}
