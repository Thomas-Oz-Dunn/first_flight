import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'favorites_page.dart';
import 'theme_handle.dart';
import 'settings_page.dart';
import 'orbit_page.dart';
import 'news_page.dart';
import 'map_page.dart';


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
                    primaryColor: Colors.black,
                    colorScheme: const ColorScheme.highContrastDark(
                      primary: Colors.black87,
                      primaryContainer: Colors.black45,
                      secondary: Color.fromARGB(255, 74, 20, 140),
                      secondaryContainer: Color.fromARGB(255, 55, 71, 79),
                    ),
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
  String celestrakJsonFormat = "&FORMAT=JSON";
  bool emptySearchbar = true;

  final TextEditingController _searchController = TextEditingController();
  int defaultPageIndex = 2;
  int currentPageIndex = 2;

  SharedPreferences? preferences;

  List<String> history = [];
  List<String> favorites = [];

  
  @override
  void initState() {
    FlutterNativeSplash.remove();
    initStorage();

    futureOrbits = queryCelestrak('ISS');

    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> initStorage() async {
    preferences = await SharedPreferences.getInstance();
    loadFavorites();
    loadHistory();
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

  void _addFavorite(name) {
    favorites.add(name);
    preferences?.setStringList(FAVORITES_KEY, favorites);
    setState(() {});
  }

  void _addToHistory(name) {
    // TODO-TD: store chronology datetime of searches
    history.add(name);
    preferences?.setStringList(HISTORY_KEY, history);
    setState(() {});
  }

  void _removeFromFavorites(name) {
    favorites.remove(name);
    preferences?.setStringList(FAVORITES_KEY, favorites);
    setState(() {});
  }

  void _removeFromHistory(name) {
    history.remove(name);
    preferences?.setStringList(HISTORY_KEY, history);
    setState(() {});
  }

  Future<List<Orbit>> queryCelestrak(String name){
    String query = celestrakSite + celestrakName + name + celestrakJsonFormat;
    futureOrbits = fetchOrbits(query);
    return futureOrbits;
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
      
    var historyListBuilder = ListView.builder(
      itemBuilder: (context, itemIdxs) {
        if (itemIdxs < history.length) {
          int backIdx = history.length - 1 -itemIdxs;
          var buttonOptions = [
            MenuItemButton(
              onPressed: () =>
                  setState(() {
                    queryCelestrak(history[backIdx]);
                    _searchController.text = history[backIdx];
                    currentPageIndex = 3;
                    Navigator.pop(context);
                    // TODO-TD: reset view to search page
                  }),
              child: const Text('Re-Search'),
            ),
            MenuItemButton(
              onPressed: () => 
                setState(() {
                  _removeFromHistory(history[backIdx]);
                  // TODO-TD: refresh view of page
                }),
              child: const Text('Remove'),
            ),
          ];

          var historyTiles = ListTile(
            title: Text(history[backIdx]),
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

    
    // view
    // TODO-TD: Interface with gyroscope for celestial sphere
    var homePage = Scaffold(
      appBar: AppBar(
        leading: settingsButton,
        title: const Text('SaTrack'),
        actions: [favoritesButton],
      ),
      body: Center(child: Text('View Page TODO')),
    );

    // history
    var historyPage = Scaffold(
      appBar: AppBar(title: const Text('Search History')),
      body: historyListBuilder
    );

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
                          // TODO-TD: store list of orbits to be viewed and mapped
                        }),
                    child: const Text('Map'),
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
                  Orbit orbit = orbits[itemIdxs];
                  var orbitTile = ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => OrbitPage(
                              orbit: orbit
                            )
                          ),
                      );
                    },
                    title: Text(orbit.objectName),
                    // TODO-TD: next pass in subtitle
                    subtitle: Text('Epoch Date Time (UTC): ${orbit.epoch}'),
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

    var exploreTiles = Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, 
          crossAxisSpacing: 10,
          childAspectRatio: 2,
        ),
        children: [
          // TODO-TD: autoscale from list of categories 
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.blueGrey,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(2)),
              ),
            ),
            child: const Text('Recent Launches'),
            onPressed: () {
              setState(() {
                futureOrbits = fetchOrbits(
                  '${celestrakSite}GROUP=last-30-days$celestrakJsonFormat'
                );
              });
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Scaffold(
                    appBar: AppBar(title: const Text("Recent Launches")),
                    body: searchResultsBuilder,
                  )
                ),
              );
            },
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(2)),
              ),
            ),
            child: const Text('Space Stations'),
            onPressed: () {
              setState(() {
                futureOrbits = fetchOrbits(
                  '${celestrakSite}GROUP=stations$celestrakJsonFormat'
                );
              });
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Scaffold(
                    appBar: AppBar(title: const Text("Space Stations")),
                    body: searchResultsBuilder,
                  )
                ),
              );
            },
          ),
        ]
      )
    );

    var searchpageBody = Scaffold(
      appBar: null,
      body: emptySearchbar ? exploreTiles : searchResultsBuilder,
    );

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
                emptySearchbar = false;
                _addToHistory(_searchController.text);
                queryCelestrak(_searchController.text);
              } else {
                setState(() {
                  emptySearchbar = true;
                });
              }
            },
          ),
          hintText: 'Search Satellites',
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear_rounded),
            onPressed: () {
              setState(() {
                _searchController.text = ""; 
                emptySearchbar = true;
              });
            }
          ),
        ),
        onSubmitted: (value) { 
          if (value.trim() == ""){
            setState(() {
              emptySearchbar = true;
            });
          } else {
            emptySearchbar = false;
            _addToHistory(value);
            queryCelestrak(value);
          }
        },
        ),
      );

    var historyButton = IconButton(
      icon: const Icon(Icons.history),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => historyPage
          ),
        );
      },
    );

    var searchPage = Scaffold(
      appBar: AppBar(
        leading: null,
        title: searchBar,
        actions: [historyButton],
      ),
      body: searchpageBody,
    );

    var pages = <Widget>[
      const MapPage(),
      const NewsPage(),
      homePage,
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
          selectedIcon: Icon(Icons.home),
          icon: Icon(Icons.home_outlined),
          label: 'Home',
        ),
        NavigationDestination(
          selectedIcon: Icon(Icons.search), 
          icon: Icon(Icons.search_outlined), 
          label: 'Search'
        ),
      ],
    );
        
    var mainPageLayout = Scaffold(
      body: pages[currentPageIndex],
      bottomNavigationBar: navBar,
    );

    return mainPageLayout;
  }
}
