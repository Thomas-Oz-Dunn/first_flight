// External imports
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';

// Internal imports
// import 'package:first_flight/vizPage.dart'

const double objSpacing = 10;
const teal =  Color.fromARGB(255, 15, 83, 157);
const blue = Color.fromARGB(255, 15, 134, 122);
const white = Color.fromARGB(185, 255, 255, 255);
const black =  Color.fromARGB(255, 0, 0, 5);
const gray =  Color.fromARGB(255, 32, 32, 45);

// Goals of the app
// Produce notifications of any Favorites, ISS, or Starlink
// Support dark mode and light mode
//
// Home Page
// ---------
// [9/10] Favorites & ISS
// [] New/Upcoming Launches
// [] View/Clear History
// [] Query Page
// [] Viz/AR Page


void main() { 
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  runApp(const FirstFlightApp());
}

class FirstFlightApp extends StatelessWidget {
  const FirstFlightApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'First Flight',
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: teal,
        hoverColor: blue,
        primaryColorDark: black,
        canvasColor: gray
      ),
      debugShowCheckedModeBanner: false,
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int currentPageIndex = 0;

  void updatePageIndex(int index) {
      setState(() {currentPageIndex = index;});
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 10), () {
      FlutterNativeSplash.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    const navigationDests = <Widget>[
        NavigationDestination(
          selectedIcon: Icon(Icons.add),
          icon: Icon(Icons.add),
          label: 'Counter',
        ),
        NavigationDestination(
          selectedIcon: Icon(Icons.home),
          icon: Icon(Icons.home_outlined),
          label: 'Home',
        ),
        NavigationDestination(
          selectedIcon: Icon(Icons.star), 
          icon: Icon(Icons.star_outline), 
          label: 'Favorites'
        ),
      ];

    var mainPage = Container(
      alignment: Alignment.center,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Home'),
        ),
        body: GridView.count(
          crossAxisCount: 3,
          children: <Widget>[
            IconButton(
                icon: const Icon(Icons.sms),
                onPressed : (){
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RequestFeaturePage()
                  ),
                );
              }, 
            ),   
            IconButton(
                icon: const Icon(Icons.camera),
                onPressed : (){
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CameraPage()
                  ),
                );
              }, 
            ),   
          ]
        )
      )
    );

    var pages = <Widget>[
        const CounterPage(),
        mainPage,
        const FavoritesPage(),
      ];
    
    var mainPageLayout = Scaffold(
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: updatePageIndex,
        indicatorColor: teal,
        selectedIndex: currentPageIndex,
        destinations: navigationDests,
      ),
      body: pages[currentPageIndex],
      backgroundColor: gray
    );

    return mainPageLayout;
  }
}

// Camera Page
class CameraPage extends StatefulWidget {
  /// Default Constructor
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}


class _CameraPageState extends State<CameraPage> {
  late CameraController controller;
  int rearCamera = 0;
  int frontCamera = 1;

  Future<void> _initCamera() async {
    List<CameraDescription> cameras = await availableCameras();

    CameraController controller = CameraController(
      cameras[frontCamera], 
      ResolutionPreset.max
    );
    
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    }).catchError((Object e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            // Handle access errors here.
            break;
          default:
            // Handle other errors here.
            break;
        }
      }
    });
  }

  @override
  void initState() {
    _initCamera();
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
          child: controller.value.isInitialized ? 
            CameraPreview(controller) : const Center(child: CircularProgressIndicator())
      )
    );
  }
}
// Counter page
class CounterPage extends StatefulWidget {
  const CounterPage({super.key});

  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> {
  int defaultValue = 0;
  int _counter = 0;
  SharedPreferences? preferences;

  bool hasPos = false;
  late Position _currentPosition;
  late List<String> locations;


  void _addLocation(name){
    locations.add(name);
    preferences?.setStringList("Locations", locations);
    setState(() {});
  }

  void _loadLocation(){
    List<String>? savedData = preferences?.getStringList('Locations');
    
    if (savedData == null) {
      preferences?.setStringList("Locations", locations);
    } else {
      locations = savedData;
    }

    setState(() {});
  }

  void _removeLocation(name){
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
      title: const Text(
        'Add new location',
        style: TextStyle(
          color: white
        )
      ),
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
          onPressed: () => Navigator.pop(
            context, 
            _textFieldController.text
          ),
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
            setState((){_addLocation(resultLabel);});
          }
        }
      )
    ];

    var loadSaveLocateButtons;

    var getLocationButton = <Widget>[
        FloatingActionButton(
          backgroundColor: teal,
          foregroundColor: white,
          child: const Text(
            textAlign: TextAlign.center,
            "Get location",
            style: TextStyle(
              color: white
            )
          ),
          onPressed: () {
            _getCurrentLocation();
          },
        ),
        if (hasPos == true) Text(
          "Latitude: ${_currentPosition.latitude}\n"
          "Longitude: ${_currentPosition.longitude}",
          style: const TextStyle(
            color: white
          ),
        ) else const Text(
          'Unknown Location',
          style: TextStyle(
            color: white
          )
        ),
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
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget> [
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
        title: const Text(
          "Counter",
          style: TextStyle(
            color: white
          )
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            const Text(
              'The current value is',
              style: TextStyle(
                color: white
              )
              ),
            Text(
              '$_counter', 
              style: const TextStyle(
                color: white
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: buttons
            ),
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
                children: manualEntryLocationButton
              )
            )
          ],
        ),
      ),
      backgroundColor: gray
    );

    return pageBody;
  }
}

