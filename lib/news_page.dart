import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';


class Article{
  final String id;
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

  factory Article.fromJson(dynamic json) {
    return switch (json) {
      {
        'id': String id,
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
      _ => throw const FormatException('Failed to load Orbit.'),
    };
  }
}

Future<List<Article>> querySpaceNews() async {
  String spaceFlightNews = "http://api.spaceflightnewsapi.net/v4/articles/";

  final response = await http.get(Uri.parse(spaceFlightNews));
      
  if (response.statusCode == 200) {
    Iterable l = json.decode(response.body);
    List<Article> articles = List<Article>.from(l.map((model) => Article.fromJson(model)));
    return articles;

  } else {
    throw Exception('Failed to load articles');
  }

}

var newsFeedBuilder = FutureBuilder<List<Article>>(
  future: futureArticles,
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      List<Article> articles = snapshot.data!;

      return ListView.builder(
        reverse: true,
        itemBuilder: (context, itemIdxs) {
    
          if (itemIdxs < articles.length) {
            var orbitTile = ListTile(
              onTap: () {
                // Open URL in browser
              },
              title: Text(articles[itemIdxs].title),
              subtitle: Text('Summary: ${articles[itemIdxs].summary}'),
            );
            return orbitTile;
          }
      }
    );

    } else if (snapshot.hasError) {
      return Text('${snapshot.error}');
    }
    return const CircularProgressIndicator();
  },
);