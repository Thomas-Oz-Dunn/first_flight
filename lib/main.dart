import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
// import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'favorites_page.dart';
import 'theme_handle.dart';
import 'settings_page.dart';
import 'orbit_page.dart';
import 'news_page.dart';


const FAVORITES_KEY = "Favorites";
const HISTORY_KEY = "History";

enum SampleItem { load, favorite, remove, share }

void main() {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  runApp(const SecondFlightApp());
}

class SecondFlightApp extends StatelessWidget {
  const SecondFlightApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ModelThemeProvider(),
      child: Consumer<ModelThemeProvider>(
          builder: (context, ModelThemeProvider themeNotifier, child) {
            return MaterialApp(
              title: 'Second Flight',
              theme: themeNotifier.isDark
                ? ThemeData(
                    brightness: Brightness.dark,
                    useMaterial3: true
                  )
                : ThemeData(
                    brightness: Brightness.light,
                    primaryColor: Colors.blue,
                    primarySwatch: Colors.blueGrey,
                    useMaterial3: true
                  ),
              debugShowCheckedModeBanner: false,
              home: const MainPage(),
            );
          }
        )
      );
    }
  }

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late Future<List<Orbit>> futureOrbits;

  String celestrakSite = "https://celestrak.org/NORAD/elements/gp.php?";
  String celestrakName = "NAME=";
  String celestrakRecent = "GROUP=last-30-days";
  String celestrakJsonFormat = "&FORMAT=JSON";

  final TextEditingController _searchController = TextEditingController();

  int defaultPageIndex = 2;
  int currentPageIndex = 2;

  SharedPreferences? preferences;

  List<String> history = [];
  List<String> favorites = [];

  // init the position using the user location
  // final mapController = MapController.withUserPosition(
  //   trackUserLocation: UserTrackingOption(
  //     enableTracking: true,
  //     unFollowUser: false,
  //   )
  // );
  
  @override
  void initState() {
    FlutterNativeSplash.remove();
    initStorage();
    loadHistory();

    String recentLaunchApi = celestrakSite + celestrakRecent + celestrakJsonFormat;
    futureOrbits = fetchOrbits(recentLaunchApi);
    
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _searchController.dispose();
  }

  Future<void> initStorage() async {
    preferences = await SharedPreferences.getInstance();
    loadFavorites();
    loadHistory();
    setState(() {});
  }

  void _addFavorite(name) {
    List<String>? savedData = preferences?.getStringList(FAVORITES_KEY);
    if (savedData != null) {
      favorites = savedData;
    }
    favorites.add(name);
    preferences?.setStringList(FAVORITES_KEY, favorites);
    setState(() {});
  }

  // Manage search history
  void _addToHistory(name) {
    // TODO-TD: store chronology datetime of searches
    history.add(name);
    preferences?.setStringList(HISTORY_KEY, history);
    setState(() {});
  }

  void loadFavorites() {
    List<String>? savedData = preferences?.getStringList(FAVORITES_KEY);

    if (savedData == null) {
      preferences?.setStringList(FAVORITES_KEY, favorites);
    } else {
      favorites = savedData;
    }
    setState(() {});
  }

  void loadHistory() {
    List<String>? savedData = preferences?.getStringList(HISTORY_KEY);

    if (savedData == null) {
      preferences?.setStringList(HISTORY_KEY, history);
    } else {
      history = savedData;
    }
    setState(() {});
  }

  void _removeFromHistory(name) {
    history.remove(name);
    preferences?.setStringList(HISTORY_KEY, history);
    setState(() {});
  }

  @override
  Widget build(BuildContext context){

    var settingsButton = IconButton(
      icon: const Icon(Icons.settings),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const SettingsPage()),
        );
      },
    );

    var favoritesButton = IconButton(
        icon: const Icon(Icons.favorite_border),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const FavoritesPage()),
          );
        },
      );
      
    Widget buildHistoryList(){
      loadHistory();
      // Add search bar to filter history list
      var historyListBuilder = ListView.builder(
        itemBuilder: (context, itemIdxs) {
          if (itemIdxs < history.length) {
            var buttonOptions = [
              MenuItemButton(
                onPressed: () =>
                    setState(() {
                      // TODO-TD: store list of orbits being viewed
                    }),
                child: const Text('View'),
              ),
              MenuItemButton(
                onPressed: () => 
                  setState(() {
                    _addFavorite(history[itemIdxs]);
                  }),
                child: const Text('Favorite'),
              ),
              MenuItemButton(
                onPressed: () => 
                  setState(() {
                    _removeFromHistory(history[itemIdxs]);
                  }),
                child: const Text('Remove'),
              ),
            ];

            var historyTiles = ListTile(
              title: Text(history[itemIdxs]),
              trailing: MenuAnchor(
                menuChildren: buttonOptions,
                builder:
                  (
                    BuildContext context, 
                    MenuController controller, 
                    Widget? child
                  ) {
                    var menuButton = IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () {
                        if (controller.isOpen) {
                          controller.close();
                        } else {
                          controller.open();
                        }
                      },
                    );
                  return menuButton;
                }
              )
            );
            return historyTiles;
          }
        },
      );
      return historyListBuilder;
    }

    // var OpenMap = OSMFlutter( 
    //     controller: mapController,
    //     osmOption: OSMOption(
    //           userTrackingOption: UserTrackingOption(
    //           enableTracking: true,
    //           unFollowUser: false,
    //         ),
    //         zoomOption: ZoomOption(
    //               initZoom: 8,
    //               minZoomLevel: 3,
    //               maxZoomLevel: 19,
    //               stepZoom: 1.0,
    //         ),
    //         userLocationMarker: UserLocationMaker(
    //             personMarker: MarkerIcon(
    //                 icon: Icon(
    //                     Icons.location_history_rounded,
    //                     color: Colors.red,
    //                     size: 48,
    //                 ),
    //             ),
    //             directionArrowMarker: MarkerIcon(
    //                 icon: Icon(
    //                     Icons.double_arrow,
    //                     size: 48,
    //                 ),
    //             ),
    //         ),
    //         roadConfiguration: RoadOption(
    //                 roadColor: Colors.yellowAccent,
    //         ),
    //         markerOption: MarkerOption(
    //             defaultMarker: MarkerIcon(
    //                 icon: Icon(
    //                   Icons.person_pin_circle,
    //                   color: Colors.blue,
    //                   size: 56,
    //                 ),
    //             )
    //         ),
    //     )
    // );

    // map 
    // TODO-TD: Open street map of location and overpasses of favorites or view
    const mapPage = Scaffold(
      body: Center( child: Text('Map Page TODO')),
    );

    var newsPage = Scaffold(
      body: newsFeedBuilder,
    );
    
    // view
    // TODO-TD: Interface with gyroscope for celestial sphere
    const viewPage = Scaffold(
      body: Center(child: Text('View Page TODO')),
    );

    // history
    var historyPage = Scaffold(
      body: buildHistoryList()
    );

    Future<List<Orbit>> queryCelestrak(String name){
      String query = celestrakSite + celestrakName + name + celestrakJsonFormat;
      futureOrbits = fetchOrbits(query);
      _addToHistory(name);
      return futureOrbits;
    }

    var searchResultsBuilder = 
      FutureBuilder<List<Orbit>>(
        future: futureOrbits,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List<Orbit> orbits = snapshot.data!;

            return ListView.builder(
              itemBuilder: (context, itemIdxs) {
                var buttonOptions = [
                  MenuItemButton(
                    onPressed: () =>
                        setState(() {
                          // TODO-TD: store list of orbits to be viewed
                        }),
                    child: const Text('View'),
                  ),
                  MenuItemButton(
                    onPressed: () => 
                      setState(() {
                        _addFavorite(orbits[itemIdxs].objectName);
                      }),
                    child: const Text('Favorite'),
                  ),
                ];

                if (itemIdxs < orbits.length) {
                  var orbitTile = ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => OrbitPage(
                              orbit: orbits[itemIdxs]
                            )
                          ),
                      );
                    },
                    title: Text(orbits[itemIdxs].objectName),
                    subtitle: Text('ID: ${orbits[itemIdxs].objectID}'),
                    trailing: MenuAnchor(
                      menuChildren: buttonOptions,
                      builder:
                        (
                          BuildContext context, 
                          MenuController controller, 
                          Widget? child
                        ) {
                          var menuButton = IconButton(
                            icon: const Icon(Icons.more_vert),
                            onPressed: () {
                              if (controller.isOpen) {
                                controller.close();
                              } else {
                                controller.open();
                              }
                            },
                          );
                        return menuButton;
                      }
                    )
                  );
                  return orbitTile;
                }
            }
          );

          } else if (snapshot.hasError) {
            return Text('${snapshot.error}');
          }
          return const CircularProgressIndicator();
        },
      );

    // search
    var searchBar = Container(
      height: 40,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(5)),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          prefixIcon: IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {
              if (_searchController.text != ""){
                queryCelestrak(_searchController.text);
              }
            },
          ),
          hintText: 'Search Orbits',
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear_rounded),
            onPressed: () {_searchController.text = "";}
          ),
        ),
        // TODO-TD: display history matches as options before submit?
        // onChanged: (value) => _queryCelestrak(value), 
        onSubmitted: (value) => queryCelestrak(value),
        ),
      );

    var searchPage = Scaffold(
      appBar: AppBar(
        leading: null,
        title: searchBar,
      ),
      body: searchResultsBuilder,
    );

    var pages = <Widget>[
      mapPage,
      newsPage,
      viewPage,
      historyPage,
      searchPage,
    ];

    var navBar = NavigationBar(
      onDestinationSelected: (int index) {
        setState(() {currentPageIndex = index;});
      },
      selectedIndex: currentPageIndex,
      destinations: const <Widget>[
        NavigationDestination(
          selectedIcon: Icon(Icons.map),
          icon: Icon(Icons.map_outlined),
          label: 'Map',
        ),
        NavigationDestination(
          selectedIcon: Icon(Icons.newspaper),
          icon: Icon(Icons.newspaper_outlined),
          label: 'News',
        ),
        NavigationDestination(
          selectedIcon: Icon(Icons.satellite),
          icon: Icon(Icons.satellite_outlined),
          label: 'View',
        ),
        NavigationDestination(
          selectedIcon: Icon(Icons.history),
          icon: Icon(Icons.history_outlined),
          label: 'History',
        ),
        NavigationDestination(
          selectedIcon: Icon(Icons.search), 
          icon: Icon(Icons.search_outlined), 
          label: 'Search'
        ),
      ],
    );
        
    var mainPageLayout = Scaffold(
      appBar: AppBar(
        leading: settingsButton,
        title: const Text('SaTrack'),
        actions: [favoritesButton],
      ),
      body: pages[currentPageIndex],
      bottomNavigationBar: navBar,
    );

    return mainPageLayout;
  }
}
