import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/grid_model.dart';
import '../widgets/grid_painter.dart';

class ImageService {
  Future<ui.Image> loadImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  Future<Uint8List?> exportImage(
    ui.Image originalImage,
    GridSettings settings,
  ) async {
    // Composite grid onto image
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final size = Size(
      originalImage.width.toDouble(),
      originalImage.height.toDouble(),
    );

    // Draw original image
    canvas.drawImage(originalImage, Offset.zero, Paint());

    // Draw grid
    // We reuse the GridPainter logic
    final painter = GridPainter(settings: settings, imageSize: size);
    painter.paint(canvas, size);

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.width.toInt(), size.height.toInt());

    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }
}
