

// Create Skybox where camera can be rotated
// plugin gyroscope or manual drag
import 'dart:math';
import 'package:flutter/material.dart';


class ViewPage extends StatefulWidget {
  const ViewPage({super.key});

  @override
  State<ViewPage> createState() => _ViewPageState();
}



class _ViewPageState extends State<ViewPage> {

  @override
  Widget build(BuildContext context){
    return const Scaffold(body: Text('Hellos'));
  }
}


// Image calcView(
//   num az_0,
//   num el_0,
//   num azfov,
//   num elfov,
//   double phi,
//   List<Image> skybox,
//   List<int> outImageSize
// ){
//   // Floor division
//   int x_c = outImageSize[0] / 2;
//   int y_c = outImageSize[1] / 2;

//   for (final ix in outImageSize[0]){
//     for (final iy in outImageSize[1]){
//       double az = az_0 + azfov / 2 * ((ix - x_c) * cos(phi) + (iy - y_c) * sin(phi));  
//       double el = el_0 + elfov / 2 * (-(ix - x_c) * sin(phi) + (iy - y_c) * cos(phi)); 

//       double x = cos(el) * cos(az);
//       double y = cos(el) * sin(az);
//       double z = sin(el);

//       double mag = sqrt(pow(x, 2) + pow(y,2) + pow(z, 2));
//       double u_x = x / mag;
//       double mag_x = sqrt(pow(u_x, 2));

//       double u_y = y / mag; 
//       double mag_y = sqrt(pow(u_y, 2));
//       double u_z = z / mag; 
//       double mag_z = sqrt(pow(u_z, 2));


//       // min dot +x, +y, -x, -y, +z, -z
//       // idx = 0, 1, 2, 3, 4, 5
//       // ui = y x y x x y
//       // uj = z z z z y x

//       var magIJ = sqrt(pow(u_i, 2) + pow(u_j, 2));
//       var i = u_i / magIJ * nxInImage;
//       var j = u_j / magIJ * nyInImage;

//       image[ix, iy] = skybox[idx][i, j];
//     }
//   }

// }

