import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:first_flight/mem/Article.dart';


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
