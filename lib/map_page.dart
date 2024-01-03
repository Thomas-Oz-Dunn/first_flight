import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as im;
import 'dart:math';
import 'package:flutter_map/flutter_map.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import 'theme_handle.dart';

const DEG_TO_RAD = pi / 180;

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  SharedPreferences? preferences;

  // NetworkImage imageProvider = const NetworkImage(
  //   'https://djlorenz.github.io/astronomy/lp2022/world2022_low3.png'
  // );
  // FileImage imageProvider = FileImage(File('lib/world_light_pollution.png'));

  FileImage imageProvider = FileImage(File('lib/world_light_pollution_mercator.png'));

  late Future<Position> futurePosition;
  LatLng defaultLatLon = const LatLng(0, 0);

  bool defaultLocateFidelityHigh = false;
  bool isHiFiLocate = false;
  bool lightPollution = true;

  LatLngBounds lightPolutionBounds = LatLngBounds(
    const LatLng(75, -180),
    const LatLng(-65, 180),
  );

  void runProjection(){
    // TODO-TD: Solve why image is loaded in black and white
    im.decodePngFile(
      'C:\\Users\\tomde\\Projects\\first_flight\\first_flight\\lib\\world_light_pollution.png'
      ).then(
      (value) {
        im.Image imb = projectMercatorImage(value!, lightPolutionBounds);
        im.encodePngFile(
          'C:\\Users\\tomde\\Projects\\first_flight\\first_flight\\lib\\world_light_pollution_mercator.png', 
          imb
        );
      }
    );
  }

  void loadLocationFidelity(){
    bool? savedData = preferences?.getBool(LOCATION_KEY);

    if (savedData == null) {
      preferences?.setBool(LOCATION_KEY, defaultLocateFidelityHigh);
      isHiFiLocate = defaultLocateFidelityHigh;
    } else {
      isHiFiLocate = savedData;
    }
    setState(() {});
  }

  Future<void> initStorage() async {
    preferences = await SharedPreferences.getInstance();
    loadLocationFidelity();    
    setState(() {});
  }

  Future<void> setPos() async {
    futurePosition = Geolocator.getCurrentPosition(
      desiredAccuracy: isHiFiLocate 
        ? LocationAccuracy.medium 
        : LocationAccuracy.lowest
      );

    futurePosition.then((value) => defaultLatLon = LatLng(
        value.latitude, 
        value.longitude
      ));
      
    setState(() {});
  }

  @override
  void initState() {
    initStorage();
    super.initState();
  }

  @override
  Widget build(context) {
    runProjection();
    // TODO-TD: Display overpasses of favorites and view
    var mapPage = Scaffold(
      appBar: AppBar(
        title: const Text("Map"), 
        actions: [
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
        ]
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: defaultLatLon, 
          initialZoom: 2,
          onTap:(tapPosition, point) {
            if (lightPollution){
              // TODO-TD: Find nearest trajectory to tap within tolerance to open
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
                imageProvider: imageProvider,
              ),
            ],
          ),
          generateTrajectoryLayer([
            const [LatLng(45, 45), LatLng(50, 41), LatLng(70, 30)],
            const [LatLng(-20, 0), LatLng(20, 0)],
            const [LatLng(0, -20), LatLng(0, 20)],
          ]),
          RichAttributionWidget(
            attributions: [
              TextSourceAttribution(
                'OpenStreetMap contributors',
                onTap: () =>
                  launchUrl(
                    Uri.parse('https://openstreetmap.org/copyright')
                  ),
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
      double latRad = latDeg * DEG_TO_RAD;

      double newLatRad = 2 * atan(pow(e, latRad)) - pi / 2;

      double srcLatDeg = newLatRad / DEG_TO_RAD - latCenter;
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
