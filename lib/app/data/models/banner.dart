class Banner {
  Banner({
    required this.id,
    required this.title,
    required this.urlType,
    required this.url,
    required this.image,
  });

  int id;
  String title;
  String urlType;
  String url;
  String image;

  factory Banner.fromJson(Map<String, dynamic> json) => Banner(
        id: json['id'] as int,
        title: json['title'] as String,
        urlType: json['url_type'] as String,
        url: json['url'] as String,
        image: json['image'] as String,
      );
}
