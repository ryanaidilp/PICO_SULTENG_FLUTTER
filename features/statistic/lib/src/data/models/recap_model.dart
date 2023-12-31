import 'package:dependencies/dependencies.dart';
import 'package:statistic/src/data/models/percentage_model.dart';
import 'package:statistic/src/data/models/reproduction_number_model.dart';
import 'package:statistic/src/domain/entities/recap.dart';

part 'recap_model.freezed.dart';
part 'recap_model.g.dart';

@freezed
abstract class RecapModel with _$RecapModel {
  factory RecapModel({
    @JsonKey(name: 'persentase') required PercentageModel percentage,
    @JsonKey(name: 'angka_reproduksi')
    ReproductionNumberModel? reproductionNumber,
  }) = _RecapModel;
  factory RecapModel.fromJson(Map<String, dynamic> json) =>
      _$RecapModelFromJson(json);
}

extension RecapModelX on RecapModel {
  Recap toEntity() => Recap(
        percentage: percentage.toEntity(),
        reproductionNumber: reproductionNumber?.toEntity(),
      );
}
