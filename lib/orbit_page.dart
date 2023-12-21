import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';

class Orbit {
  final String objectName;
  final String objectID;
  final String epoch;
  final double meanMotion;
  final double eccentricity; 
  final double inc;
  final double raan; 
  final double argPericenter; 
  final double meanAnom; 
  final int ephemType; 
  final String classification; 
  final int norad; 
  final int elemSetNo; 
  final int revNum; 
  final double bStar;
  final double meanMotionDot; 
  final double meanMotionDdot; 

  const Orbit({
    required this.objectName,
    required this.objectID,
    required this.epoch,
    required this.meanMotion,
    required this.eccentricity,
    required this.inc,
    required this.raan,
    required this.argPericenter,
    required this.meanAnom,
    required this.ephemType,
    required this.classification,
    required this.norad,
    required this.elemSetNo,
    required this.revNum,
    required this.bStar,
    required this.meanMotionDot,
    required this.meanMotionDdot,
  });

  String describe(){
    return '''
      Epoch Date Time: $epoch
      Mean Motion: $meanMotion
      Eccentricity: $eccentricity
      Inclination: $inc deg
      Ascending Node: $raan  deg
      Argument Perigee: $argPericenter deg
      meanAnom: $meanAnom deg'''; 
  }

  factory Orbit.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'OBJECT_NAME': String objectName,
        'OBJECT_ID': String objectID,
        'EPOCH': String epoch,
        'MEAN_MOTION': double meanMotion, 
        'ECCENTRICITY': double eccentricity, 
        'INCLINATION': double inc, 
        'RA_OF_ASC_NODE': double raan, 
        'ARG_OF_PERICENTER': double argPericenter, 
        'MEAN_ANOMALY': double meanAnom, 
        'EPHEMERIS_TYPE': int ephemType, 
        'CLASSIFICATION_TYPE': String classification, 
        'NORAD_CAT_ID': int noradID, 
        'ELEMENT_SET_NO': int elemSetNo, 
        'REV_AT_EPOCH': int revNum, 
        'BSTAR': double bStar, 
        'MEAN_MOTION_DOT': double meanMotionDot, 
        'MEAN_MOTION_DDOT': double meanMotionDdot, 
      } =>
        Orbit(
          objectName: objectName,
          objectID: objectID,
          epoch: epoch,
          meanMotion: meanMotion,
          eccentricity: eccentricity,
          inc: inc,
          raan: raan,
          argPericenter: argPericenter,
          meanAnom: meanAnom,
          ephemType: ephemType,
          classification: classification,
          norad: noradID,
          elemSetNo: elemSetNo,
          revNum: revNum,
          bStar: bStar,
          meanMotionDot: meanMotionDot,
          meanMotionDdot: meanMotionDdot,
        ),
      _ => throw const FormatException('Failed to load Orbit.'),
    };
  }
}

Future<List<Orbit>> fetchOrbits(String url) async {
  final response = await http.get(Uri.parse(url));
      int nameIdx = url.indexOf('NAME=');
      int formatIdx = url.indexOf('&FORMAT');
      String name = url.substring(nameIdx+5, formatIdx);
      
  if (response.statusCode == 200) {
    if (response.body.toString() == 'No GP data found'){
      throw Exception('No data found for $name');
    }
    
    Iterable iterable = json.decode(response.body);
    List<Orbit> orbits = List<Orbit>.from(
      iterable.map((contents) {
        return Orbit.fromJson(contents);
      })
    );

    return orbits;

  } else {
    throw Exception('Failed to load orbits for $name');
  }
}


class OrbitPage extends StatelessWidget {
  final Orbit orbit;

  const OrbitPage({super.key, required this.orbit});

  // Pass in Orbit object
  @override
  Widget build(BuildContext context){

    return Scaffold(
      appBar: AppBar(title: Text(orbit.objectName)),
      body: ListView(
        children: [
          const Divider(),
          const Text('TODO-TD: Picture'),
          const Divider(),
          const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [Text('TODO-TD: Favorite, Share, Notify Buttons')]
          ),
          const Divider(),
          const Text('Next Passes List: TODO'), 
          const Divider(),
          const Text('Orbital Information'),
          Text(orbit.describe()),
        ]
      ),
    );
  }
}
