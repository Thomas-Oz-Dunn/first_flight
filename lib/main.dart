// External imports
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

// Internal imports
// import 'package:first_flight/vizPage.dart'

const double objSpacing = 10;
const indicatorColor =  Color.fromARGB(255, 15, 83, 157);
const buttonColor = Color.fromARGB(255, 15, 134, 122);

// Goals of the app
// Home Page
// ---------
// Favorites & ISS
// New Satellites
// View/Clear History
// Query Page
// Viz Page
// Request Page
//
// Query Page
// ----------
// 1. Search satellite names
// 2. Connect to Device's GPS or enter manually
// 3. Select API (Default N2YO) 
//    - CELESTRAK 
//    - N2YO
//    - etc
// 4. Query site for data, handle error
// 5. Return next Az, El, time, brightness, trajectory
// 6. Open viz page



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
        primaryColor: indicatorColor,
        hoverColor: buttonColor
      ),
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
  int currentPageIndex = 1;

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
          selectedIcon: Icon(Icons.textsms), 
          icon: Icon(Icons.textsms_outlined), 
          label: 'Feature Request'
        ),
      ];
      
    var pages = <Widget>[
        const CounterPage(),
        Container(
          alignment: Alignment.center,
          child: const Text('Home Page'),
        ),
        const RequestFeaturePage(),
      ];
    
    var mainPageLayout = Scaffold(
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: updatePageIndex,
        indicatorColor: indicatorColor,
        selectedIndex: currentPageIndex,
        destinations: navigationDests,
      ),
      body: pages[currentPageIndex],
    );

    return mainPageLayout;
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

  @override
  Widget build(BuildContext context) {

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
      children: <Widget> [
        FloatingActionButton(
          onPressed: _resetCounter,
          tooltip: 'Reset',
          backgroundColor: Theme.of(context).primaryColor,
          child: const Icon(Icons.refresh),
        ),
      ],
    );

    var pageBody = Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            const Text('The current value is'),
            Text(
              '$_counter', 
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: buttons
            ),
            const SizedBox(height: objSpacing),
            resetButton,
          ],
        ),
      ),
    );

    return pageBody;
  }
}

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
            backgroundColor: buttonColor,
            child: const Icon(
              Icons.file_copy,
              color: Color.fromARGB(185, 255, 255, 255),
              ),
          ),
          const SizedBox(width: objSpacing),
          FloatingActionButton(
            onPressed: _saveRequest,
            tooltip: 'Save',
            backgroundColor: buttonColor,
            child: const Icon(Icons.save,
              color: Color.fromARGB(185, 255, 255, 255)),
          ),
          const SizedBox(width: objSpacing),
          FloatingActionButton(
            onPressed: _clearRequest,
            tooltip: 'Clear',
            backgroundColor: buttonColor,
            child: const Icon(Icons.clear, 
              color: Color.fromARGB(185, 255, 255, 255)),
          ),
       ],
      )
    ];

    var pageLayout = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: widgets
    );

    return pageLayout;
    
  }

  // Submit button
  // - Post to Issue page on GitHub or email
}
