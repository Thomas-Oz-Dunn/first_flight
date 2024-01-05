
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
