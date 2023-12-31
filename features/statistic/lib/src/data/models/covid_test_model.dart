import 'package:dependencies/dependencies.dart';
import 'package:statistic/src/domain/entities/covid_test.dart';

part 'covid_test_model.freezed.dart';
part 'covid_test_model.g.dart';

@freezed
abstract class CovidTestModel with _$CovidTestModel {
  factory CovidTestModel({
    @JsonKey(name: 'hari_ke') required int day,
    @JsonKey(name: 'tanggal') required DateTime updatedAt,
    @JsonKey(name: 'nama') required String name,
    @JsonKey(name: 'sampel') required String sample,
    @JsonKey(name: 'durasi') required String duration,
    @JsonKey(name: 'positif') required int positive,
    @JsonKey(name: 'negatif') required int negative,
    @JsonKey(name: 'proses') required int process,
    @JsonKey() required int invalid,
    @JsonKey() required int total,
  }) = _CovidTestModel;
  factory CovidTestModel.fromJson(Map<String, dynamic> json) =>
      _$CovidTestModelFromJson(json);
}

extension CovidTestModelX on CovidTestModel {
  CovidTest toEntity() => CovidTest(
        day: day,
        updatedAt: updatedAt,
        name: name,
        sample: sample,
        duration: duration,
        positive: positive,
        negative: negative,
        process: process,
        invalid: invalid,
        total: total,
      );
}
