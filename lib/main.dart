import 'package:flutter/material.dart';

void main() {
  runApp(const FirstFlightApp());
}

class FirstFlightApp extends StatelessWidget {
  const FirstFlightApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'First Flight',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const CounterPage(title: 'First Flight Home Page'),
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
