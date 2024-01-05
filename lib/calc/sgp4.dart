import 'dart:math';
import 'package:vector_math/vector_math_64.dart';

import 'math.dart';

class OrbitalState {
  const OrbitalState(this.pEci, this.vEci);
  final Vector3 pEci;
  final Vector3 vEci;
}

class KeplerianElements {
  const KeplerianElements({
    required this.epoch,
    required this.eccentricity,
    required this.meanMotion,
    required this.inclination,
    required this.raan,
    required this.meanAnomaly,
    required this.argPeri,
    required this.drag,
  });

  final double epoch;
  final double eccentricity;
  final double meanMotion;
  final double inclination;
  final double raan;
  final double meanAnomaly;
  final double argPeri;
  final double drag;

  /// Calculates minutes past epoch.
  double getMinutesPastEpoch(DateTime utc) {
    int year = epoch ~/ 1000.0;
    final doy = epoch - (year * 1000.0);

    year += year > 57 ? 1900 : 2000;
    final j = _julian(year, doy);
    final epch = julian(j);

    return utc.difference(epch).inMilliseconds / 60000.0;
  }
}

abstract class Planet {
  const Planet({
    required this.radiusKm,
    required this.mu,
    required this.j2,
    required this.j3,
    required this.j4,
    required this.flattening,
  });

  final double radiusKm;
  final double mu;
  final double j2;
  final double j3;
  final double j4;
  final double flattening;
}

class Earth extends Planet {
  const Earth._({
    required double radius,
    required double mu,
    required double j2,
    required double j3,
    required double j4,
    required double flattening,
  }) : super(
    radiusKm: radius,
    mu: mu,
    j2: j2,
    j3: j3,
    j4: j4,
    flattening: flattening,
  );

  factory Earth.wgs72() => _wgs72;
  factory Earth.wgs84() => _wgs84;

  static const _wgs72 = Earth._(
    radius: 6378.135,
    mu: 398600.8,
    j2: 0.0010826162,
    j3: -0.00000253881,
    j4: -0.00000165597,
    flattening: 1 / 298.26,
  );

  static const _wgs84 = Earth._(
    radius: 6378.137,
    mu: 398600.5,
    j2: 0.00108262998905,
    j3: -0.00000253215306,
    j4: -0.00000161098761,
    flattening: 1 / 298.257223563,
  );
}

class DeepSpaceLongPeriodPeriodicContributions {

  const DeepSpaceLongPeriodPeriodicContributions({
    required this.eccPeriodic,
    required this.incPeriodic,
    required this.raanPeriodic,
    required this.argpPeriodic,
    required this.meanAnomPeriodic,
  });

  final double eccPeriodic;
  final double incPeriodic;
  final double raanPeriodic;
  final double argpPeriodic;
  final double meanAnomPeriodic;
}

