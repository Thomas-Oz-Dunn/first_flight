import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Start Simple, build from there



void main() {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  // runApp(const FirstFlightApp());
  runApp(MainPage());
}

class SecondFlightApp extends StatelessWidget {
  const SecondFlightApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Second Flight',
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true
      ),
      debugShowCheckedModeBanner: false,
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  // Main page
  // Navigation Bar
    // Left Button to settings
    // Right button to favorites
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}


class _MainPageState extends State<MainPage> {
  @override
  void initState() {
    super.initState();
    FlutterNativeSplash.remove();
  }

  @override
  Widget build(BuildContext context){
    var mainPage = Container(
      alignment: Alignment.center,
      child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
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
            ),
            title: const Text('This is an App'),
          )
          
        )
      );
    return mainPage;
  }
}


class SettingsPage extends StatefulWidget {
  // Settings page
  // Search bar
    // scroll
    // - change color theme
    // - clear all favorites
    // - reset all settings
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  var lockAppSwitchVal = true;
  final _textFieldController = TextEditingController();

  SharedPreferences? preferences;
  String email = 'person@email.com';

  Future<void> initStorage() async {
    preferences = await SharedPreferences.getInstance();
    setState(() {});
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

    var body = SingleChildScrollView(
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
            ListTile(
              leading: const Icon(Icons.mail),
              title: Text(email),
              onTap: () async {
                var resultLabel = await _showTextInputDialog(context);
                if (resultLabel != null) {
                  setState(() {_updateEmail(resultLabel);});
                }
              }
            ),
            const Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text("Security"),
              ],
            ),
            ListTile(
              leading: const Icon(Icons.phonelink_lock_outlined),
              title: const Text("Lock app in background"),
              trailing: Switch(
                  value: lockAppSwitchVal,
                  activeColor: const Color.fromARGB(255, 82, 255, 82),
                  onChanged: (val) {
                    setState(() {
                      lockAppSwitchVal = val;
                    });
                  }),
            ),
            const Divider(),
            const Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text("Misc"),
              ],
            ),
            const ListTile(
              leading: Icon(Icons.file_open_outlined),
              title: Text("Terms of Service"),
            ),
            const Divider(),
            const ListTile(
              leading: Icon(Icons.file_copy_outlined),
              title: Text("Open Source and Licences"),
            ),
          ],
        ),
      ),
    );
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings UI"),
      ),
      body: body);
  }

}

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