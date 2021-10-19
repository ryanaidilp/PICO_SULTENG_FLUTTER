class Article {
  const Article({
    required this.title,
    required this.author,
    required this.description,
    required this.url,
    required this.cover,
    required this.publishedAt,
    required this.content,
    required this.source,
  });

  final String title;
  final String author;
  final String description;
  final String url;
  final String cover;
  final DateTime publishedAt;
  final String content;
  final String source;

  factory Article.fromJson(Map<String, dynamic> json) => Article(
        title: json['title'] as String,
        author: json['author'] as String,
        description: json['description'] as String,
        content: json['content'] as String,
        publishedAt: DateTime.parse(json['publishedAt'] as String).toLocal(),
        url: json['url'] as String,
        cover: json['urlToImage'] as String,
        source: json['source']['name'] as String,
      );
}
