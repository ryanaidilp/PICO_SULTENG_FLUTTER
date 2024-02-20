import 'package:flutter_test/flutter_test.dart';
import 'package:statistic/statistic.dart';

void main() {
  late final CovidTest covidTest;

  setUpAll(
    () {
      covidTest = CovidTest(
        day: 1,
        duration: '1 day',
        invalid: 10,
        name: 'Polymeraise Chain Reaction',
        negative: 120,
        positive: 510,
        process: 25,
        sample: 'From user',
        total: 665,
        updatedAt: DateTime.now(),
      );
    },
  );

  group(
    'CovidTest',
    () {
      test(
        'total properties should the same as total of other property',
        () => expect(
          covidTest.total,
          equals(
            covidTest.positive +
                covidTest.negative +
                covidTest.invalid +
                covidTest.process,
          ),
        ),
      );

      test(
        'reactivePercentage is equals to positive/total',
        () => expect(
          covidTest.reactivePercentage,
          covidTest.positive / covidTest.total * 100,
        ),
      );

      test(
        'nonReactivePercentage is equals to negative/total',
        () => expect(
          covidTest.nonReactivePercentage,
          covidTest.negative / covidTest.total * 100,
        ),
      );

      test(
        'invalidPercentage is equals to invalid/total',
        () => expect(
          covidTest.invalidPercentage,
          covidTest.invalid / covidTest.total * 100,
        ),
      );

      test(
        'inProcessPercentage is equals to process/total',
        () => expect(
          covidTest.inProcessPercentage,
          covidTest.process / covidTest.total * 100,
        ),
      );

      test(
        'nameAbbreviation return first letter of every word from name',
        () => expect(
          covidTest.nameAbbreviation,
          'PCR',
        ),
      );
    },
  );
}
