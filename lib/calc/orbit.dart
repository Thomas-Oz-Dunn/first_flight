
import 'package:latlong2/latlong.dart';
import 'package:vector_math/vector_math_64.dart';

import 'math.dart';
import 'sgp4.dart';
import '../mem/orbit.dart';

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
  // Convert epoch into doublwe
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
