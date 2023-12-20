import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
// import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// TODO-TD: create custom data type for loading/saving

enum SampleItem { load, favorite, remove, share }

class MyThemePreferences {
  static const THEME_KEY = "theme_key";

  setTheme(bool value) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setBool(THEME_KEY, value);
  }

  getTheme() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return sharedPreferences.getBool(THEME_KEY) ?? false;
  }
}

class Album {
  final int userId;
  final int id;
  final String title;
  final String body;

  const Album({
    required this.userId,
    required this.id,
    required this.title,
    required this.body,
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'userId': int userId,
        'id': int id,
        'title': String title,
        'body': String body,
      } =>
        Album(
          userId: userId,
          id: id,
          title: title,
          body: body,
        ),
      _ => throw const FormatException('Failed to load album.'),
    };
  }
}

Future<Album> fetchAlbum(String url) async  {
  final response = await http
      .get(Uri.parse(url));
      
  if (response.statusCode == 200) {
    // If the server did return a 200 OK response,
    // then parse the JSON.
    return Album.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  } else {
    // If the server did not return a 200 OK response,
    // then throw an exception.
    throw Exception('Failed to load album');
  }
}

class ModelThemeProvider extends ChangeNotifier {
  late bool _isDark;
  late MyThemePreferences _preferences;
  bool get isDark => _isDark;

  ModelThemeProvider() {
    _isDark = false;
    _preferences = MyThemePreferences();
    getPreferences();
  }

  // Switching the themes
  set isDark(bool value) {
    _isDark = value;
    _preferences.setTheme(value);
    notifyListeners();
  }

