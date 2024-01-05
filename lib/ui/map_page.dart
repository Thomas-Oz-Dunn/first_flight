import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as im;
import 'package:flutter_map/flutter_map.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../mem/preferences.dart';
import '../mem/orbit.dart';
import '../calc/map.dart';
import '../calc/orbit.dart';
import '../web/celestrak.dart';


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
  late Future<List<String>> futureOrbitNames;
  late Future<List<Orbit>> futureOrbitViews;

  LatLng defaultLatLon = const LatLng(0, 0);
  int nextDay = 60*60*24;
  bool defaultLocateFidelityHigh = false;
  bool isHiFiLocate = false;
  bool lightPollution = true;

  late List<List<LatLng>> passes;

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
    bool? savedData = preferences?.getBool(locationKey);

    if (savedData == null) {
      preferences?.setBool(locationKey, defaultLocateFidelityHigh);
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
    futureOrbitNames = getViewableOrbitIDs();
    futureOrbitNames.then(
      (value) {
        value.map(
          (e) {futureOrbitViews = queryCelestrakID(e);}
        );
      }
    );

    futureOrbitViews.then(
      (value) => value.map(
        (orbit) { 
          passes = calcGroundTrack(
            calcMotion(
              orbit, 
              nextDay, 
              DateTime.now()
            )
          ).map(
            (e) => e.$1
          ) as List<List<LatLng>>;
        }
      )
    );

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
          generateTrajectoryLayer(passes),
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