class SGP4 {
  SGP4(this.keplerianElements, this.planet) {
    meanMotion0 = keplerianElements.meanMotion / _xpdotp;
    bstar = keplerianElements.drag;

    incO = keplerianElements.inclination * degToRad;
    raan0 = keplerianElements.raan * degToRad;
    argp0 = keplerianElements.argPeri * degToRad;
    meanAnom0 = keplerianElements.meanAnomaly * degToRad;
    ecc0 = keplerianElements.eccentricity;

    var year = keplerianElements.epoch ~/ 1000.0;
    var doy = keplerianElements.epoch - (year * 1000);

    year += year < 57 ? 2000 : 1900;

    var julianDay = _julian(year, doy);
    double epoch = julianDay - 2433281.5;

    var earthRadius = planet.radiusKm;
    var j2 = planet.j2;
    var j3 = planet.j3;
    var j4 = planet.j4;

    var j3oj2 = j3 / j2;

    _operationmode = _OpsMode.i;
    _method = _Method.n;

    var ss = (78.0 / earthRadius) + 1.0;
    // Multiply for speed instead of pow
    var qzms2ttemp = (120.0 - 78.0) / earthRadius;
    var qzms2t = qzms2ttemp * qzms2ttemp * qzms2ttemp * qzms2ttemp;

    var t = 0.0;

    var initlResult = _initialize(
        planet: planet,
        ecc0: ecc0,
        epoch: epoch,
        inc0: incO,
        meanMotion0: meanMotion0,
        opsmode: _operationmode
      );

    var ao = initlResult.semiMajor0;
    var con42 = initlResult.con42;
    var cosInc0 = initlResult.cosInc0;
    var cosInc0sq = initlResult.cosInc0sqr;
    var eccSq = initlResult.eccSq;
    var omeosq = initlResult.omeosq;
    var p0Sqr = initlResult.p0Sqr;
    var rPerigee = initlResult.rp;
    var rteosq = initlResult.rteosq;
    var sinInc0 = initlResult.sinInc0;

    meanMotion0 = initlResult.meanMotion0;
    con41 = initlResult.con41;
    gsto = initlResult.gsto;

    if (omeosq >= 0.0 || meanMotion0 >= 0.0) {
      isimp = 0;
      if (rPerigee < ((220.0 / earthRadius) + 1.0)) {
        isimp = 1;
      }
      var sfour = ss;
      var qzms24 = qzms2t;
      var perigee = (rPerigee - 1.0) * earthRadius;

      // - for perigees below 156 km, s and qoms2t are altered -
      if (perigee < 156.0) {
        sfour = perigee - 78.0;
        if (perigee < 98.0) {
          sfour = 20.0;
        }
        var qzms24temp = (120.0 - sfour) / earthRadius;
        qzms24 = qzms24temp * qzms24temp * qzms24temp * qzms24temp;
        sfour = (sfour / earthRadius) + 1.0;
      }
      var pinvsq = 1.0 / p0Sqr;

      var tsi = 1.0 / (ao - sfour);
      eta = ao * ecc0 * tsi;
      var etaSqr = eta * eta;
      var eeta = ecc0 * eta;
      var psisq = (1.0 - etaSqr).abs();
      var coef = qzms24 * (tsi * tsi * tsi * tsi);
      var coef1 = coef / pow(psisq, 3.5);
      var cc2 = coef1 * meanMotion0 *
          ((ao * (1.0 + (1.5 * etaSqr) + (eeta * (4.0 + etaSqr)))) +
              (0.375 * j2 * tsi / psisq * con41 *
                  (8.0 + (3.0 * etaSqr * (8.0 + etaSqr)))));
      cc1 = bstar * cc2;
      var cc3 = 0.0;
      if (ecc0 > 1.0e-4) {
        cc3 = -2.0 * coef * tsi * j3oj2 * meanMotion0 * sinInc0 / ecc0;
      }
      x1mth2 = 1.0 - cosInc0sq;
      cc4 = 2.0 * meanMotion0 * coef1 * ao * omeosq *
          ((eta * (2.0 + (0.5 * etaSqr))) +
              (ecc0 * (0.5 + (2.0 * etaSqr))) -
              (j2 * tsi / (ao * psisq) * ((-3.0 * con41 *
                  (1.0 - (2.0 * eeta) +  (etaSqr * (1.5 - (0.5 * eeta))))) +
          (0.75 * x1mth2 * ((2.0 * etaSqr) - (eeta * (1.0 + etaSqr))) * cos(2.0 * argp0)))));
      
      cc5 = 2.0 * coef1 * ao * omeosq * (1.0 + (2.75 * (etaSqr + eeta)) + (eeta * etaSqr));
      var cosio4 = cosInc0sq * cosInc0sq;
      var temp1 = 1.5 * j2 * pinvsq * meanMotion0;
      var temp2 = 0.5 * temp1 * j2 * pinvsq;
      var temp3 = -0.46875 * j4 * pinvsq * pinvsq * meanMotion0;
      meanMotionDot = meanMotion0 +
          (0.5 * temp1 * rteosq * con41) +
          (0.0625 * temp2 * rteosq * (13.0 - (78.0 * cosInc0sq) + (137.0 * cosio4)));
      argpDot = (-0.5 * temp1 * con42) +
          (0.0625 * temp2 * (7.0 - (114.0 * cosInc0sq) + (395.0 * cosio4))) +
          (temp3 * (3.0 - (36.0 * cosInc0sq) + (49.0 * cosio4)));
      var xhdot1 = -temp1 * cosInc0;
      raanDot = xhdot1 +
          (((0.5 * temp2 * (4.0 - (19.0 * cosInc0sq))) +
                  (2.0 * temp3 * (3.0 - (7.0 * cosInc0sq)))) * cosInc0);
      var xpidot = argpDot + raanDot;
      omgcof = bstar * cc3 * cos(argp0);
      xmcof = 0.0;
      if (ecc0 > 1.0e-4) {
        xmcof = -2.0 /3.0 * coef * bstar / eeta;
      }
      nodecf = 3.5 * omeosq * xhdot1 * cc1;
      t2cof = 1.5 * cc1;

      // Divide by zero with cosInc0 = 180 deg
      xlcof = (cosInc0 + 1.0).abs() > zeroTol
          ? -0.25 * j3oj2 * sinInc0 * (3.0 + (5.0 * cosInc0)) / (1.0 + cosInc0)
          : -0.25 * j3oj2 * sinInc0 * (3.0 + (5.0 * cosInc0)) / zeroTol;
      aycof = -0.5 * j3oj2 * sinInc0;

      // Use multiply for speed instead of pow
      var delmotemp = 1.0 + (eta * cos(meanAnom0));
      delMeanAnom = delmotemp * delmotemp * delmotemp;
      sinMeanAnom0 = sin(meanAnom0);
      x7thm1 = (7.0 * cosInc0sq) - 1.0;

      // --------------- deep space initialization -------------
      if (twoPi / meanMotion0 >= 225.0) {
        _method = _Method.d;
        isimp = 1;
        var tc = 0.0;
        var inclm = incO;

        var dscomr = DeepSpaceCommon.calculate(
            epoch: epoch,
            ep: ecc0,
            argpp: argp0,
            tc: tc,
            inclp: incO,
            raanp: raan0,
            np: meanMotion0);

        e3 = dscomr.e3;
        ee2 = dscomr.ee2;
        peo = dscomr.peo;
        pgho = dscomr.pgho;
        pho = dscomr.pho;
        pinco = dscomr.pinco;
        plo = dscomr.plo;
        se2 = dscomr.se2;
        se3 = dscomr.se3;
        sgh2 = dscomr.sgh2;
        sgh3 = dscomr.sgh3;
        sgh4 = dscomr.sgh4;
        sh2 = dscomr.sh2;
        sh3 = dscomr.sh3;
        si2 = dscomr.si2;
        si3 = dscomr.si3;
        sl2 = dscomr.sl2;
        sl3 = dscomr.sl3;
        sl4 = dscomr.sl4;
        xgh2 = dscomr.xgh2;
        xgh3 = dscomr.xgh3;
        xgh4 = dscomr.xgh4;
        xh2 = dscomr.xh2;
        xh3 = dscomr.xh3;
        xi2 = dscomr.xi2;
        xi3 = dscomr.xi3;
        xl2 = dscomr.xl2;
        xl3 = dscomr.xl3;
        xl4 = dscomr.xl4;
        zmol = dscomr.zmol;
        zmos = dscomr.zmos;

        var sinim = dscomr.sinim;
        var cosim = dscomr.cosim;
        var em = dscomr.em;
        var emsq = dscomr.emsq;
        var s1 = dscomr.s1;
        var s2 = dscomr.s2;
        var s3 = dscomr.s3;
        var s4 = dscomr.s4;
        var s5 = dscomr.s5;
        var ss1 = dscomr.ss1;
        var ss2 = dscomr.ss2;
        var ss3 = dscomr.ss3;
        var ss4 = dscomr.ss4;
        var ss5 = dscomr.ss5;
        var sz1 = dscomr.sz1;
        var sz3 = dscomr.sz3;
        var sz11 = dscomr.sz11;
        var sz13 = dscomr.sz13;
        var sz21 = dscomr.sz21;
        var sz23 = dscomr.sz23;
        var sz31 = dscomr.sz31;
        var sz33 = dscomr.sz33;

        var nm = dscomr.nm;
        var z1 = dscomr.z1;
        var z3 = dscomr.z3;
        var z11 = dscomr.z11;
        var z13 = dscomr.z13;
        var z21 = dscomr.z21;
        var z23 = dscomr.z23;
        var z31 = dscomr.z31;
        var z33 = dscomr.z33;

        var dpperResult = _dpper(
            time: t,
            init: true,
            eccPeriodic: ecc0,
            incLPeriodic: incO,
            raanPeriodic: raan0,
            argpPeriodic: argp0,
            meanAnomPeriodic: meanAnom0,
            opsmode: _operationmode
          );

        ecc0 = dpperResult.eccPeriodic;
        incO = dpperResult.incPeriodic;
        raan0 = dpperResult.raanPeriodic;
        argp0 = dpperResult.argpPeriodic;
        meanAnom0 = dpperResult.meanAnomPeriodic;

        var argpMean = 0.0;
        var raanMean = 0.0;
        var meanMotionMean = 0.0;

        var dsinitResult = _deepSpaceInit(
            planet: planet,
            cosim: cosim,
            emsq: emsq,
            argp0: argp0,
            s1: s1,
            s2: s2,
            s3: s3,
            s4: s4,
            s5: s5,
            sinim: sinim,
            ss1: ss1,
            ss2: ss2,
            ss3: ss3,
            ss4: ss4,
            ss5: ss5,
            sz1: sz1,
            sz3: sz3,
            sz11: sz11,
            sz13: sz13,
            sz21: sz21,
            sz23: sz23,
            sz31: sz31,
            sz33: sz33,
            t: t,
            tc: tc,
            gsto: gsto,
            mo: meanAnom0,
            mdot: meanMotionDot,
            no: meanMotion0,
            nodeo: raan0,
            nodedot: raanDot,
            xpidot: xpidot,
            z1: z1,
            z3: z3,
            z11: z11,
            z13: z13,
            z21: z21,
            z23: z23,
            z31: z31,
            z33: z33,
            ecco: ecc0,
            eccsq: eccSq,
            em: em,
            argpm: argpMean,
            inclm: inclm,
            mm: meanMotionMean,
            nm: nm,
            nodem: raanMean,
            irez: irez,
            atime: atime,
            d2201: d2201,
            d2211: d2211,
            d3210: d3210,
            d3222: d3222,
            d4410: d4410,
            d4422: d4422,
            d5220: d5220,
            d5232: d5232,
            d5421: d5421,
            d5433: d5433,
            dedt: dedt,
            didt: didt,
            dmdt: dmdt,
            dnodt: dnodt,
            domdt: domdt,
            del1: del1,
            del2: del2,
            del3: del3,
            xfact: xfact,
            xlamo: xlamo,
            xli: xli,
            xni: xni);

        irez = dsinitResult.irez;
        atime = dsinitResult.atime;
        d2201 = dsinitResult.d2201;
        d2211 = dsinitResult.d2211;

        d3210 = dsinitResult.d3210;
        d3222 = dsinitResult.d3222;
        d4410 = dsinitResult.d4410;
        d4422 = dsinitResult.d4422;
        d5220 = dsinitResult.d5220;

        d5232 = dsinitResult.d5232;
        d5421 = dsinitResult.d5421;
        d5433 = dsinitResult.d5433;
        dedt = dsinitResult.dedt;
        didt = dsinitResult.didt;

        dmdt = dsinitResult.dmdt;
        dnodt = dsinitResult.dnodt;
        domdt = dsinitResult.domdt;
        del1 = dsinitResult.del1;

        del2 = dsinitResult.del2;
        del3 = dsinitResult.del3;
        xfact = dsinitResult.xfact;
        xlamo = dsinitResult.xlamo;
        xli = dsinitResult.xli;

        xni = dsinitResult.xni;
      }

      // ----------- set variables if not deep space -----------
      if (isimp != 1) {
        var cc1sq = cc1 * cc1;
        d2 = 4.0 * ao * tsi * cc1sq;
        var temp = d2 * tsi * cc1 / 3.0;
        d3 = ((17.0 * ao) + sfour) * temp;
        d4 = 0.5 * temp * ao * tsi * ((221.0 * ao) + (31.0 * sfour)) * cc1;
        t3cof = d2 + (2.0 * cc1sq);
        t4cof = 0.25 * ((3.0 * d3) + (cc1 * ((12.0 * d2) + (10.0 * cc1sq))));
        t5cof = 0.2 *
            ((3.0 * d4) + (12.0 * cc1 * d3) + (6.0 * d2 * d2) +
              (15.0 * cc1sq * ((2.0 * d2) + cc1sq)));
      }

      /* finally propogate to zero epoch to initialize all others. */
      // sgp4fix take out check to let satellites process until they are actually below earth surface
      // if(this.error == 0)
    }
  }

