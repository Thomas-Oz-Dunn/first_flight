
class Article {
  final int id;
  final String title;
  final String url;
  final String imageUrl;
  final String newsSite;
  final String summary;

// published_at*	[...]
// updated_at*	[...]
// featured	[...]
// launches*	[...]
// events*	[...]

  const Article({
    required this.id,
    required this.title,
    required this.url,
    required this.imageUrl,
    required this.newsSite,
    required this.summary,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'id': int id,
        'title': String title,
        'url': String url,
        'image_url': String imageUrl,
        'news_site': String newsSite,
        'summary': String summary,
      } =>
        Article(
          id: id,
          title: title,
          url: url,
          imageUrl: imageUrl,
          newsSite: newsSite,
          summary: summary,
        ),
      _ => throw const FormatException('Failed to load Article.'),
    };
  }
}