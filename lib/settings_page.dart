import 'package:flutter/material.dart';

import 'package:first_flight/style.dart';
import 'package:first_flight/sett_model.dart';

// Settings page
class SettingsPage extends StatefulWidget{
  
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsState();

}

class _SettingsState extends State<SettingsPage>{
  late SettModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // _model = createModel(context, () => SettModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }




  Widget _buildList() {
    return ListView(

    );
  }

  @override
  Widget build(BuildContext context) {
    var widgets = Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(0, 12, 0, 0),
      child: SwitchListTile.adaptive(
        value: _model.switchListTileValue1 ??= true,
        onChanged: (newValue) async {
          setState(() => _model.switchListTileValue1 = newValue);
        },
        title: const Text(
          'Push Notifications',
        ),
        subtitle: const Text(
          'Receive Push notifications from our application on a semi regular basis.',
        ),
        tileColor: Colors.white,
        activeColor: const Color(0xFF4B39EF),
        activeTrackColor: const Color(0x4C4B39EF),
        dense: false,
        controlAffinity: ListTileControlAffinity.trailing,
        contentPadding: const EdgeInsetsDirectional.fromSTEB(24, 12, 24, 12),
      ),
    );


    var pageLayout = Scaffold(
      appBar: AppBar(
        backgroundColor: black,
        title: const Text(
          'Settings',
          style: TextStyle(
            color: white
          )
        ),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.max,
        children: [widgets]
      ),
    backgroundColor: gray
    );

    return pageLayout;
    }
}
