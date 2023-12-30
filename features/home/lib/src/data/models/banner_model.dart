import 'package:dependencies/dependencies.dart';
import 'package:home/src/domain/entities/banner.dart';

part 'banner_model.freezed.dart';
part 'banner_model.g.dart';

@freezed
abstract class BannerModel with _$BannerModel {
  factory BannerModel({
    @JsonKey() required int id,
    @JsonKey() required String title,
    @JsonKey() required String urlType,
    @JsonKey() required String url,
    @JsonKey() required String image,
  }) = _BannerModel;
  factory BannerModel.fromJson(Map<String, dynamic> json) =>
      _$BannerModelFromJson(json);

  
}

extension BannerModelX on BannerModel {
  Banner toEntity() => Banner(
        id: id,
        image: image,
        title: title,
        url: url,
        urlType: urlType,
      );
}
