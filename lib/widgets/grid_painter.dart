import 'dart:math';
import 'package:flutter/material.dart';
import '../models/grid_model.dart';
import 'dart:math' as math;

class GridPainter extends CustomPainter {
  final GridSettings settings;
  final Size imageSize;

  GridPainter({required this.settings, required this.imageSize});

  @override
  void paint(Canvas canvas, Size size) {
    if (imageSize == Size.zero) return;

    final paint = Paint()
      ..color = settings.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = settings.strokeWidth;

    // Apply transformations
    canvas.save();

    // 1. Translation (Offset)
    // We start at center usually for rotation/scale? Or top left?
    // Requirement says "Direct Manipulation".
    // Usually we want to transform relative to a point.
    // Let's translate to center, apply scale/rot, then translate back?
    // Or just apply offset.

    // Current implementation assumes offset is translation from top-left.
    canvas.translate(settings.offset.dx, settings.offset.dy);

    // 2. Rotation and Scale usually around center of the grid?
    // If the grid covers the image, center of image.
    final center = Offset(imageSize.width / 2, imageSize.height / 2);

    canvas.translate(center.dx, center.dy);
    canvas.rotate(settings.rotation);
    canvas.scale(settings.scale);
    canvas.translate(-center.dx, -center.dy);

    // Draw based on mode
    switch (settings.activeMode) {
      case GridMode.square:
        _drawSquare(canvas, size, paint, settings.getConfig<SquareConfig>());
        break;
      case GridMode.squareFixed:
        _drawSquareFixed(
          canvas,
          size,
          paint,
          settings.getConfig<SquareFixedConfig>(),
        );
        break;
      case GridMode.rectangular:
        _drawRectangular(
          canvas,
          size,
          paint,
          settings.getConfig<RectangularConfig>(),
        );
        break;
      case GridMode.rectangularFixed:
        _drawRectangularFixed(
          canvas,
          size,
          paint,
          settings.getConfig<RectangularFixedConfig>(),
        );
        break;
      case GridMode.circular:
        _drawCircular(
          canvas,
          size,
          paint,
          settings.getConfig<CircularConfig>(),
        );
        break;
    }

    canvas.restore();
  }

  void _drawSquare(Canvas canvas, Size size, Paint paint, SquareConfig config) {
    _drawGrid(
      canvas,
      size,
      paint,
      config.size,
      config.size,
      config.enableSubdivision,
      config.subdivisionCount,
    );
  }

  void _drawSquareFixed(
    Canvas canvas,
    Size size,
    Paint paint,
    SquareFixedConfig config,
  ) {
    // Calculate size based on columns
    // We want 'columns' to fit in the image width?
    // "Cells are controlled as the amount of columns only"
    // Does this mean the grid fills the image?
    // Yes, usually.

    if (config.columns <= 0) return;

    double cellSize = imageSize.width / config.columns;
    _drawGrid(
      canvas,
      size,
      paint,
      cellSize,
      cellSize,
      config.enableSubdivision,
      config.subdivisionCount,
    );
  }

  void _drawRectangular(
    Canvas canvas,
    Size size,
    Paint paint,
    RectangularConfig config,
  ) {
    _drawGrid(
      canvas,
      size,
      paint,
      config.width,
      config.height,
      config.enableSubdivision,
      config.subdivisionCount,
    );
  }

  void _drawRectangularFixed(
    Canvas canvas,
    Size size,
    Paint paint,
    RectangularFixedConfig config,
  ) {
    if (config.columns <= 0 || config.rows <= 0) return;

    double cellW = imageSize.width / config.columns;
    double cellH = imageSize.height / config.rows;
    _drawGrid(
      canvas,
      size,
      paint,
      cellW,
      cellH,
      config.enableSubdivision,
      config.subdivisionCount,
    );
  }

  void _drawGrid(
    Canvas canvas,
    Size size,
    Paint paint,
    double spacingX,
    double spacingY,
    bool subdivide,
    int subCount,
  ) {
    // We draw enough lines to cover the image area... or infinite?
    // Since we scale/rotate, the canvas "window" needs to be covered.
    // For "Fixed", it implies fitting the *original* image rect.
    // If we scale the grid, do we scale the cell size?
    // Yes, the transform is applied to the canvas.
    // So we just draw at 1.0 scale relative to image size.

    // Draw Vertical Lines
    // Fixed modes implies starting at 0 to width?
    // Regular modes implies infinite pattern?
    // Let's assume pattern covers image bounds.

    // Optimization: Draw well beyond bounds to cover rotation.
    // Or just draw within image bounds 0..width, 0..height.

    // Vertical
    for (double x = 0; x <= imageSize.width; x += spacingX) {
      canvas.drawLine(Offset(x, 0), Offset(x, imageSize.height), paint);

      // Subdivisions
      if (subdivide && subCount > 0 && x + spacingX <= imageSize.width) {
        _drawSubdivs(
          canvas,
          x,
          x + spacingX,
          0,
          imageSize.height,
          true,
          subCount,
          paint,
        );
      }
    }
    // Last line if not exact?
    // The loop covers 0 to width.

    // Horizontal
    for (double y = 0; y <= imageSize.height; y += spacingY) {
      canvas.drawLine(Offset(0, y), Offset(imageSize.width, y), paint);

      // Subdivisions
      if (subdivide && subCount > 0 && y + spacingY <= imageSize.height) {
        _drawSubdivs(
          canvas,
          0,
          imageSize.width,
          y,
          y + spacingY,
          false,
          subCount,
          paint,
        );
      }
    }
  }

  void _drawSubdivs(
    Canvas canvas,
    double start,
    double end,
    double crossStart,
    double crossEnd,
    bool isVertical,
    int count,
    Paint mainPaint,
  ) {
    final subPaint = Paint()
      ..color = settings.subdivisionColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = mainPaint.strokeWidth / 2;

    double step = (end - start) / count;
    for (int i = 1; i < count; i++) {
      double pos = start + step * i;
      if (isVertical) {
        // Drawing vertical lines between stripes?
        // No, this helper is dragging lines IN the gap.
        // If isVertical, we are iterating X. So we draw vertical lines.
        canvas.drawLine(
          Offset(pos, crossStart),
          Offset(pos, crossEnd),
          subPaint,
        );
      } else {
        canvas.drawLine(
          Offset(crossStart, pos),
          Offset(crossEnd, pos),
          subPaint,
        );
      }
    }
  }

  void _drawCircular(
    Canvas canvas,
    Size size,
    Paint paint,
    CircularConfig config,
  ) {
    final center = Offset(imageSize.width / 2, imageSize.height / 2);
    double maxRadius = sqrt(center.dx * center.dx + center.dy * center.dy);

    // Rings
    for (double r = config.radius; r <= maxRadius; r += config.radius) {
      canvas.drawCircle(center, r, paint);
      // Subdivs?
    }

    // Segments
    double angleStep = 2 * math.pi / config.segments;
    for (int i = 0; i < config.segments; i++) {
      double angle = i * angleStep;
      canvas.drawLine(
        center,
        center + Offset(cos(angle) * maxRadius, sin(angle) * maxRadius),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) {
    return true; // For now always repaint when rebuilt
  }
}
