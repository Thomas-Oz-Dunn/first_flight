import 'package:vector_math/vector_math_64.dart';
import 'dart:math';

const RADIUS_EQUATOR = 6.378137e6; // m
const SURFACE_ECC = 0.08182;
const ROT_RATE = 7.2921150e-5;
const AXIAL_TILT = -23.439;
const J2000_DAY = 2451545.0;
const J2000_EARTH_MEAN_ANOMALY = 1.98627277778;
const EARTH_MEAN_ANOMALY_PER_JDAY = 0.00547555711;
const EARTH_AXIAL_TILT_PET_JDAY = 0.0000004;


Vector3 enuToAzelrad(Vector3 pEnu){
    var dis = pEnu.normalize();
    var az = atan2(pEnu[0], pEnu[1]);
    var el = asin(pEnu[2] / dis);
    return  Vector3(az, el, dis);
}


Matrix3 calcECItoECEFrotam(DateTime dateTime){ 
    var radPerDay = ROT_RATE * 60.0 * 60.0 * 24.0;
    var theta = radPerDay * datetimeToj2000days(dateTime);
    var rotam = Matrix3(
        cos(theta), sin(-theta), 0.0,
        sin(theta), cos(theta), 0.0,
        0.0, 0.0, 1.0
      );

    return rotam;
}

double datetimeToj2000days(DateTime dateTime){
    var year = dateTime.year;
    var month = dateTime.month;
    var day = dateTime.day;
    var hours = dateTime.hour;
    var minutes = dateTime.minute;
    var seconds = dateTime.second;
    var julianDay = dateToJulianDayNum(year, month, day);
    var siderealTime = (hours + (minutes + seconds / 60) / 60) / 24.0;
    var j2000Days = julianDay + siderealTime - J2000_DAY;
    return j2000Days;
}


double dateToJulianDayNum(
    int year,
    int month,
    int day
) {
    var delMonth = (month - 14) / 12; // Adjusts for jul & aug
    var julianDayNum = (1461 * (year + 4800 + delMonth))/4 
        + (367 * (month - 2 - 12 * (delMonth)))/12 
        - (3 * ((year + 4900 + delMonth) / 100))/4 
        + day - 32075;

    return julianDayNum;
}

Vector3 llhToEcef(Vector3 lla) {
    var radius = calcPrimeVertical(lla[0]);
    var x = (radius + lla[2]) * cos(lla[0]) * cos(lla[1]);
    var y = (radius + lla[2]) * cos(lla[0]) * sin(lla[1]);
    var z = ((1.0 - pow(SURFACE_ECC,2)) * radius + lla[2]) * sin(lla[0]);
    var xyz = Vector3(x, y, z); 
    return xyz;
}

double calcPrimeVertical(double latDeg) {
    var latRadians = pi * latDeg / 180.0;
    var radScale = sqrt((1.0 - pow((SURFACE_ECC * sin(latRadians)),2)));
    var radius = RADIUS_EQUATOR / radScale;
    return radius;
}
