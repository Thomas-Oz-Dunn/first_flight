import 'package:flutter/material.dart';

void main() => runApp(const FirstFlightApp());

class FirstFlightApp extends StatelessWidget {
  const FirstFlightApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'First Flight',
      theme: ThemeData(
        useMaterial3: true,
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
  int currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    const dests = <Widget>[
        NavigationDestination(
          selectedIcon: Icon(Icons.home),
          icon: Icon(Icons.home_outlined),
          label: 'Home',
        ),
        NavigationDestination(
          selectedIcon: Icon(Icons.square),
          icon: Icon(Icons.square_outlined),
          label: 'Counter',
        ),
        NavigationDestination(
          selectedIcon: Icon(Icons.circle),
          icon: Icon(Icons.circle_outlined),
          label: 'Second Page',
        ),
      ];
      
    var pages = <Widget>[
        Container(
          alignment: Alignment.center,
          child: const Text('Page 1'),
        ),
        const CounterPage(title: 'Counter Page'),
        Container(
          alignment: Alignment.center,
          child: const Text('Page 2'),
        ),
      ];
    
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {currentPageIndex = index;});
        },
        indicatorColor: Colors.blue[800],
        selectedIndex: currentPageIndex,
        destinations: dests,
      ),
      body: pages[currentPageIndex],
    );
  }
}

// Second page
class CounterPage extends StatefulWidget {
  final String title;
  const CounterPage({super.key, required this.title});

  @override
  State<CounterPage> createState() => _CounterPageState();
}


// Store counter when on other pages
class _CounterPageState extends State<CounterPage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {_counter++;});
  }

  void _decrementCounter() {
    setState(() {_counter--;});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('The current value is'),
            Text('$_counter', style: Theme.of(context).textTheme.headlineMedium,),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                FloatingActionButton(
                  onPressed: _decrementCounter,
                  tooltip: 'Decrement',
                  child: const Icon(Icons.exposure_minus_1),
                ),
                FloatingActionButton(
                  onPressed: _incrementCounter,
                  tooltip: 'Increment',
                  child: const Icon(Icons.exposure_plus_1),
                ), 
              ]
            ),
          ],
        ),
      ), 
    );
  }
}
