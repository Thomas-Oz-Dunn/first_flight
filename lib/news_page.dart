import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

Future<List<Article>> querySpaceFlightNews(int daysBack) async {
  String spaceFlightNews =
      "http://api.spaceflightnewsapi.net/v4/articles/?published_at_gte=";

  final today = DateTime.now();
  var yearString = today.year.toString();
  var monthString = today.month.toString();
  var dayString = (today.day - daysBack).toString();
  final newsDay = '$yearString-$monthString-$dayString';
  final response = await http.get(Uri.parse(spaceFlightNews + newsDay));

  if (response.statusCode == 200) {
    Map<String, dynamic> decoded =
        json.decode(response.body) as Map<String, dynamic>;
    if (decoded.containsKey("results")) {
      Iterable res = decoded["results"];
      List<Article> articles = List<Article>.from(
          res.map((jsonArticle) => Article.fromJson(jsonArticle)));
      return articles;
    } else {
      throw Exception('No results section');
    }
  } else {
    throw Exception('Failed to load articles');
  }
}

Future<void> _launchUrl(String url) async {
  if (!await launchUrl(Uri.parse(url))) {
    throw Exception('Could not launch $url');
  }
}

class NewsPage extends StatefulWidget {
  const NewsPage({super.key});

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  late Future<List<Article>> futureArticles;
  int daysBack = 1;

  @override
  void initState() {
    futureArticles = querySpaceFlightNews(daysBack);
    super.initState();
  }

  @override
  Widget build(context) {
    var newsFeedBuilder = FutureBuilder<List<Article>>(
      future: querySpaceFlightNews(daysBack),
      builder: (context, snapshot) {
        int ellipseCharStart = 200;

        if (snapshot.hasData) {
          List<Article> articles = snapshot.data!;
          return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              itemBuilder: (context, itemIdxs) {
                if (itemIdxs < articles.length) {
                  Article article = articles[itemIdxs];
                  String summary = article.summary;
                  String title = article.title;
                  String newsSite = article.newsSite;

                  if (summary.length > ellipseCharStart) {
                    summary = summary.replaceRange(
                        ellipseCharStart, summary.length, '...');
                  }

                  var newsTile = ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    leading: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: 50,
                        minHeight: 50,
                        maxWidth: 100,
                        maxHeight: 100,
                      ),
                      child: Image.network(article.imageUrl, fit: BoxFit.cover),
                    ),
                    onTap: () {
                      _launchUrl(article.url);
                    },
                    title: Text(title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        )),
                    subtitle: Text('$summary\nSource: $newsSite'),
                    trailing: IconButton(
                      icon: const Icon(Icons.share),
                      onPressed: () {
                        Share.share('$newsSite: $title ${article.url}');
                      },
                    ),
                  );
                  return newsTile;
                }
              }
            );
        } else if (snapshot.hasError) {
          return Text('${snapshot.error}');
        }

        return const Center(child: CircularProgressIndicator());
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("What's new"),
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: newsFeedBuilder,
      )
    );
  }
}
