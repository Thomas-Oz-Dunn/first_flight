
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../mem/orbit.dart';

String celestrakSite = "https://celestrak.org/NORAD/elements/gp.php?";
String celestrakName = "NAME=";
String celestrakID = "CATNR=";
String celestrakIntDes = "INTDES=";

String celestrakJsonFormat = "&FORMAT=JSON";

Future<List<Orbit>> fetchOrbits(String url) async {
  final response = await http.get(Uri.parse(url));
  int nameIdx = url.indexOf('NAME=');
  int formatIdx = url.indexOf('&FORMAT');
  String name = url.substring(nameIdx + 5, formatIdx);

  if (response.statusCode == 200) {
    if (response.body.toString() == 'No GP data found') {
      throw Exception('No data found for $name');
    }

    Iterable iterable = json.decode(response.body);
    return List<Orbit>.from(
      iterable.map(
        (contents) {
          return Orbit.fromJson(contents);
        }
      )
    );

  } else {
    throw Exception('Failed to load orbits for $name');
  }
}


Future<List<Orbit>> queryCelestrakName(String name) {
  String query = celestrakSite + celestrakName + name + celestrakJsonFormat;
  return fetchOrbits(query);
}

Future<List<Orbit>> queryCelestrakID(String objectID) {
  String query = celestrakSite + celestrakIntDes + objectID + celestrakJsonFormat;
  return fetchOrbits(query);
}

