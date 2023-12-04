import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:first_flight/style.dart';

// Feature Request page
class RequestFeaturePage extends StatefulWidget {
  const RequestFeaturePage({super.key});

  @override
  State<RequestFeaturePage> createState() => _RequestFeatureState();
}

class _RequestFeatureState extends State<RequestFeaturePage> {
  String currentRequest = '';
  SharedPreferences? preferences;
  final TextEditingController controller = TextEditingController();

  Future<void> initStorage() async {
    preferences = await SharedPreferences.getInstance();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    initStorage();
  }

  void _saveRequest() {
    currentRequest = controller.text;
    preferences?.setString("request", currentRequest);
    setState(() {});
  }

  void _loadRequest() {
    String? savedData = preferences?.getString("request");

    if (savedData == null) {
      preferences?.setString("request", currentRequest);
    } else {
      currentRequest = savedData;
    }
    controller.text = currentRequest;
    setState(() {});
  }

  void _clearRequest() {
    currentRequest = '';
    controller.text = currentRequest;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    var widgets = <Widget>[
      Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 2 * objSpacing, vertical: objSpacing),
        child: TextField(
          maxLines: 10,
          controller: controller,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Enter a request',
          ),
        ),
      ),
      const SizedBox(height: objSpacing),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FloatingActionButton(
            onPressed: _loadRequest,
            tooltip: 'Load',
            backgroundColor: blue,
            child: const Icon(
              Icons.file_copy,
              color: white,
            ),
          ),
          const SizedBox(width: objSpacing),
          FloatingActionButton(
            onPressed: _saveRequest,
            tooltip: 'Save',
            backgroundColor: blue,
            child: const Icon(Icons.save, color: white),
          ),
          const SizedBox(width: objSpacing),
          FloatingActionButton(
              onPressed: _clearRequest,
              tooltip: 'Clear',
              backgroundColor: blue,
              child: const Icon(
                Icons.clear,
                color: white,
              )),
        ],
      )
    ];

    var pageLayout = Scaffold(
        appBar: AppBar(
          backgroundColor: black,
          title: const Text("Feature Request", style: TextStyle(color: white)),
        ),
        body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: widgets),
        backgroundColor: gray);

    return pageLayout;
  }
}