// Feature Request page
class RequestFeaturePage extends StatefulWidget{

  const RequestFeaturePage({super.key});

  @override
  State<RequestFeaturePage> createState() => _RequestFeatureState();

}

class _RequestFeatureState extends State<RequestFeaturePage> {
  String currentRequest = '';
  SharedPreferences? preferences;
  final TextEditingController controller = TextEditingController();
  
  Future<void> initStorage() async {
    preferences = await SharedPreferences.getInstance();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    initStorage();
  }
  
  void _saveRequest() {
    currentRequest = controller.text;
    preferences?.setString("request", currentRequest);
    setState(() {});
  }

  void _loadRequest(){
    String? savedData = preferences?.getString("request");
    
    if (savedData == null) {
      preferences?.setString("request", currentRequest);
    } else {
      currentRequest = savedData;
    }
    controller.text = currentRequest;
    setState(() {});
  }

  void _clearRequest(){
    currentRequest = '';
    controller.text = currentRequest;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    var widgets = <Widget>[
      Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 2 * objSpacing, 
          vertical: objSpacing
        ),
        child: TextField(
          maxLines: 10,
          controller: controller,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Enter a request',
            ),
          ),
      ),
      const SizedBox(height: objSpacing),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FloatingActionButton(
            onPressed: _loadRequest,
            tooltip: 'Load',
            backgroundColor: blue,
            child: const Icon(
              Icons.file_copy,
              color: white,
            ),
          ),
          const SizedBox(width: objSpacing),
          FloatingActionButton(
            onPressed: _saveRequest,
            tooltip: 'Save',
            backgroundColor: blue,
            child: const Icon(
              Icons.save,
              color: white
            ),
          ),
          const SizedBox(width: objSpacing),
          FloatingActionButton(
            onPressed: _clearRequest,
            tooltip: 'Clear',
            backgroundColor: blue,
            child: const Icon(
              Icons.clear, 
              color: white,
            )
          ),
        ],
      )
    ];

    var pageLayout = Scaffold(
      appBar: AppBar(
        backgroundColor: black,
        title: const Text(
          "Feature Request",
          style: TextStyle(
            color: white
          )
          ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: widgets
      ),
      backgroundColor: gray
    );
    
    return pageLayout;
    }
}


// Favorites page
class FavoritesPage extends StatefulWidget{

  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesState();

}

class _FavoritesState extends State<FavoritesPage> {
  SharedPreferences? preferences;
  List<String> favorites = ['First'];

  Future<void> initStorage() async {
    preferences = await SharedPreferences.getInstance();
    setState(() {});
  }

  @override
  void initState() {
    initStorage();
    super.initState();
  }

  void _addFavorite(name){
    favorites.add(name);
    preferences?.setStringList("Favorites", favorites);
    setState(() {});
  }

  void _loadFavorites(){
    List<String>? savedData = preferences?.getStringList('Favorites');
    
    if (savedData == null) {
      preferences?.setStringList("Favorites", favorites);
    } else {
      favorites = savedData;
    }

    setState(() {});
  }

  void _removeFavorite(name){
    favorites.remove(name);
    preferences?.setStringList("Favorites", favorites);
    setState(() {});
  }

  Widget _buildList() {
      _loadFavorites();
      var listBuilder = ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemBuilder: (context, itemIdxs) {
          if (itemIdxs < favorites.length){
              var favoriteTiles = ListTile(
              title: Text(
                favorites[itemIdxs], 
                style: const TextStyle(
                  fontSize: 18.0,
                )
              ),
              trailing: IconButton(
                icon: const Icon(
                  Icons.delete,
                ),
                onPressed: () async {
                  _removeFavorite(favorites[itemIdxs]);
                },
              )
            );
            return favoriteTiles;
          }
        },
      );
      return listBuilder;
    }

  final _textFieldController = TextEditingController();

  Future<String?> _showTextInputDialog(BuildContext context) async {

    var dialogBox = AlertDialog(
      title: const Text(
        'Add new favorite',
        style: TextStyle(
          color: white
        )
      ),
      content: TextField(
        controller: _textFieldController,
        decoration: const InputDecoration(hintText: "New Favorite"),
      ),
      actions: <Widget>[
        ElevatedButton(
          child: const Text("Exit"),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton(
          child: const Text('Add'),
          onPressed: () => Navigator.pop(
            context, 
            _textFieldController.text
          ),
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

    var addFavButtonAppBar = <Widget>[
      IconButton(
        icon: const Icon(
          Icons.star,
        ),
        onPressed: () async {
          var resultLabel = await _showTextInputDialog(context);
          if (resultLabel != null) {
            setState((){_addFavorite(resultLabel);});
          }
        }
      )
    ];

    var pageLayout = Scaffold(
      appBar: AppBar(
        backgroundColor: black,
        title: const Text(
          'Favorites',
          style: TextStyle(
            color: white
          )
        ),
        actions:  addFavButtonAppBar
      ),
      body: _buildList(),
      backgroundColor: gray
    );

    return pageLayout;
  }
}






// Enter sat name
//  - Return either similar names for actual query or TLE
//  - Save either
// Enter location
//  - Use GPS
//  - Manual
// Enter How far ahead to look
// Run
//  Propogate to time
//  Check when overhead lla
//  Check is sunlit, night, and cloudless
//  Return [(start az, el, time, stop az, el, time), ]
// Access gyroscope and magnetometer
// Open Camera
// Display trajectory over camera view

