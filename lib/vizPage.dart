import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  // Default most recent or ISS?
  SharedPreferences? preferences;
  var currentTrajectory;
  var defaultTrajectory;

  Future<void> initStorage() async {
    preferences = await SharedPreferences.getInstance();

    // init 1st time to defaultValue
    Set<String>? availableKeys = preferences?.getKeys();

    // Key = Name-StartDatetime
    // Name string
    // Az_0 float
    // El_0 float
    // StartDatetime List of ints yy, mm, dd, hh, mm, ss
    // Duration List of ints mm ss
    // Az_f float
    // El_f float
    // Brightness float

    int? savedData = preferences?.getInt("trajectory");
    
    if (savedData == null) {
      await preferences!.setInt("trajectory", defaultTrajectory);
      currentTrajectory = defaultTrajectory;

    } else {
      currentTrajectory = savedData;

    }

    setState(() {});
  }


}