  final KeplerianElements keplerianElements;
  final Planet planet;
  late final _Method _method;
  late final double aycof;
  late final double con41;
  late final double cc1;
  late final double cc4;
  late final int isimp;
  late final double cc5;
  late final double d2;
  late final double d3;
  late final double d4;
  late final double delMeanAnom;
  late final double eta;
  late final double sinMeanAnom0;
  late final double argpDot;
  late final double omgcof;
  late final double x1mth2;
  late final double xlcof;
  late final double x7thm1;
  late final double t2cof;
  late final double t3cof;
  late final double t4cof;
  late final double t5cof;
  late final double meanMotionDot;
  late final double raanDot;
  late final double xmcof;
  late final double nodecf;
  late final int irez;
  late final _OpsMode _operationmode;
  late final double ecc0;
  late final double meanMotion0;
  late final double gsto;
  late final double d2201;
  late final double d2211;
  late final double d3210;
  late final double d3222;
  late final double d4410;
  late final double d4422;
  late final double d5220;
  late final double d5232;
  late final double d5421;
  late final double d5433;
  late final double dedt;
  late final double del1;
  late final double del2;
  late final double del3;
  late final double didt;
  late final double dmdt;
  late final double dnodt;
  late final double domdt;
  late final double e3;
  late final double ee2;
  late final double peo;
  late final double pgho;
  late final double pho;
  late final double pinco;
  late final double plo;
  late final double se2;
  late final double se3;
  late final double sgh2;
  late final double sgh3;
  late final double sgh4;
  late final double sh2;
  late final double sh3;
  late final double si2;
  late final double si3;
  late final double sl2;
  late final double sl3;
  late final double sl4;
  late final double xfact;
  late final double xgh2;
  late final double xgh3;
  late final double xgh4;
  late final double xh2;
  late final double xh3;
  late final double xi2;
  late final double xi3;
  late final double xl2;
  late final double zmol;
  late final double zmos;
  late final double xlamo;
  late final double atime;
  late final double xli;
  late final double xni;
  late final double xl4;
  late final double bstar;
  late final double argp0;
  late final double incO;
  late final double meanAnom0;
  late final double raan0;
  late final double xl3;

// Deep space long period periodic contributions to the mean elements.
// by design, these periodics are zero at epoch.
// 
// outputs       :
// ep          - eccentricity                           0.0 - 1.0
// inclp       - inclination
// raanp        - right ascension of ascending node
// argpp       - argument of perigee
// mp          - mean anomaly
// 
// references    :
// hoots, roehrich, norad spacetrack report #3 1980
// hoots, norad spacetrack report #6 1986
// hoots, schumacher and glover 2004
// vallado, crawford, hujsak, kelso  2006
  DeepSpaceLongPeriodPeriodicContributions _dpper({
    required double time,
    required double eccPeriodic,
    required double incLPeriodic,
    required double raanPeriodic,
    required double argpPeriodic,
    required double meanAnomPeriodic,
    required bool init,
    required _OpsMode opsmode,
  }) {
    const double zns = 1.19459e-5;
    const double zes = 0.01675;
    const double znl = 1.5835218e-4;
    const double zel = 0.05490;

    // Calculate time varying periodics
    var zm = zmos + (zns * time);

    // Initial call has time set to zero
    if (init) {
      zm = zmos;
    }

    var zf = zm + (2.0 * zes * sin(zm));
    var sinZf = sin(zf);
    var f2 = (0.5 * sinZf * sinZf) - 0.25;
    var f3 = -0.5 * sinZf * cos(zf);

    double ses = (se2 * f2) + (se3 * f3);
    double sis = (si2 * f2) + (si3 * f3);
    double sls = (sl2 * f2) + (sl3 * f3) + (sl4 * sinZf);
    double sghs = (sgh2 * f2) + (sgh3 * f3) + (sgh4 * sinZf);
    double shs = (sh2 * f2) + (sh3 * f3);

    zm = zmol + (znl * time);
    if (init) {
      zm = zmol;
    }

    zf = zm + (2.0 * zel * sin(zm));
    sinZf = sin(zf);
    f2 = (0.5 * sinZf * sinZf) - 0.25;
    f3 = -0.5 * sinZf * cos(zf);

    var sel = (ee2 * f2) + (e3 * f3);
    var sil = (xi2 * f2) + (xi3 * f3);
    var sll = (xl2 * f2) + (xl3 * f3) + (xl4 * sinZf);
    var sghl = (xgh2 * f2) + (xgh3 * f3) + (xgh4 * sinZf);
    var shll = (xh2 * f2) + (xh3 * f3);

    var pe = ses + sel;
    var pinc = sis + sil;
    var pl = sls + sll;
    var pgh = sghs + sghl;
    var ph = shs + shll;

    if (!init) {
      pe -= peo;
      pinc -= pinco;
      pl -= plo;
      pgh -= pgho;
      ph -= pho;
      incLPeriodic += pinc;
      eccPeriodic += pe;
      var sinIncPeriodic = sin(incLPeriodic);
      var cosIncPeriodic = cos(incLPeriodic);

      /* ----------------- apply periodics directly ------------ */
      // sgp4fix for lyddane choice
      // strn3 used original inclination - this is technically feasible
      // gsfc used perturbed inclination - also technically feasible
      // probably best to readjust the 0.2 limit value and limit discontinuity
      // 0.2 rad = 11.45916 deg
      // use next line for original strn3 approach and original inclination
      // if (inclo >= 0.2)
      // use next line for gsfc version and perturbed inclination
      if (incLPeriodic >= 0.2) {
        ph /= sinIncPeriodic;
        pgh -= cosIncPeriodic * ph;
        argpPeriodic += pgh;
        raanPeriodic += ph;
        meanAnomPeriodic += pl;
      } else {
        var sinRaanPeriodic = sin(raanPeriodic);
        var cosRaanPeriodic = cos(raanPeriodic);
        var alfdp = sinIncPeriodic * sinRaanPeriodic;
        var betdp = sinIncPeriodic * cosRaanPeriodic;
        var dalf = (ph * cosRaanPeriodic) + (pinc * cosIncPeriodic * sinRaanPeriodic);
        var dbet = (-ph * sinRaanPeriodic) + (pinc * cosIncPeriodic * cosRaanPeriodic);
        alfdp += dalf;
        betdp += dbet;
        raanPeriodic %= twoPi;

        //  sgp4fix for afspc written intrinsic functions
        //  raanp used without a trigonometric function ahead
        if (raanPeriodic < 0.0 && opsmode == _OpsMode.a) {
          raanPeriodic += twoPi;
        }
        var xls = meanAnomPeriodic + argpPeriodic + (cosIncPeriodic * raanPeriodic);
        var dls = pl + pgh - (pinc * raanPeriodic * sinIncPeriodic);
        xls += dls;
        var xnoh = raanPeriodic;
        raanPeriodic = atan2(alfdp, betdp);

        //  sgp4fix for afspc written intrinsic functions
        //  raanp used without a trigonometric function ahead
        if (raanPeriodic < 0.0 && opsmode == _OpsMode.a) {
          raanPeriodic += twoPi;
        }
        if ((xnoh - raanPeriodic).abs() > pi) {
          if (raanPeriodic < xnoh) {
            raanPeriodic += twoPi;
          } else {
            raanPeriodic -= twoPi;
          }
        }
        meanAnomPeriodic += pl;
        argpPeriodic = xls - meanAnomPeriodic - (cosIncPeriodic * raanPeriodic);
      }
    }

    return DeepSpaceLongPeriodPeriodicContributions(
      eccPeriodic: eccPeriodic, 
      incPeriodic: incLPeriodic, 
      raanPeriodic: raanPeriodic, 
      argpPeriodic: argpPeriodic, 
      meanAnomPeriodic: meanAnomPeriodic
    );
  }

