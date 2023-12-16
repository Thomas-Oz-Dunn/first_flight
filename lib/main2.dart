import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'package:shared_preferences/shared_preferences.dart';

// Start Simple, build from there

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

class ModelThemeProvider extends ChangeNotifier {
  late bool _isDark;
  late MyThemePreferences _preferences;
  bool get isDark => _isDark;

  ModelThemeProvider() {
    _isDark = false;
    _preferences = MyThemePreferences();
    getPreferences();
  }

  //Switching the themes
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
  runApp(SecondFlightApp());
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
                    primaryColor: Colors.green,
                    primarySwatch: Colors.lightGreen,
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
  @override
  void initState() {
    FlutterNativeSplash.remove();
    super.initState();
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

    var favoritesButton = 
      IconButton(
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

    var mainPage = Scaffold(
      // App Bar
        // Left Button to settings
        // Right button to favorites
      appBar: AppBar(
          leading: settingsButton,
          title: const Text('This is an App'),
          actions: [favoritesButton],
        )
      );
    return mainPage;
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
    // scroll
    // - change color theme
    // - clear all favorites
    // - reset all settings
  final _textFieldController = TextEditingController();

  SharedPreferences? preferences;
  String defaultEmail = 'person@email.com';
  String email = 'person@email.com';

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
        });
  }
  @override
  Widget build(BuildContext context){

    var searchBar = TextField(
      controller: _textFieldController,
      decoration: const InputDecoration(
        labelText: "Search",
        hintText: "Search Settings",
        prefixIcon: Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(25.0)
          )
        )
      )
    );


    var emailTile = ListTile(
      leading: const Icon(Icons.mail),
      title: const Text("Email"),
      subtitle: Text(email),
      trailing: IconButton(
        icon: const Icon(
          Icons.delete,
        ),
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
                });
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
                  leading: Icon(Icons.language),
                  title: Text("Language"),
                  subtitle: Text("English"),
                ),
                const Divider(),
                emailTile,
                darkmodeTile,
              ],
            ),
          ),
        );

        return Scaffold(
          appBar: AppBar(
            title: const Text("Settings"),
          ),
          body: Column(
            children: [searchBar, settingsBody]
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

  void _addFavorite(name) {
    favorites.add(name);
    preferences?.setStringList("Favorites", favorites);
    setState(() {});
  }

  void _loadFavorites() {
    List<String>? savedData = preferences?.getStringList('Favorites');

    if (savedData == null) {
      preferences?.setStringList("Favorites", favorites);
    } else {
      favorites = savedData;
    }

    setState(() {});
  }

  void _removeFavorite(name) {
    favorites.remove(name);
    preferences?.setStringList("Favorites", favorites);
    setState(() {});
  }

  Widget _buildList() {
    _loadFavorites();
    var listBuilder = ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemBuilder: (context, itemIdxs) {
        if (itemIdxs < favorites.length) {
          var favoriteTiles = ListTile(
              title: Text(favorites[itemIdxs]),
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
      title: const Text('Add new favorite'),
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
              });
            }
          })
    ];

    var pageLayout = Scaffold(
        appBar: AppBar(
            title: const Text('Favorites'),
            actions: addFavButtonAppBar
          ),
        body: _buildList()
      );

    return pageLayout;
  }
}
