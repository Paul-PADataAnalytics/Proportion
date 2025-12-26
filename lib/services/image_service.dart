import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math;
// import 'dart:isolate'; // Removed due to web incompatibility
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:image/image.dart' as img_lib;
import '../models/grid_model.dart';
import '../widgets/grid_painter.dart';

enum ExportFormat {
  png,
  jpg,
  pdf, // PDF export
}

class ImageService {
  Future<ui.Image> loadImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  Future<Uint8List?> exportImage(
    ui.Image originalImage,
    GridSettings settings, {
    Uint8List? originalBytes,
    ExportFormat format = ExportFormat.png,
  }) async {
    if (format == ExportFormat.pdf) {
      return _exportPdf(originalImage, settings);
    }

    // Optimization: If explicit original bytes are provided, use them for
    // full off-thread compositing (Cleanest Web Performance).
    // If not, fallback to using UI thread extraction.
    if (originalBytes != null) {
      // debugPrint(
      //   'Proportion: Offloading export to isolate using originalBytes (Uint8List)',
      // );

      // Prepare Param DTO to avoid complex object serialization
      final params = _createDrawParams(settings);

      return await compute(
        _compositeAndEncode,
        _CompositeTask(
          fileBytes: originalBytes,
          params: params,
          format: format,
        ),
      );
    }

    // debugPrint(
    //   'Proportion: Warning - originalBytes is null, using Main Thread fallback',
    // );
    // Fallback path (Main Thread Heavy)
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = Size(
      originalImage.width.toDouble(),
      originalImage.height.toDouble(),
    );

    canvas.drawImage(
      originalImage,
      Offset.zero,
      Paint()..filterQuality = FilterQuality.high,
    );
    final painter = GridPainter(settings: settings, imageSize: size);
    painter.paint(canvas, size);

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.width.toInt(), size.height.toInt());

    final byteData = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) return null;

    final rawBytes = byteData.buffer.asUint8List();

    return await compute(
      _encodeImage,
      _EncodeTask(
        rawBytes: rawBytes,
        width: size.width.toInt(),
        height: size.height.toInt(),
        format: format,
      ),
    );
  }

  GridDrawParams _createDrawParams(GridSettings settings) {
    final config = settings.configs[settings.activeMode]!;

    // Default values
    int size = 0;
    int columns = 0;
    int rows = 0;
    int width = 0;
    int height = 0;
    int radius = 0;
    int segments = 0;

    if (config is SquareConfig) {
      size = config.size.round();
    } else if (config is SquareFixedConfig) {
      columns = config.columns;
    } else if (config is RectangularConfig) {
      width = config.width.round();
      height = config.height.round();
    } else if (config is RectangularFixedConfig) {
      columns = config.columns;
      rows = config.rows;
    } else if (config is CircularConfig) {
      radius = config.radius.round();
      segments = config.segments; // segments is int
    }

    // Convert activeMode to int index
    // 0: square, 1: squareFixed, 2: rect, 3: rectFixed, 4: circular
    int modeIndex = GridMode.values.indexOf(settings.activeMode);

    return GridDrawParams(
      activeModeIndex: modeIndex,
      colorValue: settings.color.value,
      size: size,
      columns: columns,
      rows: rows,
      width: width,
      height: height,
      radius: radius,
      segments: segments,
    );
  }

  Future<Uint8List> _exportPdf(
    ui.Image originalImage,
    GridSettings settings,
  ) async {
    // 1. Get grid image (transparent)
    final gridRecorder = ui.PictureRecorder();
    final gridCanvas = Canvas(gridRecorder);
    final size = Size(
      originalImage.width.toDouble(),
      originalImage.height.toDouble(),
    );

    final painter = GridPainter(settings: settings, imageSize: size);
    painter.paint(gridCanvas, size);

    final gridPicture = gridRecorder.endRecording();
    final gridImg = await gridPicture.toImage(
      size.width.toInt(),
      size.height.toInt(),
    );

    // 2. Get bytes for Original & Grid off-thread?
    // Original image:
    final startByteData = await originalImage.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );
    if (startByteData == null) return Uint8List(0);
    final startRaw = startByteData.buffer.asUint8List();

    final gridByteData = await gridImg.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );
    if (gridByteData == null) return Uint8List(0);
    final gridRaw = gridByteData.buffer.asUint8List();

    // Offload encoding
    final bgPngBytes = await compute(
      _encodeImage,
      _EncodeTask(
        rawBytes: startRaw,
        width: size.width.toInt(),
        height: size.height.toInt(),
        format: ExportFormat.png,
      ),
    );
    if (bgPngBytes == null) return Uint8List(0);

    final gridPngBytes = await compute(
      _encodeImage,
      _EncodeTask(
        rawBytes: gridRaw,
        width: size.width.toInt(),
        height: size.height.toInt(),
        format: ExportFormat.png,
      ),
    );
    if (gridPngBytes == null) return Uint8List(0);

    // 3. Create PDF
    final pdf = pw.Document();
    final pdfImage = pw.MemoryImage(bgPngBytes);
    final pdfGridImage = pw.MemoryImage(gridPngBytes);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(
          originalImage.width.toDouble(),
          originalImage.height.toDouble(),
          marginAll: 0,
        ),
        build: (pw.Context context) {
          return pw.Stack(
            fit: pw.StackFit.expand,
            children: [pw.Image(pdfImage), pw.Image(pdfGridImage)],
          );
        },
      ),
    );

    return pdf.save();
  }
}

class GridDrawParams {
  final int activeModeIndex;
  final int colorValue;

  final int size;
  final int columns;
  final int rows;
  final int width;
  final int height;
  final int radius;
  final int segments;

