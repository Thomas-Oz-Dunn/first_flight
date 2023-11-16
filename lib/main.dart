import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

var indicatorColor = Colors.blue[800];

void main() => runApp(const FirstFlightApp());

class FirstFlightApp extends StatelessWidget {
  const FirstFlightApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'First Flight',
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: Colors.blue[500],
        hoverColor: Colors.blue[100]
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
          selectedIcon: Icon(Icons.abc),
          icon: Icon(Icons.abc_outlined),
          label: 'Text',
        ),
      ];
      
    var pages = <Widget>[
        const CounterPage(title: 'Counter Page'),
        Container(
          alignment: Alignment.center,
          child: const Text('Home Page'),
        ),
        const TextPage(),
      ];
    
    var layout = Scaffold(
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: updatePageIndex,
        indicatorColor: indicatorColor,
        selectedIndex: currentPageIndex,
        destinations: navigationDests,
      ),
      body: pages[currentPageIndex],
    );

    return layout;
  }
}

// Text Field Page
class TextPage extends StatelessWidget {
  const TextPage({super.key});

  @override
  Widget build(BuildContext context) {
    const searchBox = TextField(
      decoration: InputDecoration(
        border: OutlineInputBorder(),
        hintText: 'Enter a search term',
      ),
    );

    return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            child: searchBox
          ),
        ],
    );
  }
}

// Counter page
class CounterPage extends StatefulWidget {
  final String title;
  const CounterPage({super.key, required this.title});

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
      const SizedBox(width: 20),
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
            const SizedBox(height: 20),
            resetButton,
          ],
        ),
      ),
    );

    return pageBody;
  }
}
