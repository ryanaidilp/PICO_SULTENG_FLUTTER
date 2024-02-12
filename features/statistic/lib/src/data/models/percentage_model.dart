import 'package:dependencies/dependencies.dart';
import 'package:statistic/src/domain/entities/percentage.dart';

part 'percentage_model.freezed.dart';
part 'percentage_model.g.dart';

@freezed
abstract class PercentageModel with _$PercentageModel {
  factory PercentageModel({
    @JsonKey(name: 'dalam_perawatan') required double underTreatment,
    @JsonKey(name: 'sembuh') required double recovered,
    @JsonKey(name: 'meninggal') required double deceased,
  }) = _PercentageModel;
  factory PercentageModel.fromJson(Map<String, dynamic> json) =>
      _$PercentageModelFromJson(json);
  factory PercentageModel.fromEntity(Percentage entity) => PercentageModel(
        underTreatment: entity.underTreatment,
        recovered: entity.recovered,
        deceased: entity.deceased,
      );
}

extension PercentageModelX on PercentageModel {
  Percentage toEntity() => Percentage(
        underTreatment: underTreatment,
        deceased: deceased,
        recovered: recovered,
      );
}