  /*-----------------------------------------------------------------------------
 *  Initialize propagator. 
 *
 *  inputs        :
 *    ecco        - eccentricity                           0.0 - 1.0
 *    epoch       - epoch time in days from jan 0, 1950. 0 hr
 *    inclo       - inclination of satellite
 *    no          - mean motion of satellite
 *
 *  outputs       :
 *    ainv        - 1.0 / a
 *    ao          - semi major axis
 *    con41       -
 *    con42       - 1.0 - 5.0 cos(i)
 *    cosio       - cosine of inclination
 *    cosio2      - cosio squared
 *    eccsq       - eccentricity squared
 *    method      - flag for deep space                    'd', 'n'
 *    omeosq      - 1.0 - ecco * ecco
 *    posq        - semi-parameter squared
 *    rp          - radius of perigee
 *    rteosq      - square root of (1.0 - ecco*ecco)
 *    sinio       - sine of inclination
 *    gsto        - gst at time of observation               rad
 *    no          - mean motion of satellite
 *
 *
 *  references    :
 *    hoots, roehrich, norad spacetrack report #3 1980
 *    hoots, norad spacetrack report #6 1986
 *    hoots, schumacher and glover 2004
 *    vallado, crawford, hujsak, kelso  2006
 ----------------------------------------------------------------------------*/
  static _Spg4InitResult _initialize({
    required Planet planet,
    required double ecc0,
    required double epoch,
    required double inc0,
    required double meanMotion0,
    required _OpsMode opsmode,
  }) {
    var j2 = planet.j2;
    var xke = planet.xke();

    // ------------- calculate auxillary epoch quantities ----------
    var eccsq = ecc0 * ecc0;
    var omeosq = 1.0 - eccsq;
    var rteosq = sqrt(omeosq);
    var cosInc0 = cos(inc0);
    final sinInc0 = sin(inc0);
    var cosInc0sq = cosInc0 * cosInc0;

    // ------------------ un-kozai the mean motion -----------------
    var ak = pow(xke / meanMotion0, 2.0 / 3.0);
    var d1 = 0.75 * j2 * ((3.0 * cosInc0sq) - 1.0) / (rteosq * omeosq);
    var delPrime = d1 / (ak * ak);
    var adel = ak *
        (1.0 - (delPrime * delPrime) -
        (delPrime * ((1.0 / 3.0) + (134.0 * delPrime * delPrime / 81.0))));
    delPrime = d1 / (adel * adel);
    meanMotion0 /= 1.0 + delPrime;

    final semiMajor0 = pow(xke / meanMotion0, 2.0 / 3.0).toDouble();
    final p0 = semiMajor0 * omeosq;
    final con42 = 1.0 - (5.0 * cosInc0sq);
    final con41 = -con42 - cosInc0sq - cosInc0sq;
    final aInv = 1.0 / semiMajor0;
    final p0Sqr = p0 * p0;
    final rP = semiMajor0 * (1.0 - ecc0);
    final method = _OpsMode.n;

    //  sgp4fix modern approach to finding sidereal time
    double gsto;
    if (opsmode == _OpsMode.a) {
      //  sgp4fix use old way of finding gst
      //  count integer number of days from 0 jan 1970
      final ts70 = epoch - 7305.0;
      final ds70 = (ts70 + 1.0e-8).floor();
      final tfrac = ts70 - ds70;

      //  find greenwich location at epoch
      const double c1 = 1.72027916940703639e-2;
      const double thgr70 = 1.7321343856509374;
      const double fk5r = 5.07551419432269442e-15;

      var c1p2p = c1 + twoPi;
      gsto = (thgr70 + (c1 * ds70) + (c1p2p * tfrac) + (ts70 * ts70 * fk5r)) %
          twoPi;
      if (gsto < 0.0) {
        gsto += twoPi;
      }
    } else {
      gsto = _gstime(epoch + 2433281.5);
    }

    return _Spg4InitResult(
      meanMotion0: meanMotion0,
      method: method,
      aInv: aInv,
      semiMajor0: semiMajor0,
      con41: con41,
      con42: con42,
      cosInc0: cosInc0,
      cosInc0sqr: cosInc0sq,
      eccSq: eccsq,
      omeosq: omeosq,
      p0Sqr: p0Sqr,
      rp: rP,
      rteosq: rteosq,
      sinInc0: sinInc0,
      gsto: gsto,
    );
  }

  /*----------------------------------------------------------------------------
     *
     *                             procedure sgp4
     *
     *  this procedure is the sgp4 prediction model from space command. this is an
     *    updated and combined version of sgp4 and sdp4, which were originally
     *    published separately in spacetrack report //3. this version follows the
     *    methodology from the aiaa paper (2006) describing the history and
     *    development of the code.
     *
     *  author        : david vallado                  719-573-2600   28 jun 2005
     *
     *  inputs        :
     *    satrec  - initialised structure from sgp4init() call.
     *    tsince  - time since epoch (minutes)
     *
     *  outputs       :
     *    r           - position vector                     km
     *    v           - velocity                            km/sec
     *  return code - non-zero on error.
     *                   1 - mean elements, ecc >= 1.0 or ecc < -0.001 or a < 0.95 er
     *                   2 - mean motion less than 0.0
     *                   3 - pert elements, ecc < 0.0  or  ecc > 1.0
     *                   4 - semi-latus rectum < 0.0
     *                   5 - epoch elements are sub-orbital
     *                   6 - satellite has decayed
     *
     *  locals        :
     *    am          -
     *    axnl, aynl        -
     *    betal       -
     *    cosim   , sinim   , cosomm  , sinomm  , cnod    , snod    , cos2u   ,
     *    sin2u   , coseo1  , sineo1  , cosi    , sini    , cosip   , sinip   ,
     *    cosisq  , cossu   , sinsu   , cosu    , sinu
     *    delm        -
     *    delomg      -
     *    dndt        -
     *    eccm        -
     *    emsq        -
     *    ecose       -
     *    el2         -
     *    eo1         -
     *    eccp        -
     *    esine       -
     *    argpm       -
     *    argpp       -
     *    omgadf      -
     *    pl          -
     *    r           -
     *    rtemsq      -
     *    rdotl       -
     *    rl          -
     *    rvdot       -
     *    rvdotl      -
     *    su          -
     *    t2  , t3   , t4    , tc
     *    tem5, temp , temp1 , temp2  , tempa  , tempe  , templ
     *    u   , ux   , uy    , uz     , vx     , vy     , vz
     *    inclm       - inclination
     *    mm          - mean anomaly
     *    nm          - mean motion
     *    nodem       - right asc of ascending node
     *    xinc        -
     *    xincp       -
     *    xl          -
     *    xlm         -
     *    mp          -
     *    xmdf        -
     *    xmx         -
     *    xmy         -
     *    nodedf      -
     *    xnode       -
     *    raanp       -
     *    np          -
     *
     *  coupling      :
     *    getgravconst-
     *    dpper
     *    dspace
     *
     *  references    :
     *    hoots, roehrich, norad spacetrack report //3 1980
     *    hoots, norad spacetrack report //6 1986
     *    hoots, schumacher and glover 2004
     *    vallado, crawford, hujsak, kelso  2006
     ----------------------------------------------------------------------------*/

