
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

// Camera Page
class CameraPage extends StatefulWidget {
  /// Default Constructor
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}


class _CameraPageState extends State<CameraPage> {
  late CameraController controller;
  int rearCamera = 0;
  int frontCamera = 1;

  Future<void> _initCamera() async {
    List<CameraDescription> cameras = await availableCameras();

    CameraController controller = CameraController(
      cameras[frontCamera], 
      ResolutionPreset.max
    );
    
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    }).catchError((Object e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            // Handle access errors here.
            break;
          default:
            // Handle other errors here.
            break;
        }
      }
    });
  }

  @override
  void initState() {
    _initCamera();
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
          child: controller.value.isInitialized ? 
            CameraPreview(controller) : const Center(child: CircularProgressIndicator())
      )
    );
  }
}
