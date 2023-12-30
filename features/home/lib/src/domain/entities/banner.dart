import 'package:dependencies/dependencies.dart';

class Banner extends Equatable {
  const Banner({
    this.id = 0,
    this.title = '',
    this.urlType = '',
    this.url = '',
    this.image = '',
  });

  final int id;
  final String title;
  final String urlType;
  final String url;
  final String image;

  @override
  List<Object> get props {
    return [
      id,
      title,
      urlType,
      url,
      image,
    ];
  }
}
