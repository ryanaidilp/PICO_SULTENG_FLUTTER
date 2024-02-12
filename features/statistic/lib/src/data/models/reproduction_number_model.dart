import 'package:dependencies/dependencies.dart';
import 'package:statistic/src/domain/entities/reproduction_number.dart';

part 'reproduction_number_model.freezed.dart';
part 'reproduction_number_model.g.dart';

@freezed
abstract class ReproductionNumberModel with _$ReproductionNumberModel {
  factory ReproductionNumberModel({
    @JsonKey(name: 'rt') double? value,
    @JsonKey(name: 'rt_upper') double? upperBound,
    @JsonKey(name: 'rt_lower') double? lowerBound,
  }) = _ReproductionNumberModel;
  factory ReproductionNumberModel.fromJson(Map<String, dynamic> json) =>
      _$ReproductionNumberModelFromJson(json);

  factory ReproductionNumberModel.fromEntity(ReproductionNumber? entity) =>
      ReproductionNumberModel(
        value: entity?.value,
        lowerBound: entity?.lowerBound,
        upperBound: entity?.upperBound,
      );
}

extension ReproductionNumberModelX on ReproductionNumberModel {
  ReproductionNumber toEntity() => ReproductionNumber(
        value: value,
        upperBound: upperBound,
        lowerBound: lowerBound,
      );
}
