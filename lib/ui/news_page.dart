import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'package:first_flight/mem/Article.dart';
import 'package:first_flight/web/news.dart';


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
