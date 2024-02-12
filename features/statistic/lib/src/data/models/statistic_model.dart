import 'package:dependencies/dependencies.dart';
import 'package:statistic/src/data/models/case_model.dart';
import 'package:statistic/src/data/models/recap_model.dart';
import 'package:statistic/src/domain/entities/statistic.dart';

part 'statistic_model.freezed.dart';
part 'statistic_model.g.dart';

@freezed
abstract class StatisticModel with _$StatisticModel {
  factory StatisticModel({
    @JsonKey(name: 'hari_ke') required int day,
    @JsonKey(name: 'tanggal') required DateTime updatedAt,
    @JsonKey(name: 'kumulatif') required CaseModel cumulative,
    @JsonKey(name: 'kasus_baru') required CaseModel newCases,
    @JsonKey(name: 'rekap') required RecapModel recap,
  }) = _StatisticModel;
  factory StatisticModel.fromJson(Map<String, dynamic> json) =>
      _$StatisticModelFromJson(json);

  factory StatisticModel.fromEntity(Statistic entity) => StatisticModel(
        day: entity.day,
        cumulative: CaseModel.fromEntity(entity.cumulative),
        newCases: CaseModel.fromEntity(entity.newCases),
        recap: RecapModel.fromEntity(entity.recap),
        updatedAt: entity.updatedAt,
      );
}

extension StatisticModelX on StatisticModel {
  Statistic toEntity() => Statistic(
        day: day,
        updatedAt: updatedAt,
        cumulative: cumulative.toEntity(),
        newCases: newCases.toEntity(),
        recap: recap.toEntity(),
      );
}