  /// Get Position.
  OrbitalState getPosition(double minutes) {
    var satrec = this;
    var planet = satrec.planet;
    var earthRadius = planet.radiusKm;
    var xke = planet.xke();
    var j2 = planet.j2;
    var j3 = planet.j3;

    var j3oj2 = j3 / j2;
    var vKmSec = earthRadius * xke / 60.0;

    //  ------- update for secular gravity and atmospheric drag -----
    var xmdf = satrec.meanAnom0 + (satrec.meanMotionDot * minutes);
    var argpdf = satrec.argp0 + (satrec.argpDot * minutes);
    var nodedf = satrec.raan0 + (satrec.raanDot * minutes);
    var argpMean = argpdf;
    var meanAnomMean = xmdf;
    var minutesSqr = minutes * minutes;
    var raanMean = nodedf + (satrec.nodecf * minutesSqr);
    var tempA = 1.0 - (satrec.cc1 * minutes);
    var tempEcc = satrec.bstar * satrec.cc4 * minutes;
    var tempL = satrec.t2cof * minutesSqr;

    if (satrec.isimp != 1) {
      var delomg = satrec.omgcof * minutes;
      //  sgp4fix use mutliply for speed instead of pow
      var delmtemp = 1.0 + (satrec.eta * cos(xmdf));
      var delm =
          satrec.xmcof * ((delmtemp * delmtemp * delmtemp) - satrec.delMeanAnom);
      var tempp = delomg + delm;
      meanAnomMean = xmdf + tempp;
      argpMean = argpdf - tempp;
      var minutesCube = minutesSqr * minutes;
      var minutesQuart = minutesCube * minutes;
      tempA = tempA - (satrec.d2 * minutesSqr) - (satrec.d3 * minutesCube) - (satrec.d4 * minutesQuart);
      tempEcc += satrec.bstar * satrec.cc5 * (sin(meanAnomMean) - satrec.sinMeanAnom0);
      tempL = tempL +
          (satrec.t3cof * minutesCube) +
          (minutesQuart * (satrec.t4cof + (minutes * satrec.t5cof)));
    }
    var meanMotionMean = satrec.meanMotion0;
    var eccMean = satrec.ecc0;
    var incMean = satrec.incO;

    if (satrec._method == _Method.d) {
      var tc = minutes;

      var dspaceResult = _deepSpace(
          satrec: satrec,
          t: minutes,
          tc: tc,
          eccMean: eccMean,
          argpMean: argpMean,
          incMean: incMean,
          xli: satrec.xli,
          meanAnomMean: meanAnomMean,
          xni: satrec.xni,
          raanMean: raanMean,
          meanMotionMean: meanMotionMean
        );

      eccMean = dspaceResult.eccMean;
      argpMean = dspaceResult.argpMean;
      incMean = dspaceResult.incMean;
      meanAnomMean = dspaceResult.meanAnomMean;
      raanMean = dspaceResult.raanMean;
      meanMotionMean = dspaceResult.meanMotionMean;
    }

    if (meanMotionMean <= 0.0) {
      throw PropagationException('Error mean mean motion $meanMotionMean', 2);
    }

    var am = pow(xke / meanMotionMean, 2.0 / 3.0) * tempA * tempA;
    meanMotionMean = xke / pow(am, 1.5);
    eccMean -= tempEcc;

    // fix tolerance for error recognition
    if (eccMean >= 1.0 || eccMean < -0.001) // || (am < 0.95)
    {
      throw PropagationException('Error mean eccentricity $eccMean', 1);
    }

    // Avoid a divide by zero
    if (eccMean < 1.0e-6) {
      eccMean = 1.0e-6;
    }
    meanAnomMean += satrec.meanMotion0 * tempL;
    var xlm = meanAnomMean + argpMean + raanMean;

    raanMean %= twoPi;
    argpMean %= twoPi;
    xlm %= twoPi;
    meanAnomMean = (xlm - argpMean - raanMean) % twoPi;

    var sinIncMean = sin(incMean);
    var cosIncMean = cos(incMean);

    // -------------------- add lunar-solar periodics --------------
    var eccPeriodic = eccMean;
    var xIncPeriodic = incMean;
    var argpPeriodic = argpMean;
    var raanPeriodic = raanMean;
    var meanAnomPeriodic = meanAnomMean;
    var sinIncPeriodic = sinIncMean;
    var cosIncPeriodic = cosIncMean;

    if (satrec._method == _Method.d) {
      var dpperResult = satrec._dpper(
          time: minutes,
          init: false,
          eccPeriodic: eccPeriodic,
          incLPeriodic: xIncPeriodic,
          raanPeriodic: raanPeriodic,
          argpPeriodic: argpPeriodic,
          meanAnomPeriodic: meanAnomPeriodic,
          opsmode: satrec._operationmode
        );

      xIncPeriodic = dpperResult.incPeriodic;

      if (xIncPeriodic < 0.0) {
        xIncPeriodic = -xIncPeriodic;
        raanPeriodic += pi;
        argpPeriodic -= pi;
      }
      if (eccPeriodic < 0.0 || eccPeriodic > 1.0) {
        throw PropagationException('Error periodic eccentricity $eccPeriodic', 3);
      }
    }

    var aycof = satrec.aycof;
    var xlcof = satrec.xlcof;

    //  -------------------- long period periodics ------------------
    if (satrec._method == _Method.d) {
      sinIncPeriodic = sin(xIncPeriodic);
      cosIncPeriodic = cos(xIncPeriodic);
      aycof = -0.5 * j3oj2 * sinIncPeriodic;

      // divide by zero for xincp = 180 deg
      xlcof = (cosIncPeriodic + 1.0).abs() > zeroTol
          ? -0.25 * j3oj2 * sinIncPeriodic * (3.0 + (5.0 * cosIncPeriodic)) / (1.0 + cosIncPeriodic)
          : -0.25 * j3oj2 * sinIncPeriodic * (3.0 + (5.0 * cosIncPeriodic)) / zeroTol;
    }

    var axnl = eccPeriodic * cos(argpPeriodic);
    var temp = 1.0 / (am * (1.0 - (eccPeriodic * eccPeriodic)));
    var aynl = (eccPeriodic * sin(argpPeriodic)) + (temp * aycof);
    var xl = meanAnomPeriodic + argpPeriodic + raanPeriodic + (temp * xlcof * axnl);

    // --------------------- solve kepler's equation ---------------
    var u = (xl - raanPeriodic) % twoPi;
    var eo1 = u;
    var tem5 = 9999.9;
    var ktr = 1;

    var coseo1 = 0.0;
    var sineo1 = 0.0;

    //    sgp4fix for kepler iteration
    //    the following iteration needs better limits on corrections
    while (tem5.abs() >= 1.0e-12 && ktr <= 10) {
      sineo1 = sin(eo1);
      coseo1 = cos(eo1);
      tem5 = 1.0 - (coseo1 * axnl) - (sineo1 * aynl);
      tem5 = (u - (aynl * coseo1) + (axnl * sineo1) - eo1) / tem5;
      if (tem5.abs() >= 0.95) {
        tem5 = tem5 > 0.0 ? 0.95 : -0.95;
      }
      eo1 += tem5;
      ktr += 1;
    }

    //  ------------- short period preliminary quantities -----------
    var ecose = (axnl * coseo1) + (aynl * sineo1);
    var esine = (axnl * sineo1) - (aynl * coseo1);
    var el2 = (axnl * axnl) + (aynl * aynl);
    var pl = am * (1.0 - el2);
    if (pl < 0.0) {
      throw PropagationException('Error pl $pl', 4);
    }

    var rl = am * (1.0 - ecose);
    var rdotl = sqrt(am) * esine / rl;
    var rvdotl = sqrt(pl) / rl;
    var betal = sqrt(1.0 - el2);
    temp = esine / (1.0 + betal);
    var sinu = am / rl * (sineo1 - aynl - (axnl * temp));
    var cosu = am / rl * (coseo1 - axnl + (aynl * temp));
    var su = atan2(sinu, cosu);
    var sin2u = (cosu + cosu) * sinu;
    var cos2u = 1.0 - (2.0 * sinu * sinu);
    temp = 1.0 / pl;
    var temp1 = 0.5 * j2 * temp;
    var temp2 = temp1 * temp;

    var con41 = satrec.con41;
    var x1mth2 = satrec.x1mth2;
    var x7thm1 = satrec.x7thm1;

    // -------------- update for short period periodics ------------
    if (satrec._method == _Method.d) {
      var cosisq = cosIncPeriodic * cosIncPeriodic;
      con41 = (3.0 * cosisq) - 1.0;
      x1mth2 = 1.0 - cosisq;
      x7thm1 = (7.0 * cosisq) - 1.0;
    }

    var mrt = (rl * (1.0 - (1.5 * temp2 * betal * con41))) +
        (0.5 * temp1 * x1mth2 * cos2u);

    // sgp4fix for decaying satellites
    if (mrt < 1.0) {
      throw PropagationException('decay condition $mrt', 6);
    }

    su -= 0.25 * temp2 * x7thm1 * sin2u;
    var xRaan = raanPeriodic + (1.5 * temp2 * cosIncPeriodic * sin2u);
    var xInc = xIncPeriodic + (1.5 * temp2 * cosIncPeriodic * sinIncPeriodic * cos2u);
    var mvt = rdotl - (meanMotionMean * temp1 * x1mth2 * sin2u / xke);
    var rvdot =
        rvdotl + (meanMotionMean * temp1 * ((x1mth2 * cos2u) + (1.5 * con41)) / xke);

    // --------------------- orientation vectors -------------------
    var sinSu = sin(su);
    var cosSu = cos(su);
    var sinRaan = sin(xRaan);
    var cosRaan = cos(xRaan);
    var sinInc = sin(xInc);
    var cosInc = cos(xInc);
    var xmx = -sinRaan * cosInc;
    var xmy = cosRaan * cosInc;

    var ux = (xmx * sinSu) + (cosRaan * cosSu);
    var uy = (xmy * sinSu) + (sinRaan * cosSu);
    var uz = sinInc * sinSu;
    var vx = (xmx * cosSu) - (cosRaan * sinSu);
    var vy = (xmy * cosSu) - (sinRaan * sinSu);
    var vz = sinInc * cosSu;

    // --------- ECI position and velocity (in km and km/sec) ----------
    var r = Vector3(
        mrt * ux * earthRadius, 
        mrt * uy * earthRadius, 
        mrt * uz * earthRadius
      );
    var v = Vector3(
        ((mvt * ux) + (rvdot * vx)) * vKmSec,
        ((mvt * uy) + (rvdot * vy)) * vKmSec,
        ((mvt * uz) + (rvdot * vz)) * vKmSec
      );

    return OrbitalState(r, v);
  }

