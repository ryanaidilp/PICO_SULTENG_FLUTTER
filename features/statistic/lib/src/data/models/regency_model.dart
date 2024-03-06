import 'package:dependencies/dependencies.dart';
import 'package:statistic/src/data/data.dart';
import 'package:statistic/src/domain/entities/entities.dart';

part 'regency_model.freezed.dart';
part 'regency_model.g.dart';

@freezed
abstract class RegencyModel with _$RegencyModel {
  factory RegencyModel({
    @JsonKey() required int id,
    @JsonKey(name: 'hari_ke') required int day,
    @JsonKey(name: 'kabupaten') required String name,
    @JsonKey(name: 'tanggal') required DateTime date,
    @JsonKey(name: 'kasus_baru') required CaseModel newCase,
    @JsonKey(name: 'kumulatif') required CaseModel cumulative,
    @JsonKey(name: 'rekap') required RecapModel recap,
  }) = _RegencyModel;

  factory RegencyModel.fromJson(Map<String, dynamic> json) =>
      _$RegencyModelFromJson(json);

  factory RegencyModel.fromEntity(Regency entity) => RegencyModel(
        id: entity.id,
        day: entity.day,
        name: entity.name,
        date: entity.date,
        newCase: CaseModel.fromEntity(entity.newCase),
        cumulative: CaseModel.fromEntity(entity.cumulative),
        recap: RecapModel.fromEntity(entity.recap),
      );
}

extension RegencyModelX on RegencyModel {
  Regency toEntity() => Regency(
        id: id,
        day: day,
        date: date,
        name: name,
        newCase: newCase.toEntity(),
        cumulative: cumulative.toEntity(),
        recap: recap.toEntity(),
      );
}
