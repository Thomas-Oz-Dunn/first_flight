// External imports
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
// import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';

// Internal imports
import 'package:first_flight/style.dart';
import 'package:first_flight/settings_page.dart';
import 'package:first_flight/favorites_page.dart';
import 'package:first_flight/location_page.dart';
import 'package:first_flight/camera_page.dart';
import 'package:first_flight/feature_request_page.dart';

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
          canvasColor: gray),
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
  int defaultPageIndex = 1;
  int currentPageIndex = 1;

  @override
  void initState() {
    super.initState();
    FlutterNativeSplash.remove();
  }

  @override
  Widget build(BuildContext context) {
    var mainPage = Container(
        alignment: Alignment.center,
        child: Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(
                  Icons.star,
                ),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage()),);
                },
              ),
              title: const Text('Home'),
            ),
            body: GridView.count(crossAxisCount: 3, children: <Widget>[
              IconButton(
                icon: const Icon(Icons.sms),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const RequestFeaturePage()),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.camera),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CameraPage()),
                  );
                },
              ),
            ])));

    var pages = <Widget>[
      const LocaterPage(),
      mainPage,
      const FavoritesPage(),
    ];

    var mainPageLayout = Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        elevation: 4.0,
        icon: const Icon(Icons.home),
        label: const Text('Home'),
        onPressed: () {
          currentPageIndex = defaultPageIndex;
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      body: pages[currentPageIndex],
      bottomNavigationBar: BottomAppBar(
        notchMargin: 24,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                setState(() {
                  if (currentPageIndex != 0) {
                    currentPageIndex--;
                  }
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: () {
                setState(() {
                  if (currentPageIndex != pages.length) {
                    currentPageIndex++;
                  }
                });
              },
            )
          ],
        ),
      ),
    );

    return mainPageLayout;
  }
}