  getPreferences() async {
    _isDark = await _preferences.getTheme();
    notifyListeners();
  }
}

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
  String placeholder = 'https://jsonplaceholder.typicode.com/albums/1';
  late Future<Album> futureAlbum;

  String spaceFlightNews = "http://api.spaceflightnewsapi.net/v4/articles/";

  String celestrakPreScript = "https://celestrak.org/NORAD/elements/gp.php?NAME=";
  String celestrakPostScript = "&FORMAT=JSON";
  final TextEditingController _searchController = TextEditingController();

  int defaultPageIndex = 2;
  int currentPageIndex = 2;

  SampleItem? selectedMenu;

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
  void updatePageIndex(int index) {
    setState(() {currentPageIndex = index;});
  }
  
  @override
  void initState() {
    FlutterNativeSplash.remove();
    initStorage();
    futureAlbum = fetchAlbum(placeholder);
    super.initState();
  }

  // @override
  // void dispose() {
  //   super.dispose();
  //   mapController.dispose();
  // }

  Future<void> initStorage() async {
    preferences = await SharedPreferences.getInstance();
    setState(() {});
  }

  void _addFavorite(name) {
    favorites.add(name);
    preferences?.setStringList("Favorites", favorites);
    setState(() {});
  }

  // Manage search history
  void _addToHistory(name) {
    // TODO-TD: store chronology datetime of searches
    history.add(name);
    preferences?.setStringList("History", history);
    setState(() {});
  }

  void _loadHistory() {
    List<String>? savedData = preferences?.getStringList("History");

    if (savedData == null) {
      preferences?.setStringList("History", history);
    } else {
      favorites = savedData;
    }
    setState(() {});
  }

  void _removeFromHistory(name) {
    history.remove(name);
    preferences?.setStringList("History", history);
    setState(() {});
  }

  @override
  Widget build(BuildContext context){

    var settingsButton = IconButton(
      icon: const Icon(
        Icons.settings,
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const SettingsPage()),
        );
      },
    );

    var favoritesButton = IconButton(
        icon: const Icon(
          Icons.star_border,
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const FavoritesPage()),
          );
        },
      );
      
    Widget buildHistoryList(){
      _loadHistory();
      // Add search bar to filter history list
      var historyListBuilder = ListView.builder(
        itemBuilder: (context, itemIdxs) {
          if (itemIdxs < history.length) {
            var buttonOptions = [
              MenuItemButton(
                onPressed: () =>
                    setState(() {
                      selectedMenu = SampleItem.values[0];
                      // TODO-TD: store list of orbits being viewed
                    }),
                child: const Text('View'),
              ),
              MenuItemButton(
                onPressed: () => 
                  setState(() {
                    selectedMenu = SampleItem.values[1];
                    _addFavorite(history[itemIdxs]);
                  }),
                child: const Text('Favorite'),
              ),
              MenuItemButton(
                onPressed: () => 
                  setState(() {
                    selectedMenu = SampleItem.values[2];
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
      body: Center( child: Text('Map Page')),
    );

    // news / recent launches
    // TODO-TD: Tile List of space news article
    // http request spaceFlightNewsSite
    // Related launches

    const newsPage = Scaffold(
      body: Center(child: Text('News')),
    );
    
    // view
    // TODO-TD: Interface with gyroscope for celestial sphere
    const viewPage = Scaffold(
      body: Center(child: Text('View')),
    );

    // history
    var historyPage = Scaffold(
      body: buildHistoryList()
    );

    Future<Album> queryCelestrak(String name){
      String query = celestrakPreScript + name + celestrakPostScript;
      futureAlbum = fetchAlbum(query);
      return futureAlbum;
    }

    var searchResultsBuilder = FutureBuilder<Album>(
      future: futureAlbum,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          Album album = snapshot.data!;
          return Column(
            children: [
              Text('${album.userId}'),
              Text('${album.id}'),
              Text(album.title),
              Text(album.body)
            ]
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
            onPressed: () => FocusScope.of(context).unfocus(),
          ),
          hintText: 'Search Orbits',
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear_rounded),
            onPressed: () {_searchController.text = "";}
          ),
        ),
        // onChanged: (value) => _queryCelestrak(value),
        onSubmitted: (value) => queryCelestrak(value),
        ),
      );

    var searchPage = Scaffold(
      appBar: AppBar(
        leading: null,
        title: searchBar,
      ),
      body: Center(child: searchResultsBuilder),
    );

    var pages = <Widget>[
      mapPage,
      newsPage,
      viewPage,
      historyPage,
      searchPage,
    ];

    var navBar = NavigationBar(
      onDestinationSelected: updatePageIndex,
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


class SettingsPage extends StatefulWidget {
  // Settings page
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
    // Search bar
    // - Display only the search results

    // - reset all settings
    // - control location services
    // - enable disable notifications
    // - sensor calibration

  final _textFieldController = TextEditingController();
  final _editingController = TextEditingController();

  final List<String> titles = [
    "Email", 
    "Language"
  ];

  List<String> filteredItems = [];
  
  SharedPreferences? preferences;
  String defaultEmail = 'person@email.com';
  String email = 'person@email.com';
  
  void _clearMemory(String name){

    List<String>? savedData = preferences?.getStringList(name);

    if (savedData == null) {
      setState(() {});

    } else {

      for (final saved in savedData) {
        savedData.remove(saved);
      }

      preferences?.setStringList(name, savedData);
      setState(() {});
    }
  }

  void filterSearchResults(String query) {
    setState(() {
      filteredItems = titles
          .where((item) => item.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }
  Future<void> initStorage() async {
    preferences = await SharedPreferences.getInstance();
    setState(() {
      _loadEmail();
    });
  }

  @override
  void initState() {
    initStorage();
    super.initState();
  }

  void _updateEmail(name) {
    email = name;
    preferences?.setString("email", email);
    setState(() {});
  }

  void _loadEmail() {
    String? savedData = preferences?.getString('email');

    if (savedData == null) {
      preferences?.setString("email", defaultEmail);
    } else {
      email = savedData;
    }

    setState(() {});
  }

  void _removeEmail() {
    email = defaultEmail;
    preferences?.setString("email", defaultEmail);
    setState(() {});
  }

  Future<String?> _showTextInputDialog(BuildContext context) async {
    var dialogBox = AlertDialog(
      title: const Text('Add email'),
      content: TextField(
        controller: _textFieldController,
        decoration: const InputDecoration(hintText: "Email"),
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
        }
      );
  }
  @override
  Widget build(BuildContext context){

    var searchBar = TextField(
      controller: _editingController,
      decoration: const InputDecoration(
        floatingLabelBehavior: FloatingLabelBehavior.never,
        labelText: "Search",
        hintText: "Search Settings",
        prefixIcon: Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(15.0)
          )
        )
      )
    );


    var emailTile = ListTile(
      leading: const Icon(Icons.mail),
      title: const Text("Email"),
      subtitle: Text(email),
      trailing: IconButton(
        icon: const Icon(Icons.delete),
        onPressed: () async {
          _removeEmail();
        },
      ),
      onTap: () async {
        var resultLabel = await _showTextInputDialog(context);
        if (resultLabel != null) {
          setState(() {
            _updateEmail(resultLabel);
            }
          );
        }
      }
    );

    var clearHistoryTile = ListTile(
      leading: const Icon(Icons.history),
      title: const Text("Clear History"),
      subtitle: const Text("Clear all search history"),
      trailing: IconButton(
        icon: const Icon(Icons.delete_forever_sharp),
        onPressed: () async {_clearMemory("History");},
      )
    );

    var clearFavoritesTile = ListTile(
      leading: const Icon(Icons.star),
      title: const Text("Clear Favorites"),
      subtitle: const Text("Clear all favorites"),
      trailing: IconButton(
        icon: const Icon(Icons.delete_forever_sharp),
        onPressed: () async {_clearMemory("Favorites");},
      )
    );

    var themeConsumer = Consumer<ModelThemeProvider>(
      builder: (context, ModelThemeProvider themeNotifier, child) {

        var darkmodeTile = ListTile(
          leading: Icon(
            themeNotifier.isDark ? Icons.nightlight_round : Icons.wb_sunny
          ),
          title: Text(themeNotifier.isDark ? "Dark Mode" : "Light Mode"),
          trailing: Switch(
              value: themeNotifier.isDark,
              activeColor: Colors.purple,
              onChanged: (val) {
                setState(() {
                  themeNotifier.isDark = val;
                }
              );
            }
          ),
        );

        var settingsBody = SingleChildScrollView(
          child: Container(
            alignment: Alignment.center,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [Text("Common")],
                ),
                const ListTile(
                  title: Text("Location"),
                  leading: Icon(Icons.pin_drop),
                  subtitle: Text("Here"),
                ),
                const ListTile(
                  title: Text("Notifications"),
                  leading: Icon(Icons.notifications),
                  subtitle: Text("Get notified on upcoming passes"),
                ),
                const ListTile(
                  title: Text("Language"),
                  leading: Icon(Icons.language),
                  subtitle: Text("English"),
                ),
                const Divider(),
                emailTile,
                darkmodeTile,
                const Divider(),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [Text("Account")],
                ),
                clearHistoryTile,
                clearFavoritesTile
              ],
            ),
          ),
        );

        return Scaffold(
          appBar: AppBar(
            title: const Text("Settings"),
          ),
          body: Column(
            children: [
              searchBar, 
              settingsBody
            ]
          )
        );
      }
    );
    return themeConsumer;       
  }
}

class FavoritesPage extends StatefulWidget {
// Favorites page 
    // + button in bottom right to add new
      // Pop up window to enter fields

    // Search bar
    // scroll
      // each list member
        // Title
        // Metadata (next time)
        // triple dot
          // share
          // delete
        // single tap load trajector in main
        // hold click to reorder
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  SharedPreferences? preferences;
  List<String> _allFavoritesList = [];
  List<String> _filteredFavoritesList = [];

  final TextEditingController _searchController = TextEditingController();
  final _newFavoriteFieldController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  

  void loadFavorites() {
    List<String>? savedData = preferences?.getStringList('Favorites');

    if (savedData != null) {
      _allFavoritesList = savedData;
      _filteredFavoritesList = _allFavoritesList;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterListBySearchText(String searchText) {
    setState(() {
      _filteredFavoritesList = _allFavoritesList
          .where((faveObj) =>
              faveObj.toLowerCase().contains(searchText.toLowerCase()))
          .toList();
    });
  }

  Future<void> initStorage() async {
    preferences = await SharedPreferences.getInstance();
    setState(() {});
  }

  @override
  void initState() {
    initStorage();
    loadFavorites();
    super.initState();
  }

  void _addFavorite(name) {
    _allFavoritesList.add(name);
    preferences?.setStringList("Favorites", _allFavoritesList);
    setState(() {});
  }

  void _loadFavorites() {
    List<String>? savedData = preferences?.getStringList('Favorites');

    if (savedData == null) {
      preferences?.setStringList("Favorites", _allFavoritesList);
    } else {
      _allFavoritesList = savedData;
      _filteredFavoritesList = _allFavoritesList;
    }

    setState(() {});
  }

  void _removeFavorite(name) {
    _allFavoritesList.remove(name);
    _filteredFavoritesList.remove(name);
    preferences?.setStringList("Favorites", _allFavoritesList);
    setState(() {});
  }

  Future<String?> _showTextInputDialog(BuildContext context) async {
    var dialogBox = AlertDialog(
      title: const Text('Add new favorite'),
      content: TextField(
        controller: _newFavoriteFieldController,
        decoration: const InputDecoration(hintText: "New Favorite"),
      ),
      actions: <Widget>[
        ElevatedButton(
          child: const Text("Exit"),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton(
          child: const Text('Add'),
          onPressed: () => Navigator.pop(context, _newFavoriteFieldController.text),
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

    // TODO-TD: hide search bar unless scrolled up?
    var favoritesSearchBar = AppBar(
      leading: null,
      title: Container(
        height: 40,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(5)),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            prefixIcon: IconButton(
              icon: const Icon(Icons.search_rounded),
              onPressed: () => FocusScope.of(context).unfocus(),
            ),
            hintText: 'Search Favorites',
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear_rounded),
              onPressed: () {
                _searchController.text = "";
                _filterListBySearchText("");
              }
            ),
          ),
          onChanged: (value) => _filterListBySearchText(value),
          onSubmitted: (value) => _filterListBySearchText(value),
          ),
        ),
      );
    
    var favoritesSearchResults = ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      controller: _scrollController,
      itemCount: _filteredFavoritesList.length,
      shrinkWrap: true,
      padding: const EdgeInsets.only(bottom: 10),
      itemBuilder: (context, itemIdxs) {
        if (itemIdxs < _filteredFavoritesList.length) {
          var favoriteTiles = ListTile(
            title: Text(_filteredFavoritesList[itemIdxs]),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                _removeFavorite(_filteredFavoritesList[itemIdxs]);
              },
            )
          );
          return favoriteTiles;
        }
      },
    );
      
    // TODO-TD: move to circular button hovering in bottom right corner
    var addFavButtonAppBar = <Widget>[
      IconButton(
        icon: const Icon(
          Icons.star,
        ),
        onPressed: () async {
          var resultLabel = await _showTextInputDialog(context);
          if (resultLabel != null) {
            setState(() {
              _addFavorite(resultLabel);
              _filterListBySearchText("");
            });
          }
        }
      )
    ];

    var pageLayout = Scaffold(
      appBar: AppBar(
          title: const Text('Favorites'),
          actions: addFavButtonAppBar,
        ),
      body: Scaffold(
        appBar: favoritesSearchBar,
        body: favoritesSearchResults,
      )
    );

    return pageLayout;
  }
}
