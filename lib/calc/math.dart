import 'package:vector_math/vector_math_64.dart';
import 'dart:math';

const RADIUS_EQUATOR = 6.378137e6; // m
const SURFACE_ECC = 0.08182;
const ROT_RATE = 7.2921150e-5;
const AXIAL_TILT = -23.439;
const j2000Day = 2451545.0;
const j2000EarthMeanAnomaly = 1.98627277778;
const earthMeanAnomalyPerJday = 0.00547555711;

const double earthAxialTiltPerJday = 0.0000004;
const double twoPi = pi * 2;
const double degToRad = pi / 180.0;
const double _xpdotp = 1440.0 / twoPi; // 229.1831180523293;
const double secPerHour = 3600;
const double zeroTol = 1.5e-12;

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
    var j2000Days = julianDay + siderealTime - j2000Day;
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


bool isEclipsedByEarth(
    Vector3 pEci,
    DateTime dateTime,
){  
    var j2000Days = datetimeToj2000days(dateTime);
    var sunEci = calcSunNormEciVec(j2000Days);
    var beta = asin(dot3(sunEci, pEci));
    var betaEclipse = pi - asin((RADIUS_EQUATOR / pEci.normalize()));
    return beta > betaEclipse;
}


Vector3 calcSunNormEciVec(double j2000Days){
    double meanLonDeg = 280.460 + 0.98560028 * j2000Days;
    double meanAnom = j2000EarthMeanAnomaly + earthMeanAnomalyPerJday * j2000Days;
    double u1deg = 1.9148 * sin(meanAnom);
    double u2deg = 0.02 * sin(2.0 * meanAnom);
    double eclipticLon = (meanLonDeg + u1deg + u2deg) * pi / 180.0;
    double obliquity = -(AXIAL_TILT + earthAxialTiltPerJday * j2000Days);
    double ecixnorm = cos(eclipticLon);
    double eciynorm = sin(eclipticLon) * cos(obliquity);
    double eciznorm = sin(eclipticLon) * sin(obliquity);

    return Vector3(ecixnorm, eciynorm, eciznorm);
}

Vector3 ecefToLla(Vector3 ecef){
    // Zhu's method
    double a = RADIUS_EQUATOR;
    double b = RADIUS_EQUATOR * sqrt((1.0 - pow(SURFACE_ECC, 2)));
    double ecc2 = (pow(a, 2) - pow(b,2)) / pow(a,2);
    double ecc_2Prime = pow(a,2) / pow(b,2) - 1.0;
    double x = ecef[0] / 1000.0;
    double y = ecef[1] / 1000.0;
    double z = ecef[2] / 1000.0;
    double p = sqrt((pow(x,2) + pow(y,2)));
    double g = pow(p,2) + (1.0 - ecc2) * pow(z,2) - ecc2 * (pow(a,2) - pow(b,2));
    double f = 54.0 * pow(b,2) * pow(z,2);
    double c = pow(ecc2,2) * f * pow(p,2) / (pow(g,3));
    num s = pow(1.0 + c + sqrt((pow(c,2) + 2.0 * c)) , (1.0 / 3.0));
    double P = f / (3.0 * pow((s + 1.0 + 1.0 / s),2) * pow(g,2));
    double q = sqrt((1.0 + 2.0 * pow(ecc2,2) * P));
    double r_0_2_1 = (pow(a,2)/2.0) * (1.0 + 1.0 / q);
    double r_0_2_2 = (1.0 - ecc2) * pow(z,2) / (q * (1.0 + q)) - (pow(p,2)/2.0);
    double r_0_2 = r_0_2_1 - P * r_0_2_2;
    double r_0 = - P * ecc2 * p /(1.0 + q) + sqrt((r_0_2));
    double u = sqrt((pow((p - (ecc2 * r_0)),2) + pow(z,2)));
    double v = sqrt((pow((p - (ecc2 * r_0)),2) + (1.0 - ecc2) * pow(z,2)));
    double z_0 = pow(b,2) * z / (a * v);
    double lat = atan2((z + ecc_2Prime * z_0),p) * 180.0 / pi;
    double lon =  atan2(y,x) * 180.0 / pi;
    double alt = u * (1.0 - pow(b,2) / (a * v));

    return Vector3(lat, lon, alt);
}


Vector3 ecefToEnu(
    Vector3 pLla, 
    Vector3 pTgtEcef
) {
    var observerEcef = llhToEcef(pLla);
    var vecEcef = pTgtEcef - observerEcef;
    var ecefToEnu = Matrix3(
        -sin(pLla[1]), cos(pLla[1]), 0.0,
        -cos(pLla[1])*sin(pLla[0]), -sin(pLla[1])*sin(pLla[0]), cos(pLla[0]),
        cos(pLla[1])*cos(pLla[0]), sin(pLla[1])*cos(pLla[0]), sin(pLla[0]));
    return ecefToEnu * vecEcef;
}


