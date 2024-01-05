import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import '../mem/preferences.dart';

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

  List<String> filteredItems = [];

  SharedPreferences? preferences;
  String defaultEmail = 'person@email.com';
  String email = 'person@email.com';

  bool defaultLocateFidelityHigh = false;
  bool isHiFiLocate = false;

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
    preferences?.setString(emailKey, email);
    setState(() {});
  }

  void _updateLocationFidelity(bool value) {
    isHiFiLocate = value;
    preferences?.setString(locationKey, email);
    setState(() {});
  }

  void _loadEmail() {
    String? savedData = preferences?.getString(emailKey);

    if (savedData == null) {
      preferences?.setString(emailKey, defaultEmail);
    } else {
      email = savedData;
    }

    setState(() {});
  }

  void loadLocationFidelity(){
    bool? savedData = preferences?.getBool(locationKey);

    if (savedData == null) {
      preferences?.setBool(locationKey, defaultLocateFidelityHigh);
      isHiFiLocate = defaultLocateFidelityHigh;
    } else {
      isHiFiLocate = savedData;
    }
    setState(() {});
  }

  void _removeEmail() {
    email = defaultEmail;
    preferences?.setString(emailKey, defaultEmail);
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
  Widget build(BuildContext context) {
    var searchBar = TextField(
      controller: _editingController,
      decoration: const InputDecoration(
          floatingLabelBehavior: FloatingLabelBehavior.never,
          labelText: "Search",
          hintText: "Search Settings",
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(15.0)))));

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
          });
        }
      }
    );

    var clearHistoryTile = ListTile(
      leading: const Icon(Icons.history),
      title: const Text("Clear History"),
      subtitle: const Text("Clear all search history"),
      trailing: IconButton(
        icon: const Icon(Icons.delete_forever_sharp),
        onPressed: () async {
          await preferences?.remove(historyKey);
          setState(() {});
        },
      )
    );

    var clearFavoritesTile = ListTile(
      leading: const Icon(Icons.favorite),
      title: const Text("Clear Favorites"),
      subtitle: const Text("Clear all favorites"),
      trailing: IconButton(
        icon: const Icon(Icons.delete_forever_sharp),
        onPressed: () async {
          await preferences?.remove(favoritesKey);
          setState(() {});
        },
      )
    );

    var themeConsumer = Consumer<ModelThemeProvider>(
      builder: (
        context, 
        ModelThemeProvider themeNotifier, 
        child
      ) {
      var darkmodeTile = ListTile(
        leading: Icon(themeNotifier.isDark 
          ? Icons.nightlight_round 
          : Icons.wb_sunny
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

      Widget locationTile = ListTile(
          title: Text(
            "Location Fidelity: ${isHiFiLocate? "High" : "Low"}"
          ),
          leading: const Icon(Icons.pin_drop),
          subtitle: const Text("Level of fidelity in Location Services"),
          trailing: Switch(
          value: isHiFiLocate,
          activeColor: Colors.orange,
          onChanged: (val) {
            setState(() {
              _updateLocationFidelity(val);
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
                // TODO-TD: give control capabilities
                title: Text("Notifications"),
                leading: Icon(Icons.notifications),
                subtitle: Text("Get notified on upcoming passes"),
              ),
              const ListTile(
                title: Text("Language"),
                leading: Icon(Icons.language),
                subtitle: Text("English"),
              ),
              locationTile,
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
    });
    return themeConsumer;
  }
}