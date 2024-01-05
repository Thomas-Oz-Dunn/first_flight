import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:first_flight/calc/skybox.dart';

class ViewPage extends StatefulWidget {
  const ViewPage({super.key});

  @override
  State<ViewPage> createState() => _ViewPageState();
}


class _ViewPageState extends State<ViewPage> {

  Future<ui.Image> _image(String path) {
    return rootBundle.load(path).then((bytes) {
      return ui.instantiateImageCodec(
        bytes.buffer.asUint8List()
        ).then((codec) {
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
          future: _image('lib/Skybox.png'),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Stack(
                children: [
                  /// Full screen sky box.
                  Positioned.fill(
                    // TODO-TD: display view and favorite passes
                    child: SkyBox(
                      image: snapshot.data!,
                    ),
                  ),
                ],
              );
            }
            return const Center(
              child: CircularProgressIndicator()
            );
          },
        ),
      );
  }
}
