import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

int newsDays = 2;

class Article{
  final int id;
  final String title;
  final String url;
  final String image_url;
  final String news_site;
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
    required this.image_url,
    required this.news_site,
    required this.summary,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'id': int id,
        'title': String title, 
        'url': String url, 
        'image_url': String image_url, 
        'news_site': String news_site, 
        'summary': String summary, 
      } =>
        Article(
          id: id,
          title: title,
          url: url,
          image_url: image_url,
          news_site: news_site,
          summary: summary,
        ),
      _ => throw const FormatException('Failed to load Article.'),
    };
  }
}

Future<List<Article>> querySpaceNews() async {
  // Show me everything since yesterday
  // TODO-TD: toggle look back time
  String spaceFlightNews = "http://api.spaceflightnewsapi.net/v4/articles/?published_at_gte=";
  final now = DateTime.now();
  final past = '${now.year.toString()}-${now.month.toString()}-${(now.day-newsDays).toString()}';
  final response = await http.get(Uri.parse(spaceFlightNews + past));
      
  if (response.statusCode == 200) {
    Map<String, dynamic> decoded = json.decode(response.body) as Map<String, dynamic>;
    if (decoded.containsKey("results")){
      Iterable res = decoded["results"];
      List<Article> articles = List<Article>.from(
        res.map((jsonArticle) => Article.fromJson(jsonArticle))
      );
      return articles;

    } else {
    throw Exception('No results section');
    }
  } else {
    throw Exception('Failed to load articles');
  }

}

Future<void> _launchUrl(String _url) async {
  if (!await launchUrl(Uri.parse(_url))) {
    throw Exception('Could not launch $_url');
  }
}
var newsFeedBuilder = FutureBuilder<List<Article>>(
  future: querySpaceNews(),
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

            if (summary.length > ellipseCharStart){
              summary = summary.replaceRange(
                ellipseCharStart, 
                summary.length, 
                '...'
              );
            }

            var newsTile = ListTile(
              contentPadding: EdgeInsets.symmetric(vertical: 8),
              leading: ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: 50,
                  minHeight: 50,
                  maxWidth: 100,
                  maxHeight: 100,
                ),
                child: Image.network(article.image_url, fit: BoxFit.cover),
              ),
              onTap: () {_launchUrl(article.url);},
              title: Text(
                article.title,
                style: TextStyle(fontWeight: FontWeight.bold,)
              ),
              subtitle: Text('$summary\nSource: ${article.news_site}'),
              trailing: IconButton(
                icon: Icon(Icons.ios_share), 
                onPressed: () {
                  Share.share('${article.news_site}: ${article.title} ${article.url}');
              },
              ),
              // TODO-TD: link related satellites to each article

            );
            return newsTile;
          }
      }
    );

    } else if (snapshot.hasError) {
      return Text('${snapshot.error}');
    }
    return const CircularProgressIndicator();
  },
);