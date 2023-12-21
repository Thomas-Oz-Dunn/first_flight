import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';

class Orbit {
  final String objectName;
  final String objectID;
  final String epoch;
  final double meanMotion;
  // final double eccentricity; 
  // final double inc;
  // final double raan; 
  // final double argPericenter; 
  // final double meanAnom; 
  // final Int ephemType; 
  // final String classification; 
  // final Int norad; 
  // final Int elemSetNo; 
  // final Int revNum; 
  // final double bStar;
  // final double meanMotionDot; 
  // final double meanMotionDdot; 

  const Orbit({
    required this.objectName,
    required this.objectID,
    required this.epoch,
    required this.meanMotion,
    // required this.eccentricity,
    // required this.inc,
    // required this.raan,
    // required this.argPericenter,
    // required this.meanAnom,
    // required this.ephemType,
    // required this.classification,
    // required this.norad,
    // required this.elemSetNo,
    // required this.revNum,
    // required this.bStar,
    // required this.meanMotionDot,
    // required this.meanMotionDdot,
  });

  factory Orbit.fromJson(dynamic json) {
    return switch (json) {
      {
        'OBJECT_NAME': String objectName,
        'OBJECT_ID': String objectID,
        'EPOCH': String epoch,
        'MEAN_MOTION': double meanMotion, 
        // 'ECCENTRICITY': double eccentricity, 
        // 'INCLINATION': double inc, 
        // 'RA_OF_ASC_NODE': double raan, 
        // 'ARG_OF_PERICENTER': double argPericenter, 
        // 'MEAN_ANOMALY': double meanAnom, 
        // 'EPHEMERIS_TYPE': Int ephemType, 
        // 'CLASSIFICATION_TYPE': String classification, 
        // 'NORAD_CAT_ID': Int noradID, 
        // 'ELEMENT_SET_NO': Int elemSetNo, 
        // 'REV_AT_EPOCH': Int revNum, 
        // 'BSTAR': double bStar, 
        // 'MEAN_MOTION_DOT': double meanMotionDot, 
        // 'MEAN_MOTION_DDOT': double meanMotionDdot, 
      } =>
        Orbit(
          objectName: objectName,
          objectID: objectID,
          epoch: epoch,
          meanMotion: meanMotion,
          // eccentricity: eccentricity,
          // inc: inc,
          // raan: raan,
          // argPericenter: argPericenter,
          // meanAnom: meanAnom,
          // ephemType: ephemType,
          // classification: classification,
          // norad: noradID,
          // elemSetNo: elemSetNo,
          // revNum: revNum,
          // bStar: bStar,
          // meanMotionDot: meanMotionDot,
          // meanMotionDdot: meanMotionDdot,
        ),
      _ => throw const FormatException('Failed to load Orbit.'),
    };
  }
}

Future<List<Orbit>> fetchOrbits(String url) async  {
  final response = await http.get(Uri.parse(url));
      
  if (response.statusCode == 200) {
    Iterable l = json.decode(response.body);
    List<Orbit> orbits = List<Orbit>.from(l.map((model) => Orbit.fromJson(model)));
    return orbits;

  } else {
    throw Exception('Failed to load orbits');
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
      // TODO-TD: 3d picture
      body: ListView(
        children: [
          // TODO-TD: create button set
          const Text('Like, Share, Notify'),
          const Text('Next Passes: TODO'), 
          Text(
            'ID: ${orbit.objectID}\nEPOCH: ${orbit.epoch}\nMean Motion: ${orbit.meanMotion}'
          ),
        ]
      ),
    );
  }
}
