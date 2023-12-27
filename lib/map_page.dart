import 'package:flutter/material.dart';
import 'package:image/image.dart' as im;
import 'dart:math';
import 'package:flutter_map/flutter_map.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late Future<Position> futurePosition;
  LatLng defaultLatLon = LatLng(0, 0);

  bool lightPollution = true;

  @override
  void initState() {
    // init the position using the user location, TODO toggle in settings
    futurePosition =
        Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    futurePosition.then(
        (value) => defaultLatLon = LatLng(value.latitude, value.longitude));

    super.initState();
  }

  @override
  Widget build(context) {
    // TODO-TD: `map` button calculates and redirects here
    // TODO-TD: Display overpasses of favorites
    var mapPage = Scaffold(
      appBar: AppBar(title: const Text("Map"), actions: [
        IconButton(
          icon: const Icon(Icons.lightbulb),
          onPressed: () {
            setState(() {
              if (lightPollution) {
                lightPollution = false;
              } else {
                lightPollution = true;
              }
            });
          },
        ),
      ]),
      body: FlutterMap(
        options: MapOptions(initialCenter: defaultLatLon, initialZoom: 4),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.app',
          ),
          OverlayImageLayer(
            overlayImages: [
              OverlayImage(
                opacity: lightPollution ? 0.5 : 0,
                bounds: LatLngBounds(
                  const LatLng(75, -180),
                  const LatLng(-65, 180),
                ),
                // TODO-TD: Project to Mercator
                // TODO-TD: on tap return brightness value
                imageProvider: const NetworkImage(
                    'https://djlorenz.github.io/astronomy/lp2022/world2022_low3.png'),
              ),
            ],
          ),
          generateTrajectoryLayer([
            [LatLng(0, 0), LatLng(1, 1), LatLng(10, 10)],
            [LatLng(90, 45), LatLng(91, 41), LatLng(95, 30)],
          ]),
          RichAttributionWidget(
            attributions: [
              TextSourceAttribution(
                'OpenStreetMap contributors',
                onTap: () =>
                    launchUrl(Uri.parse('https://openstreetmap.org/copyright')),
              ),
            ],
          ),
        ],
      ),
    );
    return mapPage;
  }
}


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



im.Image projectMercator(
  im.Image image,
  LatLngBounds bounds,
){
  double latCenter = bounds.center.latitude;

  double latNW = bounds.northWest.latitude;
  double lonNW = bounds.northWest.longitude;

  double latSE = bounds.southEast.latitude;
  double lonSE = bounds.southEast.longitude;

  for (final frame in image.frames) {
    final orig = frame.clone(noAnimation: true);
    double w = frame.width - 1;
    double h = frame.height - 1;

    int cx = frame.width ~/ 2;
    int cy = frame.height ~/ 2;
    
    double nCntX = 2 * (cx / w) - 1;
    double nCntY = 2 * (cy / h) - 1;
    
    for (final p in frame) {
      
      var lat = (p.y - cy) / nCntY * (latNW - latSE) / 2 + latCenter;
      final x = ((p.x - cx) / nCntX * (lonSE - lonNW) / 2) / (2*pi);
      final y = log(tan(pi / 4 + lat / 2)) / (2*pi);
      final p2 = orig.getPixelInterpolate(x, y, interpolation: im.Interpolation.nearest);

        p
          ..r = p2.r
          ..g = p2.g
          ..b = p2.b;
    }

  }
  return image;

}

