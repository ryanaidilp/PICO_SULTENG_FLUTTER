class Infographic {
  Infographic({
    required this.id,
    required this.title,
    required this.link,
    required this.publishedAt,
    required this.images,
  });

  final String id;
  final String title;
  final String link;
  final DateTime publishedAt;
  final List<dynamic> images;

  factory Infographic.fromJson(Map<String, dynamic> json) => Infographic(
        id: json['id'] as String,
        title: json['judul'] as String,
        link: json['link'] as String,
        publishedAt: DateTime.parse(json['published_at'] as String).toLocal(),
        images: json['images'] as List<dynamic>,
      );
}
