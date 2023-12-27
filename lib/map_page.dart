import 'package:flutter/material.dart';
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
                // TODO-TD: on tap return brightnesds value
                imageProvider: const NetworkImage(
                    'https://djlorenz.github.io/astronomy/lp2022/world2022_low3.png'),
              ),
            ],
          ),
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

Image projectMercator(
  Image image,
  LatLngBounds bounds,
) {
  final w = image.width! - 1;
  final h = image.height! - 1;
  final cx = image.width! ~/ 2;
  final cy = image.height! ~/ 2;
  final nCntX = 2 * (cx / w) - 1;
  final nCntY = 2 * (cy / h) - 1;

  final latCenter = bounds.center.latitude;
  final lonCenter = bounds.center.longitude;

  // pixel to km

  // deg / pixel vert horiz
  // lat = y_km / R_earth + latCenter
  // long = x_km / R_earth + lonCenter

  // interpolate to new image
  // X_km = R_earth * (long - long_center)
  // Y_km = R_earth * ln(tan(pi / 4 + lat / 2))

  // km to pixel
  return image;
}
