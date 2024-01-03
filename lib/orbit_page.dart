import 'package:first_flight/math.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:share_plus/share_plus.dart';
// import 'package:first_flight/src/rust/api/simple.dart';
import 'package:latlong2/latlong.dart';
import 'package:vector_math/vector_math_64.dart';

import 'sgp4.dart';

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

  String describe() {
    return '''
      Epoch Date Time: $epoch
      Mean Motion: $meanMotion
      Eccentricity: $eccentricity
      Inclination: $inc deg
      Ascending Node: $raan  deg
      Argument Perigee: $argPericenter deg
      Mean Anomaly: $meanAnom deg''';
  }

  factory Orbit.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'OBJECT_NAME': String objectName,
        'OBJECT_ID': String objectID,
        'EPOCH': String epoch,
        'MEAN_MOTION': double meanMotion,
        'ECCENTRICITY': double eccentricity,
        'INCLINATION': num inc,
        'RA_OF_ASC_NODE': num raan,
        'ARG_OF_PERICENTER': num argPericenter,
        'MEAN_ANOMALY': num meanAnom,
        'EPHEMERIS_TYPE': int ephemType,
        'CLASSIFICATION_TYPE': String classification,
        'NORAD_CAT_ID': int noradID,
        'ELEMENT_SET_NO': int elemSetNo,
        'REV_AT_EPOCH': int revNum,
        'BSTAR': num bStar,
        'MEAN_MOTION_DOT': num meanMotionDot,
        'MEAN_MOTION_DDOT': num meanMotionDdot,
      } =>
        Orbit(
          objectName: objectName,
          objectID: objectID,
          epoch: epoch,
          meanMotion: meanMotion,
          eccentricity: eccentricity,
          inc: inc.toDouble(),
          raan: raan.toDouble(),
          argPericenter: argPericenter.toDouble(),
          meanAnom: meanAnom.toDouble(),
          ephemType: ephemType,
          classification: classification,
          norad: noradID,
          elemSetNo: elemSetNo,
          revNum: revNum,
          bStar: bStar.toDouble(),
          meanMotionDot: meanMotionDot.toDouble(),
          meanMotionDdot: meanMotionDdot.toDouble(),
        ),
      _ => throw FormatException('Failed to load: $json'),
    };
  }
}

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

void addToNotifications(String name){
  // TODO-TD: Check if already receiving notification
  // TODO-TD: Send to FCM

}

List<(Vector2, DateTime)> calcAzEls(
  List<(Vector3, DateTime)> motion,
  LatLng observer,
){
  var obslla = Vector3(observer.latitude, observer.longitude, 0);
  List<(Vector3, DateTime)> ecefs = motion.map(
    (e) => (
      calcECItoECEFrotam(e.$2) * e.$1, e.$2)
    ) as List<(Vector3, DateTime)>;
  return ecefs.map((e) {
    Vector3 azelrad = enuToAzelrad(
      ecefToEnu(
      obslla, 
      e.$1
    )
    );
    (Vector2(azelrad.x, azelrad.y), e.$2);
    }
    ) as List<(Vector2, DateTime)>;
}


List<(LatLng, DateTime)> calcGroundTrack(
  List<(Vector3, DateTime)> motion,
){
  return motion.map((e) {
    var lla = ecefToLla(calcECItoECEFrotam(e.$2) * e.$1);
    return (LatLng(lla[0], lla[1]), e.$2);
  }) as List<(LatLng, DateTime)>;
  
}


List<(Vector3, DateTime)> calcMotion(
  Orbit orbit, 
  int searchMinutes, 
  DateTime now
) {
  // calcmotion
  KeplerianElements elems = KeplerianElements(
    epoch: orbit.epoch, 
    eccentricity: orbit.eccentricity, 
    meanMotion: orbit.meanMotion, 
    inclination: orbit.inc, 
    raan: orbit.raan, 
    meanAnomaly: orbit.meanAnom, 
    argPeri: orbit.argPericenter, 
    drag: orbit.bStar
  );
  
  SGP4 state = SGP4(elems, Earth.wgs84());
  
  List<(Vector3, DateTime)> motion = List<(Vector3, DateTime)>.generate(
    searchMinutes, (iMin) {
    DateTime time =now.add(Duration(minutes: iMin));
    return (state.getPositionByDateTime(time).pEci, time);
  });
  return motion;
}

class OrbitPage extends StatelessWidget {
  final Orbit orbit;

  const OrbitPage({super.key, required this.orbit});
  

  // Pass in Orbit object
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(orbit.objectName)),
      body: ListView(children: [
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
              Row(children: [
                IconButton(
                  onPressed: () {
                    Share.share('${orbit.objectName} ${orbit.describe()}');
                  }, 
                  icon: const Icon(Icons.share)
                ),
                IconButton(
                  onPressed: () => addToNotifications(orbit.objectName), 
                  icon: const Icon(Icons.notification_add)
                ),
              ],
            )
          ]
        ),
        const Divider(),
        const Text('Next Passes List: TODO'),
        const Divider(),
        const Text('Orbital Information'),
        Text(orbit.describe()),
      ]),
    );
  }
}


// List<LatLng, DateTime> LatLngTrajectory(
//   Orbit orbit, 
//   DateTime dateTime, 
//   double hrDuration
// ) {
//   var props = propagate_from_elements(

//   );
//   var p_lla = eci_to_llh(props);
//   return List<LatLng(p_lla[0], p_lla[1])>;
// }
