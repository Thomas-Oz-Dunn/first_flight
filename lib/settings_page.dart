import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'theme_handle.dart';

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
