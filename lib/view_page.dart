import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'skybox.dart';
import 'package:flutter/services.dart' show rootBundle;

class ViewPage extends StatefulWidget {
  const ViewPage({super.key});

  @override
  State<ViewPage> createState() => _ViewPageState();
}


class _ViewPageState extends State<ViewPage> {

  Future<ui.Image> _image(String path) {
    /// Load image from assets.
    return rootBundle.load(path).then((bytes) {
      return ui.instantiateImageCodec(bytes.buffer.asUint8List()).then((codec) {
        return codec.getNextFrame().then((frame) {
          return frame.image;
        });
      });
    });
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
        body: FutureBuilder<ui.Image>(
          future: _image('images/map.png'),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              /// Pass images to sky box.
              return Stack(
                children: [
                  /// Full screen sky box.
                  Positioned.fill(
                    child: SkyBox(
                      image: snapshot.data!,
                    ),
                  ),
                ],
              );
            }
            /// Show loading indicator while image is loading.
            return const Center(child: CircularProgressIndicator());
          },
        ),
      );
  }
}
