
import 'dart:math';
import 'package:vector_math/vector_math_64.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class SkyBox extends StatefulWidget {
  final ui.Image image;

  /// The field of view of the sky box.
  final double fov;
  /// The perspective of the sky box.
  final double perspective;
  /// The sensitivity of the sky box panning.
  final double sensitivity;
  /// The child widget.
  /// This widget will be drawn on top of the sky box.
  final Widget? child;

  const SkyBox({
    super.key,
    required this.image,
    this.fov = 60,
    this.perspective = 0.4,
    this.sensitivity = 0.2,
    this.child,
  });

  @override
  State<SkyBox> createState() => _SkyBoxState();
}

class _SkyBoxState extends State<SkyBox> {
  // TODO-TD: integrate gryoscope readings for pitch and yaw
  // Use gesture detector if device has no gyrscope access

  double _pitch = 0;
  double _yaw = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _pitch = (_pitch + details.delta.dy * widget.sensitivity) % 360;
          _yaw = (_yaw + details.delta.dx * widget.sensitivity) % 360;
        });
      },
      child: CustomPaint(
        painter: SkyBoxPainter(
          image: widget.image,
          pitch: _pitch,
          yaw: _yaw,
          fov: widget.fov,
          perspective: widget.perspective,
        ),
        child: widget.child,
      ),
    );
  }
}

class _Face {
  final Matrix4 transform;
  final Offset offset;

  _Face(this.transform, this.offset);
}

class SkyBoxPainter extends CustomPainter {
  final ui.Image image;
  final double pitch;
  final double yaw;
  final double fov;
  final double perspective;

  SkyBoxPainter({
    required this.image,
    required this.pitch,
    required this.yaw,
    this.fov = 120,
    this.perspective = 0.01,
  });

  @override
  void paint(Canvas canvas, Size size) {
    /// FOV scaling factor.
    final scale = 1 / tan(radians(fov / 2) * (pi / 180));

    final transform = Matrix4.identity()
      ..setEntry(3, 2, perspective)
      ..setEntry(0, 0, scale)
      ..setEntry(1, 1, scale)
      ..rotateX(radians(-pitch))
      ..rotateY(radians(yaw));

    /// Size of the sky box.
    final double dim = size.height.toDouble();
    final double dim2 = dim / 2;

    final sx = image.width.toDouble() / 4;
    final sy = image.height.toDouble() / 3;

    final dest = Rect.fromCenter(
      center: const Offset(0, 0),
      width: dim,
      height: dim,
    );

    canvas.translate(size.width / 2, size.height / 2);

    final paint = Paint()
      ..isAntiAlias = false
      ..blendMode = BlendMode.srcOver;

    final faces = _createFaces(transform, dim2);

    faces.sort((a, b) {
      final aPos = a.transform.getTranslation();
      final bPos = b.transform.getTranslation();
      return bPos.z.compareTo(aPos.z);
    });

    for (final face in faces.reversed) {
      final src =
          Rect.fromLTWH(
            face.offset.dx * sx, 
            face.offset.dy * sy, 
            sx, 
            sy
          );

      canvas.save();
      canvas.transform(face.transform.storage);
      canvas.drawImageRect(image, src, dest, paint);
      canvas.restore();
    }
  }

  List<_Face> _createFaces(
    Matrix4 transform, 
    double size
  ) {
    return [
      /// Front
      _Face(
        transform.clone()
          ..translate(Vector3(0, 0, size)),
        const Offset(1, 1),
      ),

      /// Right
      _Face(
        transform.clone()
          ..translate(Vector3(size, 0, 0))
          ..rotateY(radians(90)),
        const Offset(2, 1),
      ),

      /// Back
      _Face(
        transform.clone()
          ..translate(Vector3(0, 0, -size))
          ..rotateY(radians(180)),
        const Offset(3, 1),
      ),

      /// Left
      _Face(
        transform.clone()
          ..translate(Vector3(-size, 0, 0))
          ..rotateY(radians(270)),
        const Offset(0, 1),
      ),

      /// Bottom
      _Face(
        transform.clone()
          ..translate(Vector3(0, size, 0))
          ..rotateX(radians(270)),
        const Offset(1, 2),
      ),

      /// Top
      _Face(
        transform.clone()
          ..translate(Vector3(0, -size, 0))
          ..rotateX(radians(90)),
        const Offset(1, 0),
      ),
    ];
  }

  @override
  bool shouldRepaint(covariant SkyBoxPainter oldDelegate) {
    return oldDelegate.pitch != pitch ||
        oldDelegate.yaw != yaw ||
        oldDelegate.fov != fov ||
        oldDelegate.perspective != perspective;
  }
}
