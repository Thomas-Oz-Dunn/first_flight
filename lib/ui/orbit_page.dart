import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../mem/orbit.dart';

void addToNotifications(String name){
  // TODO-TD: Check if already receiving notification
  // TODO-TD: Send to FCM

}

class OrbitPage extends StatelessWidget {
  final Orbit orbit;

  const OrbitPage({super.key, required this.orbit});
  

  // Pass in Orbit object
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(orbit.objectName)),
      body: ListView(children: [
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
              Row(children: [
                IconButton(
                  onPressed: () {
                    Share.share('${orbit.objectName} ${orbit.describe()}');
                  }, 
                  icon: const Icon(Icons.share)
                ),
                IconButton(
                  onPressed: () => addToNotifications(orbit.objectName), 
                  icon: const Icon(Icons.notification_add)
                ),
              ],
            )
          ]
        ),
        const Divider(),
        const Text('Next Passes List: TODO'),
        const Divider(),
        const Text('Orbital Information'),
        Text(orbit.describe()),
      ]),
    );
  }
}


// List<LatLng, DateTime> LatLngTrajectory(
//   Orbit orbit, 
//   DateTime dateTime, 
//   double hrDuration
// ) {
//   var props = propagate_from_elements(

//   );
//   var p_lla = eci_to_llh(props);
//   return List<LatLng(p_lla[0], p_lla[1])>;
// }