  OrbitalState getPositionByDateTime(DateTime utc) {
    final minutes = keplerianElements.getMinutesPastEpoch(utc);
    return getPosition(minutes);
  }
}

class _DspaceResult {
  const _DspaceResult({
    required this.atime,
    required this.eccMean,
    required this.argpMean,
    required this.incMean,
    required this.xli,
    required this.meanAnomMean,
    required this.xni,
    required this.raanMean,
    required this.meanMotionMean,
    required this.dndt,
  });

  final double atime;
  final double eccMean;
  final double argpMean;
  final double incMean;
  final double xli;
  final double meanAnomMean;
  final double xni;
  final double raanMean;
  final double meanMotionMean;
  final double dndt;
}

class _Spg4InitResult {
  const _Spg4InitResult({
    required this.method,
    required this.meanMotion0,
    required this.aInv,
    required this.semiMajor0,
    required this.con41,
    required this.con42,
    required this.cosInc0,
    required this.cosInc0sqr,
    required this.eccSq,
    required this.omeosq,
    required this.p0Sqr,
    required this.rp,
    required this.rteosq,
    required this.sinInc0,
    required this.gsto,
  });
  final _OpsMode method;
  final double meanMotion0;
  final double aInv;
  final double semiMajor0;
  final double con41;
  final double con42;
  final double cosInc0;
  final double cosInc0sqr;
  final double eccSq;
  final double omeosq;
  final double p0Sqr;
  final double rp;
  final double rteosq;
  final double sinInc0;
  final double gsto;
}

class _DsInitResult {
  const _DsInitResult(
      {required this.irez,
      required this.em,
      required this.argpm,
      required this.inclm,
      required this.mm,
      required this.nm,
      required this.nodem,
      required this.atime,
      required this.d2201,
      required this.d2211,
      required this.d3210,
      required this.d3222,
      required this.d4410,
      required this.d4422,
      required this.d5220,
      required this.d5232,
      required this.d5421,
      required this.d5433,
      required this.dedt,
      required this.didt,
      required this.dmdt,
      required this.dndt,
      required this.dnodt,
      required this.domdt,
      required this.del1,
      required this.del2,
      required this.del3,
      required this.xfact,
      required this.xlamo,
      required this.xli,
      required this.xni});

  final int irez;
  final double em;
  final double argpm;
  final double inclm;
  final double mm;
  final double nm;
  final double nodem;
  final double atime;
  final double d2201;
  final double d2211;
  final double d3210;
  final double d3222;
  final double d4410;
  final double d4422;
  final double d5220;
  final double d5232;
  final double d5421;
  final double d5433;
  final double dedt;
  final double didt;
  final double dmdt;
  final double dndt;
  final double dnodt;
  final double domdt;
  final double del1;
  final double del2;
  final double del3;
  final double xfact;
  final double xlamo;
  final double xli;
  final double xni;
}

class PropagationException implements Exception {
  const PropagationException(this.message, [int n = 0]);
  final String message;
}

enum _OpsMode {
  n,
  a,
  i,
}

enum _Method {
  d,
  n,
}

double _julian(int year, double doy) {
  {
    // Now calculate Julian date
    // Ref: "Astronomical Formulae for Calculators", Jean Meeus, pages 23-25

    year--;

    // Centuries are not leap years unless they divide by 400
    int A = year ~/ 100;
    int B = 2 - A + (A ~/ 4);
    var yearDays = (365.25 * year).toInt();
    double jan01 = yearDays + (30.6001 * 14).toInt() + 1720994.5 + B;

    return jan01 + doy;
  }
}

double _gstime(double jdut1) {
  var tut1 = (jdut1 - 2451545.0) / 36525.0;

  var temp = (-6.2e-6 * tut1 * tut1 * tut1) +
      (0.093104 * tut1 * tut1) +
      (((876600.0 * secPerHour) + 8640184.812866) * tut1) +
      67310.54841; // # sec
  temp = temp * degToRad / 240.0 % twoPi; // 360/86400 = 1/240, to deg, to rad

  //  ------------------------ check quadrants ---------------------
  if (temp < 0.0) {
    temp += twoPi;
  }

  return temp;
}

extension _X on Planet {
  double xke() {
    return 60.0 / sqrt(radiusKm * radiusKm * radiusKm / mu);
  }
}

/*-----------------------------------------------------------------------------

* Provide deep space contributions to mean elements fromperturbing third body. 
* These effects have been averaged over one revolution of the sun and moon.  
* for earth resonance effects, the effects have been averaged over mean motion # 
* revolutions of the satellite.
*
*  inputs        :
*    d2201, d2211, d3210, d3222, d4410, d4422, d5220, d5232, d5421, d5433 -
*    dedt        -
*    del1, del2, del3  -
*    didt        -
*    dmdt        -
*    dnodt       -
*    domdt       -
*    irez        - flag for resonance           0-none, 1-one day, 2-half day
*    argpo       - argument of perigee
*    argpdot     - argument of perigee dot (rate)
*    t           - time
*    tc          -
*    gsto        - gst
*    xfact       -
*    xlamo       -
*    no          - mean motion
*    atime       -
*    em          - eccentricity
*    ft          -
*    argpm       - argument of perigee
*    inclm       - inclination
*    xli         -
*    mm          - mean anomaly
*    xni         - mean motion
*    nodem       - right ascension of ascending node
*
*  outputs       :
*    atime       -
*    em          - eccentricity
*    argpm       - argument of perigee
*    inclm       - inclination
*    xli         -
*    mm          - mean anomaly
*    xni         -
*    nodem       - right ascension of ascending node
*    dndt        -
*    nm          - mean motion
*
*  references    :
*    hoots, roehrich, norad spacetrack report #3 1980
*    hoots, norad spacetrack report #6 1986
*    hoots, schumacher and glover 2004
*    vallado, crawford, hujsak, kelso  2006
----------------------------------------------------------------------------*/
_DspaceResult _deepSpace({
  required SGP4 satrec,
  required double t,
  required double tc,
  //
  required double eccMean,
  required double argpMean,
  required double incMean,
  required double xli,
  required double meanAnomMean,
  required double xni,
  required double raanMean,
  required double meanMotionMean,
}) {
  var irez = satrec.irez;
  var d2201 = satrec.d2201;
  var d2211 = satrec.d2211;
  var d3210 = satrec.d3210;
  var d3222 = satrec.d3222;
  var d4410 = satrec.d4410;
  var d4422 = satrec.d4422;
  var d5220 = satrec.d5220;
  var d5232 = satrec.d5232;
  var d5421 = satrec.d5421;
  var d5433 = satrec.d5433;
  var dedt = satrec.dedt;
  var del1 = satrec.del1;
  var del2 = satrec.del2;
  var del3 = satrec.del3;
  var didt = satrec.didt;
  var dmdt = satrec.dmdt;
  var dnodt = satrec.dnodt;
  var domdt = satrec.domdt;
  var argpo = satrec.argp0;
  var argpdot = satrec.argpDot;

  var gsto = satrec.gsto;
  var xfact = satrec.xfact;
  var xlamo = satrec.xlamo;
  var no = satrec.meanMotion0;
  var atime = satrec.atime;

  const double fasx2 = 0.13130908;
  const double fasx4 = 2.8843198;
  const double fasx6 = 0.37448087;
  const double g22 = 5.7686396;
  const double g32 = 0.95240898;
  const double g44 = 1.8014998;
  const double g52 = 1.0508330;
  const double g54 = 4.4108898;
  const double rptim = 4.37526908801129966e-3; // 7.29211514668855e-5 rad/sec
  const double stepp = 720.0;
  const double stepn = -720.0;
  const double step2 = 259200.0;

  double x2li;
  double x2omi;
  double xl;
  double xldot = 0;
  double xnddt = 0;
  double xndt = 0;
  double xomi;
  double dndt = 0.0;
  double ft = 0.0;

  //  ----------- calculate deep space resonance effects -----------
  double theta = (gsto + (tc * rptim)) % twoPi;
  eccMean += dedt * t;
  incMean += didt * t;
  argpMean += domdt * t;
  raanMean += dnodt * t;
  meanAnomMean += dmdt * t;

  /* - update resonances : numerical (euler-maclaurin) integration - */
  /* ------------------------- epoch restart ----------------------  */
  //   sgp4fix for propagator problems
  //   the following integration works for negative time steps and periods
  //   the specific changes are unknown because the original code was so convoluted

  if (irez != 0) {
    if (atime == 0.0 || t * atime <= 0.0 || t.abs() < atime.abs()) {
      atime = 0.0;
      xni = no;
      xli = xlamo;
    }
    var delt = t > 0.0 ? stepp : stepn;

    var iretn = 381; // added for do loop
    while (iretn == 381) {
      //  ------------------- dot terms calculated -------------
      //  ----------- near - synchronous resonance terms -------
      if (irez != 2) {
        xndt = (del1 * sin(xli - fasx2)) +
            (del2 * sin(2.0 * (xli - fasx4))) +
            (del3 * sin(3.0 * (xli - fasx6)));
        xldot = xni + xfact;
        xnddt = (del1 * cos(xli - fasx2)) +
            (2.0 * del2 * cos(2.0 * (xli - fasx4))) +
            (3.0 * del3 * cos(3.0 * (xli - fasx6)));
        xnddt *= xldot;
      } else {
        // --------- near - half-day resonance terms --------
        xomi = argpo + (argpdot * atime);
        x2omi = xomi + xomi;
        x2li = xli + xli;
        xndt = (d2201 * sin(x2omi + xli - g22)) +
            (d2211 * sin(xli - g22)) +
            (d3210 * sin(xomi + xli - g32)) +
            (d3222 * sin(-xomi + xli - g32)) +
            (d4410 * sin(x2omi + x2li - g44)) +
            (d4422 * sin(x2li - g44)) +
            (d5220 * sin(xomi + xli - g52)) +
            (d5232 * sin(-xomi + xli - g52)) +
            (d5421 * sin(xomi + x2li - g54)) +
            (d5433 * sin(-xomi + x2li - g54));
        xldot = xni + xfact;
        xnddt = (d2201 * cos(x2omi + xli - g22)) +
            (d2211 * cos(xli - g22)) +
            (d3210 * cos(xomi + xli - g32)) +
            (d3222 * cos(-xomi + xli - g32)) +
            (d5220 * cos(xomi + xli - g52)) +
            (d5232 * cos(-xomi + xli - g52)) +
            (2.0 * d4410 * cos(x2omi + x2li - g44)) +
            (d4422 * cos(x2li - g44)) +
            (d5421 * cos(xomi + x2li - g54)) +
            (d5433 * cos(-xomi + x2li - g54));
        xnddt *= xldot;
      }

      //  ----------------------- integrator -------------------
      //  sgp4fix move end checks to end of routine
      if ((t - atime).abs() >= stepp) {
        iretn = 381;
      } else {
        ft = t - atime;
        iretn = 0;
      }

      if (iretn == 381) {
        xli += (xldot * delt) + (xndt * step2);
        xni += (xndt * delt) + (xnddt * step2);
        atime += delt;
      }
    }

    meanMotionMean = xni + (xndt * ft) + (xnddt * ft * ft * 0.5);
    xl = xli + (xldot * ft) + (xndt * ft * ft * 0.5);
    if (irez != 1) {
      meanAnomMean = xl - (2.0 * raanMean) + (2.0 * theta);
      dndt = meanMotionMean - no;
    } else {
      meanAnomMean = xl - raanMean - argpMean + theta;
      dndt = meanMotionMean - no;
    }
    meanMotionMean = no + dndt;
  }

  var ret = _DspaceResult(
      atime: atime,
      eccMean: eccMean,
      argpMean: argpMean,
      incMean: incMean,
      xli: xli,
      meanAnomMean: meanAnomMean,
      xni: xni,
      raanMean: raanMean,
      dndt: dndt,
      meanMotionMean: meanMotionMean);

  return ret;
}

