// lib/models/news_model.dart
class Article {
  final String title;
  final String description;
  final String url;
  final String? urlToImage;
  final String? publishedAt;
  final String? sourceName;

  Article({
    required this.title,
    required this.description,
    required this.url,
    this.urlToImage,
    this.publishedAt,
    this.sourceName,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      title: json['title'] ?? 'Tiêu đề không có sẵn',
      description: json['description'] ?? 'Không có mô tả',
      url: json['url'] ?? '',
      urlToImage: json['urlToImage'],
      publishedAt: json['publishedAt'],
      sourceName:
          json['source'] != null ? json['source']['name'] : 'Nguồn không rõ',
    );
  }
}
