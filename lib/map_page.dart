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
  NetworkImage imageProvider = const NetworkImage(
    'https://djlorenz.github.io/astronomy/lp2022/world2022_low3.png'
  );

  late Future<Position> futurePosition;
  LatLng defaultLatLon = LatLng(0, 0);

  bool lightPollution = true;

  LatLngBounds lightPolutionBounds = LatLngBounds(
    const LatLng(75, -180),
    const LatLng(-65, 180),
  );

  runProjection(){
    im.decodePngFile(
      'C:\\Users\\tomde\\Projects\\first_flight\\first_flight\\lib\\world_light_pollution.png'
      ).then(
      (value) {
        im.Image imb = projectMercator(value!, lightPolutionBounds);
        im.writeFile(
          'C:\\Users\\tomde\\Projects\\first_flight\\first_flight\\lib\\world_light_pollution_mercator.png', 
          imb.getBytes()
        );
      }
    );

  }
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
    runProjection();

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
        options: MapOptions(
          initialCenter: defaultLatLon, 
          initialZoom: 4,
          onTap:(tapPosition, point) {
            if (lightPollution){
              // TODO-TD: Find nearest trajectory, tolerance?
              point.latitude;
              point.longitude;
            }
          },
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.app',
          ),
          OverlayImageLayer(
            overlayImages: [
              OverlayImage(
                opacity: lightPollution ? 0.5 : 0,
                bounds: lightPolutionBounds,
                // TODO-TD: Project to Mercator
                imageProvider: imageProvider,
              ),
            ],
          ),
          generateTrajectoryLayer([
            const [LatLng(0, 0), LatLng(1, 1), LatLng(10, 10)],
            const [LatLng(45, 45), LatLng(50, 41), LatLng(70, 30)],
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

  double latSE = bounds.southEast.latitude;

  for (final frame in image.frames) {
    var newFrame = frame.clone(noAnimation: true);
    double h = frame.height - 1;

    int cy = frame.height ~/ 2;
  
    for (final newPixel in newFrame) {
      var normFromCenter = (newPixel.y - cy) / h; 
      double nwLat = normFromCenter * (latNW - latSE) + latCenter;
      double origX = newPixel.x - 0.0;
      double t = tan(pi / 4 + nwLat * pi / 360);
      double origY = log(t) / (2 * pi) * h + cy;

      final p2 = frame.getPixelInterpolate(
        origX, 
        origY, 
        interpolation: im.Interpolation.nearest
      );

      newPixel
        ..r = p2.r
        ..g = p2.g
        ..b = p2.b;
    }

  }
  return image;

}

