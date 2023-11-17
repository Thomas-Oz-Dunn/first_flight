import 'package:flutter/widgets.dart';

class VizPage extends StatefulWidget{
  
  const VizPage({super.key});

  @override
  State<VizPage> createState() => _VizPageState();
}


// Viz Page
// --------
// 1. Convert into Az, El, time, brightness, trajectory into path, save
// 2. Open front camera view
// 3. Access device Gyroscope & Compass for orientation
//    At first startup on devide
//    Have user start North, then UP, then East to calibrate sensor
// Display trajectory on night sky
// Share or save trajectory
class _VizPageState extends State<VizPage> {
    


}