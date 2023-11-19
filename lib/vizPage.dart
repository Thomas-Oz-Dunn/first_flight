import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

import 'package:first_flight/types.dart';

class VizPage extends StatefulWidget{
  
  const VizPage({super.key});

  @override
  State<VizPage> createState() => _VizPageState();
}


// Viz Page
// --------
// 1. Load Az, El, time, bright 
// 2. Convert into Az, El, time, brightness, trajectory into path, save
// 3. Open front camera view
// 4. Access device Gyroscope & Compass for orientation
//    At first startup on devide
//    Have user start North, then UP, then East to calibrate sensor
// 4. Display trajectory on night sky
// 5. Share or save trajectory
class _VizPageState extends State<VizPage> {
  final ImagePicker _picker = ImagePicker();

  dynamic _getTrajError;
  Trajectory currentTrajectory;

  // Default most recent or ISS?
  SharedPreferences? preferences;

  Future<void> queryStorage(queryKey) async {
    preferences = await SharedPreferences.getInstance();

    if (preferences?.getKeys().contains(queryKey) == true) {
      try {
        Object? savedData = preferences?.get(queryKey);
        if (savedData != null){
          setState(() {
            currentTrajectory = savedData as Trajectory;
          });
        }
      } catch(e) {
        setState(() {
          _getTrajError = e;
        });
      }
  }
  }

  Future<void> getCurrentCamera() async
  { 
    setState(() {
      _mediaFileList = _picker.pickImage(source: ImageSource.camera,);
    });
  }

  @override
  Widget build(BuildContext context) {
    var pageBody = Scaffold(
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          if (_picker.supportsImageSource(ImageSource.camera))
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: FloatingActionButton(
                onPressed: () {
                  getCurrentCamera();
                },
                heroTag: 'image2',
                tooltip: 'Get camera',
                child: const Icon(Icons.camera_alt),
              ),
            ),
        ],
      ),
    );

    return pageBody;
}
  }