/*-----------------------------------------------------------------------------

*  Provide deep space contributions to mean motion dot due
*  to geopotential resonance with half day and one day orbits.
*
*  inputs        :
*    cosim, sinim-
*    emsq        - eccentricity squared
*    argpo       - argument of perigee
*    s1, s2, s3, s4, s5      -
*    ss1, ss2, ss3, ss4, ss5 -
*    sz1, sz3, sz11, sz13, sz21, sz23, sz31, sz33 -
*    t           - time
*    tc          -
*    gsto        - greenwich sidereal time                   rad
*    mo          - mean anomaly
*    mdot        - mean anomaly dot (rate)
*    no          - mean motion
*    nodeo       - right ascension of ascending node
*    nodedot     - right ascension of ascending node dot (rate)
*    xpidot      -
*    z1, z3, z11, z13, z21, z23, z31, z33 -
*    eccm        - eccentricity
*    argpm       - argument of perigee
*    inclm       - inclination
*    mm          - mean anomaly
*    xn          - mean motion
*    nodem       - right ascension of ascending node
*
*  outputs       :
*    em          - eccentricity
*    argpm       - argument of perigee
*    inclm       - inclination
*    mm          - mean anomaly
*    nm          - mean motion
*    nodem       - right ascension of ascending node
*    irez        - flag for resonance           0-none, 1-one day, 2-half day
*    atime       -
*    d2201, d2211, d3210, d3222, d4410, d4422, d5220, d5232, d5421, d5433    -
*    dedt        -
*    didt        -
*    dmdt        -
*    dndt        -
*    dnodt       -
*    domdt       -
*    del1, del2, del3        -
*    ses  , sghl , sghs , sgs  , shl  , shs  , sis  , sls
*    theta       -
*    xfact       -
*    xlamo       -
*    xli         -
*    xni
*
*
*  references    :
*    hoots, roehrich, norad spacetrack report #3 1980
*    hoots, norad spacetrack report #6 1986
*    hoots, schumacher and glover 2004
*    vallado, crawford, hujsak, kelso  2006
----------------------------------------------------------------------------*/
_DsInitResult _deepSpaceInit({

  required Planet planet,
  required double cosim,
  required double argp0,
  required double s1,
  required double s2,
  required double s3,
  required double s4,
  required double s5,
  required double sinim,
  required double ss1,
  required double ss2,
  required double ss3,
  required double ss4,
  required double ss5,
  required double sz1,
  required double sz3,
  required double sz11,
  required double sz13,
  required double sz21,
  required double sz23,
  required double sz31,
  required double sz33,
  required double t,
  required double tc,
  required double gsto,
  required double mo,
  required double mdot,
  required double no,
  required double nodeo,
  required double nodedot,
  required double xpidot,
  required double z1,
  required double z3,
  required double z11,
  required double z13,
  required double z21,
  required double z23,
  required double z31,
  required double z33,
  required double ecco,
  required double eccsq,
  required double emsq,
  required double em,
  required double argpm,
  required double inclm,
  required double mm,
  required double nm,
  required double nodem,
  required int irez,
  required double atime,
  required double d2201,
  required double d2211,
  required double d3210,
  required double d3222,
  required double d4410,
  required double d4422,
  required double d5220,
  required double d5232,
  required double d5421,
  required double d5433,
  required double dedt,
  required double didt,
  required double dmdt,
  required double dnodt,
  required double domdt,
  required double del1,
  required double del2,
  required double del3,
  required double xfact,
  required double xlamo,
  required double xli,
  required double xni,
}) {
  var xke = planet.xke();

  const double q22 = 1.7891679e-6;
  const double q31 = 2.1460748e-6;
  const double q33 = 2.2123015e-7;
  const double root22 = 1.7891679e-6;
  const double root44 = 7.3636953e-9;
  const double root54 = 2.1765803e-9;
  const double rptim =
      4.37526908801129966e-3; // equates to 7.29211514668855e-5 rad/sec
  const double root32 = 3.7393792e-7;
  const double root52 = 1.1428639e-7;
  const double znl = 1.5835218e-4;
  const double zns = 1.19459e-5;

  // -------------------- deep space initialization ------------
  irez = 0;
  if (nm < 0.0052359877 && nm > 0.0034906585) {
    irez = 1;
  }
  if ((nm >= 8.26e-3) && (nm <= 9.24e-3) && (em >= 0.5)) {
    irez = 2;
  }

  // ------------------------ solar terms -------------------
  var ses = ss1 * zns * ss5;
  var sis = ss2 * zns * (sz11 + sz13);
  var sls = -zns * ss3 * (sz1 + sz3 - 14.0 - (6.0 * emsq));
  var sghs = ss4 * zns * (sz31 + sz33 - 6.0);
  var shs = -zns * ss2 * (sz21 + sz23);

  bool incIs180Deg = inclm < 5.2359877e-2 || inclm > (pi - 5.2359877e-2);
  if (incIs180Deg) {shs = 0.0;}
  if (sinim != 0.0) {
    shs /= sinim;
  }
  var sgs = sghs - (cosim * shs);

  // ------------------------- lunar terms ------------------
  dedt = ses + (s1 * znl * s5);
  didt = sis + (s2 * znl * (z11 + z13));
  dmdt = sls - (znl * s3 * (z1 + z3 - 14.0 - (6.0 * emsq)));
  var sghl = s4 * znl * (z31 + z33 - 6.0);
  var shll = -znl * s2 * (z21 + z23);

  if (incIs180Deg) {shll = 0.0;}
  domdt = sgs + sghl;
  dnodt = shs;
  if (sinim != 0.0) {
    domdt -= cosim / sinim * shll;
    dnodt += shll / sinim;
  }

  // ----------- calculate deep space resonance effects --------
  const double dndt = 0.0;
  var theta = (gsto + (tc * rptim)) % twoPi;
  em += dedt * t;
  inclm += didt * t;
  argpm += domdt * t;
  nodem += dnodt * t;
  mm += dmdt * t;

  // -------------- initialize the resonance terms -------------
  if (irez != 0) {
    var semiMajorInv = nm / pow(xke, 2.0 / 3.0);

    // ---------- geopotential resonance for 12 hour orbits ------
    if (irez == 2) {
      var cosisq = cosim * cosim;
      var emo = em;
      em = ecco;
      var emsqo = emsq;
      emsq = eccsq;
      var eoc = em * emsq;
      var g201 = -0.306 - ((em - 0.64) * 0.440);

      double g211;
      double g310;
      double g322;
      double g410;
      double g422;
      double g520;
      double g533;
      double g521;
      double g532;

      if (em <= 0.65) {
        g211 = 3.616 - (13.2470 * em) + (16.2900 * emsq);
        g310 = -19.302 + (117.3900 * em) - (228.4190 * emsq) + (156.5910 * eoc);
        g322 =
            -18.9068 + (109.7927 * em) - (214.6334 * emsq) + (146.5816 * eoc);
        g410 = -41.122 + (242.6940 * em) - (471.0940 * emsq) + (313.9530 * eoc);
        g422 =
            -146.407 + (841.8800 * em) - (1629.014 * emsq) + (1083.4350 * eoc);
        g520 =
            -532.114 + (3017.977 * em) - (5740.032 * emsq) + (3708.2760 * eoc);
      } else {
        g211 = -72.099 + (331.819 * em) - (508.738 * emsq) + (266.724 * eoc);
        g310 =
            -346.844 + (1582.851 * em) - (2415.925 * emsq) + (1246.113 * eoc);
        g322 =
            -342.585 + (1554.908 * em) - (2366.899 * emsq) + (1215.972 * eoc);
        g410 =
            -1052.797 + (4758.686 * em) - (7193.992 * emsq) + (3651.957 * eoc);
        g422 = -3581.690 +
            (16178.110 * em) -
            (24462.770 * emsq) +
            (12422.520 * eoc);
        g520 = em > 0.715
            ? -5149.66 + (29936.92 * em) - (54087.36 * emsq) + (31324.56 * eoc)
            : 1464.74 - (4664.75 * em) + (3763.64 * emsq);
      }
      if (em < 0.7) {
        g533 = -919.22770 +
            (4988.6100 * em) -
            (9064.7700 * emsq) +
            (5542.21 * eoc);
        g521 = -822.71072 +
            (4568.6173 * em) -
            (8491.4146 * emsq) +
            (5337.524 * eoc);
        g532 =
            -853.66600 + (4690.2500 * em) - (8624.7700 * emsq) + (5341.4 * eoc);
      } else {
        g533 = -37995.780 +
            (161616.52 * em) -
            (229838.20 * emsq) +
            (109377.94 * eoc);
        g521 = -51752.104 +
            (218913.95 * em) -
            (309468.16 * emsq) +
            (146349.42 * eoc);
        g532 = -40023.880 +
            (170470.89 * em) -
            (242699.48 * emsq) +
            (115605.82 * eoc);
      }
      var sini2 = sinim * sinim;
      var f220 = 0.75 * (1.0 + (2.0 * cosim) + cosisq);
      var f221 = 1.5 * sini2;
      var f321 = 1.875 * sinim * (1.0 - (2.0 * cosim) - (3.0 * cosisq));
      var f322 = -1.875 * sinim * (1.0 + (2.0 * cosim) - (3.0 * cosisq));
      var f441 = 35.0 * sini2 * f220;
      var f442 = 39.3750 * sini2 * sini2;

      var f522 = 9.84375 *
          sinim *
          ((sini2 * (1.0 - (2.0 * cosim) - (5.0 * cosisq))) +
              (0.33333333 * (-2.0 + (4.0 * cosim) + (6.0 * cosisq))));
      var f523 = sinim *
          ((4.92187512 * sini2 * (-2.0 - (4.0 * cosim) + (10.0 * cosisq))) +
              (6.56250012 * (1.0 + (2.0 * cosim) - (3.0 * cosisq))));
      var f542 = 29.53125 *
          sinim *
          (2.0 -
              (8.0 * cosim) +
              (cosisq * (-12.0 + (8.0 * cosim) + (10.0 * cosisq))));
      var f543 = 29.53125 *
          sinim *
          (-2.0 -
              (8.0 * cosim) +
              (cosisq * (12.0 + (8.0 * cosim) - (10.0 * cosisq))));

      var xno2 = nm * nm;
      var semiMajorInvSqr = semiMajorInv * semiMajorInv;
      var temp1 = 3.0 * xno2 * semiMajorInvSqr;
      var temp = temp1 * root22;
      d2201 = temp * f220 * g201;
      d2211 = temp * f221 * g211;
      temp1 *= semiMajorInv;
      temp = temp1 * root32;
      d3210 = temp * f321 * g310;
      d3222 = temp * f322 * g322;
      temp1 *= semiMajorInv;
      temp = 2.0 * temp1 * root44;
      d4410 = temp * f441 * g410;
      d4422 = temp * f442 * g422;
      temp1 *= semiMajorInv;
      temp = temp1 * root52;
      d5220 = temp * f522 * g520;
      d5232 = temp * f523 * g532;
      temp = 2.0 * temp1 * root54;
      d5421 = temp * f542 * g521;
      d5433 = temp * f543 * g533;
      xlamo = (mo + nodeo + nodeo - (theta + theta)) % twoPi;
      xfact = mdot + dmdt + (2.0 * (nodedot + dnodt - rptim)) - no;
      em = emo;
      emsq = emsqo;
    }

    //  ---------------- synchronous resonance terms --------------
    if (irez == 1) {
      var g200 = 1.0 + (emsq * (-2.5 + (0.8125 * emsq)));
      var g310 = 1.0 + (2.0 * emsq);
      var g300 = 1.0 + (emsq * (-6.0 + (6.60937 * emsq)));
      var f220 = 0.75 * (1.0 + cosim) * (1.0 + cosim);
      var f311 = (0.9375 * sinim * sinim * (1.0 + (3.0 * cosim))) -
          (0.75 * (1.0 + cosim));
      var f330 = 1.0 + cosim;

      f330 *= 1.875 * f330 * f330;
      del1 = 3.0 * nm * nm * semiMajorInv * semiMajorInv;
      del2 = 2.0 * del1 * f220 * g200 * q22;
      del3 = 3.0 * del1 * f330 * g300 * q33 * semiMajorInv;
      del1 = del1 * f311 * g310 * q31 * semiMajorInv;
      xlamo = (mo + nodeo + argp0 - theta) % twoPi;
      xfact = mdot + xpidot + dmdt + domdt + dnodt - (no + rptim);
    }

    //  ------------ for sgp4, initialize the integrator ----------
    xli = xlamo;
    xni = no;
    atime = 0.0;
    nm = no + dndt;
  }

  return _DsInitResult(
      em: em,
      argpm: argpm,
      inclm: inclm,
      mm: mm,
      nm: nm,
      nodem: nodem,
      irez: irez,
      atime: atime,
      d2201: d2201,
      d2211: d2211,
      d3210: d3210,
      d3222: d3222,
      d4410: d4410,
      d4422: d4422,
      d5220: d5220,
      d5232: d5232,
      d5421: d5421,
      d5433: d5433,
      dedt: dedt,
      didt: didt,
      dmdt: dmdt,
      dndt: dndt,
      dnodt: dnodt,
      domdt: domdt,
      del1: del1,
      del2: del2,
      del3: del3,
      xfact: xfact,
      xlamo: xlamo,
      xli: xli,
      xni: xni
    );
}
