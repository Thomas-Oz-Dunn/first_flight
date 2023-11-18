
class Trajectory extends Object {
  
  final String name;
  final double Az_0;
  final double Az_f;
  final double El_0;
  final double El_f;
  final double brightness;
  final List<int> StartDatetime;
  final List<int> Duration;


  Trajectory({
    required this.name,
    required this.Az_0,
    required this.Az_f,
    required this.El_0,
    required this.El_f,
    required this.brightness,
    required this.StartDatetime,
    required this.Duration,
  })


};
