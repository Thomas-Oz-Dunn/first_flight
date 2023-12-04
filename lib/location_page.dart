import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

import 'package:first_flight/style.dart';

// Location page
class LocaterPage extends StatefulWidget {
  const LocaterPage({super.key});

  @override
  State<LocaterPage> createState() => _LocaterPageState();
}

class _LocaterPageState extends State<LocaterPage> {
  int defaultValue = 0;
  int _counter = 0;
  SharedPreferences? preferences;

  bool hasPos = false;
  late Position _currentPosition;
  late List<String> locations;

  void _addLocation(name) {
    locations.add(name);
    preferences?.setStringList("Locations", locations);
    setState(() {});
  }

  void _loadLocation() {
    List<String>? savedData = preferences?.getStringList('Locations');

    if (savedData == null) {
      preferences?.setStringList("Locations", locations);
    } else {
      locations = savedData;
    }

    setState(() {});
  }

  void _removeLocation(name) {
    locations.remove(name);
    preferences?.setStringList("Locations", locations);
    setState(() {});
  }

  Future<void> initStorage() async {
    preferences = await SharedPreferences.getInstance();

    // init 1st time to defaultValue
    int? savedData = preferences?.getInt("counter");

    if (savedData == null) {
      await preferences!.setInt("counter", defaultValue);
      _counter = defaultValue;
    } else {
      _counter = savedData;
    }

    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    initStorage();
  }

  void _resetCounter() {
    setState(() {
      _counter = defaultValue;
      preferences?.setInt("counter", _counter);
    });
  }

  void _incrementCounter() {
    setState(() {
      _counter = preferences?.getInt("counter") ?? defaultValue;
      _counter++;
      preferences?.setInt("counter", _counter);
    });
  }

  void _decrementCounter() {
    setState(() {
      _counter = preferences?.getInt("counter") ?? defaultValue;
      _counter--;
      preferences?.setInt("counter", _counter);
    });
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

  final _textFieldController = TextEditingController();

  Future<String?> _showTextInputDialog(BuildContext context) async {
    var dialogBox = AlertDialog(
      title: const Text('Add new location', style: TextStyle(color: white)),
      content: TextField(
        controller: _textFieldController,
        decoration: const InputDecoration(hintText: "New Location"),
      ),
      actions: <Widget>[
        ElevatedButton(
          child: const Text("Exit"),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton(
          child: const Text('Add'),
          onPressed: () => Navigator.pop(context, _textFieldController.text),
        ),
      ],
    );

    return showDialog(
        context: context,
        builder: (context) {
          return dialogBox;
        });
  }

  @override
  Widget build(BuildContext context) {
    var manualEntryLocationButton = <Widget>[
      IconButton(
          icon: const Icon(
            Icons.satellite,
          ),
          onPressed: () async {
            var resultLabel = await _showTextInputDialog(context);
            if (resultLabel != null) {
              setState(() {
                _addLocation(resultLabel);
              });
            }
          }),
      IconButton(
          icon: const Icon(
            Icons.download,
          ),
          onPressed: () async {
            var resultLabel = await _showTextInputDialog(context);
            if (resultLabel != null) {
              setState(() {
                _loadLocation();
              });
            }
          }),
    ];

    var getLocationButton = <Widget>[
      FloatingActionButton(
        backgroundColor: teal,
        foregroundColor: white,
        child: const Text(
            textAlign: TextAlign.center,
            "Get location",
            style: TextStyle(color: white)),
        onPressed: () {
          _getCurrentLocation();
        },
      ),
      if (hasPos == true)
        Text(
          "Latitude: ${_currentPosition.latitude}\n"
          "Longitude: ${_currentPosition.longitude}",
          style: const TextStyle(color: white),
        )
      else
        const Text('Unknown Location', style: TextStyle(color: white)),
    ];

    var buttons = <Widget>[
      FloatingActionButton(
        onPressed: _decrementCounter,
        tooltip: 'Decrement',
        backgroundColor: Colors.red,
        child: const Icon(Icons.exposure_minus_1),
      ),
      const SizedBox(width: objSpacing),
      FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        backgroundColor: Colors.green,
        child: const Icon(Icons.exposure_plus_1),
      ),
    ];

    var resetButton = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        FloatingActionButton(
          onPressed: _resetCounter,
          tooltip: 'Reset',
          backgroundColor: Theme.of(context).primaryColor,
          child: const Icon(Icons.refresh),
        ),
      ],
    );

    const spacer = SizedBox(height: objSpacing);

    var pageBody = Scaffold(
        appBar: AppBar(
          backgroundColor: black,
          title: const Text("Counter", style: TextStyle(color: white)),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              const Text('The current value is',
                  style: TextStyle(color: white)),
              Text(
                '$_counter',
                style: const TextStyle(color: white),
              ),
              Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: buttons),
              spacer,
              resetButton,
              spacer,
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: getLocationButton,
                ),
              ),
              Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: manualEntryLocationButton))
            ],
          ),
        ),
        backgroundColor: gray);

    return pageBody;
  }
}