  GridDrawParams({
    required this.activeModeIndex,
    required this.colorValue,
    this.size = 0,
    this.columns = 0,
    this.rows = 0,
    this.width = 0,
    this.height = 0,
    this.radius = 0,
    this.segments = 0,
  });
}

class _EncodeTask {
  final Uint8List rawBytes;
  final int width;
  final int height;
  final ExportFormat format;

  _EncodeTask({
    required this.rawBytes,
    required this.width,
    required this.height,
    required this.format,
  });
}

class _CompositeTask {
  final Uint8List fileBytes;
  final GridDrawParams params;
  final ExportFormat format;

  _CompositeTask({
    required this.fileBytes,
    required this.params,
    required this.format,
  });
}

Uint8List? _compositeAndEncode(_CompositeTask task) {
  // 1. Decode original image
  // Note: We use the 'image' package's decoder, which is pure Dart.
  final image = img_lib.decodeImage(task.fileBytes);
  if (image == null) return null;

  // 2. Draw Grid
  _drawGridOnImage(image, task.params); // Pass params DTO

  // 3. Encode
  if (task.format == ExportFormat.jpg) {
    return Uint8List.fromList(img_lib.encodeJpg(image, quality: 90));
  } else {
    return Uint8List.fromList(img_lib.encodePng(image));
  }
}

void _drawGridOnImage(img_lib.Image image, GridDrawParams params) {
  // Convert UI Color to Image Color
  final uiColor = params.colorValue;
  // Convert ARGB int to expected RGBA or similar for image lib?
  // ui.Color.value is 0xAARRGGBB
  // img_lib.ColorRgba8 expects r, g, b, a (0-255).

  final a = (uiColor >> 24) & 0xFF;
  final r = (uiColor >> 16) & 0xFF;
  final g = (uiColor >> 8) & 0xFF;
  final b = (uiColor) & 0xFF;

  final gridColor = img_lib.ColorRgba8(r, g, b, a);

  final w = image.width;
  final h = image.height;

  // Determine mode from index
  // 0: square, 1: squareFixed, 2: rect, 3: rectFixed, 4: circular
  final modeIndex = params.activeModeIndex;

  if (modeIndex == 0) {
    // Square
    int size = params.size;
    if (size <= 0) size = 50;
    for (int x = 0; x < w; x += size) {
      img_lib.drawLine(image, x1: x, y1: 0, x2: x, y2: h, color: gridColor);
    }
    for (int y = 0; y < h; y += size) {
      img_lib.drawLine(image, x1: 0, y1: y, x2: w, y2: y, color: gridColor);
    }
  } else if (modeIndex == 1) {
    // SquareFixed
    int cols = params.columns;
    if (cols <= 0) cols = 1;
    double cellSize = w / cols;
    for (int i = 0; i <= cols; i++) {
      int x = (i * cellSize).round();
      img_lib.drawLine(image, x1: x, y1: 0, x2: x, y2: h, color: gridColor);
    }

    int rows = (h / cellSize).ceil();
    for (int i = 0; i <= rows; i++) {
      int y = (i * cellSize).round();
      img_lib.drawLine(image, x1: 0, y1: y, x2: w, y2: y, color: gridColor);
    }
  } else if (modeIndex == 2) {
    // Rectangular
    int cw = params.width;
    int ch = params.height;
    if (cw <= 0) cw = 50;
    if (ch <= 0) ch = 50;
    for (int x = 0; x < w; x += cw) {
      img_lib.drawLine(image, x1: x, y1: 0, x2: x, y2: h, color: gridColor);
    }
    for (int y = 0; y < h; y += ch) {
      img_lib.drawLine(image, x1: 0, y1: y, x2: w, y2: y, color: gridColor);
    }
  } else if (modeIndex == 3) {
    // RectangularFixed
    double cw = w / (params.columns > 0 ? params.columns : 1);
    double ch = h / (params.rows > 0 ? params.rows : 1);
    for (int i = 0; i <= params.columns; i++) {
      int x = (i * cw).round();
      img_lib.drawLine(image, x1: x, y1: 0, x2: x, y2: h, color: gridColor);
    }
    for (int i = 0; i <= params.rows; i++) {
      int y = (i * ch).round();
      img_lib.drawLine(image, x1: 0, y1: y, x2: w, y2: y, color: gridColor);
    }
  } else if (modeIndex == 4) {
    // Circular
    int cx = w ~/ 2;
    int cy = h ~/ 2;
    int maxRadius = (w > h ? w : h) ~/ 2;
    int step = params.radius;
    if (step <= 0) step = 50;

    for (int r = step; r < maxRadius; r += step) {
      img_lib.drawCircle(image, x: cx, y: cy, radius: r, color: gridColor);
    }

    int segments = params.segments;
    if (segments > 0) {
      double diagonal = (w + h).toDouble();
      for (int i = 0; i < segments; i++) {
        double angle = (2 * math.pi * i) / segments;
        double c = math.cos(angle);
        double s = math.sin(angle);
        int x2 = (cx + diagonal * c).round();
        int y2 = (cy + diagonal * s).round();
        img_lib.drawLine(
          image,
          x1: cx,
          y1: cy,
          x2: x2,
          y2: y2,
          color: gridColor,
        );
      }
    }
  }
}

// Top-level function for isolate
Uint8List? _encodeImage(_EncodeTask task) {
  // Construct image from raw RGBA bytes
  final image = img_lib.Image.fromBytes(
    width: task.width,
    height: task.height,
    bytes: task.rawBytes.buffer,
    order: img_lib.ChannelOrder.rgba,
    numChannels: 4,
  );

  if (task.format == ExportFormat.jpg) {
    return Uint8List.fromList(img_lib.encodeJpg(image, quality: 90));
  } else {
    // Default to PNG for PNG and internal usage
    return Uint8List.fromList(img_lib.encodePng(image));
  }
}
