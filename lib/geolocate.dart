import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocaterPage extends StatefulWidget {
  const LocaterPage({super.key});

  @override
  State<LocaterPage> createState() => _LocaterPageState();
}

class _LocaterPageState extends State<LocaterPage> {
  bool hasPos = false;
  late Position _currentPosition;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Location"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FloatingActionButton.large(
              backgroundColor: Colors.blueGrey,
              foregroundColor: Colors.white,
              child: const Text("Get location"),
              onPressed: () {
                _getCurrentLocation();
              },
            ),
            const SizedBox(height: 10),
            if (hasPos == true) Text(
              "LAT: ${_currentPosition.latitude}\n"
              "LNG: ${_currentPosition.longitude}"
            ),
          ],
        ),
      ),
    );
  }

  void _getCurrentLocation() {
    Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best, 
        forceAndroidLocationManager: true)
      .then((Position position) {
        setState(() {
          _currentPosition = position;
          hasPos = true;
        });
      }).catchError((e) {
          hasPos = false;
      });
  }
}
