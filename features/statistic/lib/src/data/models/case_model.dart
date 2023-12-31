import 'package:dependencies/dependencies.dart';
import 'package:statistic/src/domain/entities/case.dart';

part 'case_model.freezed.dart';
part 'case_model.g.dart';

@freezed
abstract class CaseModel with _$CaseModel {
  factory CaseModel({
    @JsonKey(name: 'positif') required int positive,
    @JsonKey(name: 'sembuh') required int recovered,
    @JsonKey(name: 'meninggal') required int deceased,
    @JsonKey(name: 'dalam_perawatan') required int underTreatment,
    @JsonKey(
      name: 'ODP',
      defaultValue: 0,
    )
    required int totalObserved,
    @JsonKey(
      name: 'selesai_ODP',
      defaultValue: 0,
    )
    required int finishedObservation,
    @JsonKey(
      name: 'dalam_ODP',
      defaultValue: 0,
    )
    required int underObservation,
    @JsonKey(
      name: 'PDP',
      defaultValue: 0,
    )
    required int totalSupervised,
    @JsonKey(
      name: 'selesai_PDP',
      defaultValue: 0,
    )
    required int finishedSupervision,
    @JsonKey(
      name: 'dalam_PDP',
      defaultValue: 0,
    )
    required int underSupervision,
  }) = _CaseModel;
  factory CaseModel.fromJson(Map<String, dynamic> json) =>
      _$CaseModelFromJson(json);
}

extension CaseModelX on CaseModel {
  Case toEntity() => Case(
        positive: positive,
        recovered: recovered,
        deceased: deceased,
        underTreatment: underTreatment,
        totalObserved: totalObserved,
        finishedObservation: finishedObservation,
        underObservation: underObservation,
        totalSupervised: totalSupervised,
        finishedSupervision: finishedSupervision,
        underSupervision: underSupervision,
      );
}
