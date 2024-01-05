import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as im;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'math.dart';


PolylineLayer generateTrajectoryLayer(
  List<List<LatLng>> trajectories
){
  List<Polyline> lines = trajectories.map(
    (line){
      return Polyline(
        points: line,
        color: Colors.blue,
    );}
  ).toList();

  return PolylineLayer(
    polylines: lines,
  );
}


im.Image projectMercatorImage(
  im.Image image,
  LatLngBounds bounds,
){
  double latN = 75;
  double latS = -65;
  double latCenter = (latN + latS) / 2;
  double latDegExtent = latN - latS;

  for (final frame in image.frames) {
    var orig = frame.clone(noAnimation: true);
    double ny = frame.height - 1;
    int cy = frame.height ~/ 2;
  
    for (final newPixel in frame) {

      double normFromCenter = (newPixel.y - cy) / ny; 
      double latDeg = normFromCenter * latDegExtent + latCenter;
      double latRad = latDeg * degToRad;

      double newLatRad = 2 * atan(pow(e, latRad)) - pi / 2;

      double srcLatDeg = newLatRad / degToRad - latCenter;
      double normFromCenterDeg = srcLatDeg / latDegExtent;
      double origY = normFromCenterDeg * ny + cy;

      final p2 = orig.getPixelInterpolate(
        newPixel.x - 0.0, 
        origY, 
        interpolation: im.Interpolation.linear
      );
      newPixel.setRgba(
        p2.r, 
        p2.g, 
        p2.b,
        p2.a
      );
    }
  }
  return image;
}
