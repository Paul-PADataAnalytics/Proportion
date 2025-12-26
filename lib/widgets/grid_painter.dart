import 'package:flutter/material.dart';
import '../models/grid_model.dart';
import 'dart:math' as math;

class GridPainter extends CustomPainter {
  final GridSettings settings;
  final Size imageSize;

  GridPainter({required this.settings, required this.imageSize});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = settings.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = settings.strokeWidth;

    final Paint subPaint = Paint()
      ..color = settings.subdivisionColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = settings.strokeWidth * 0.5;

    // Apply transformations (Rotate, Scale, Translate)
    // Conceptually we want the grid to cover the image.
    // If we transform the canvas, we transform the grid drawing.

    // We assume the canvas size passed here matches the widget size, which might be scaled to fit screen.
    // However, for consistency, let's draw in the coordinate space of the "image" and let the parent widget handle scaling to screen.
    // BUT, the custom painter receives the size of the container.
    // Let's assume the container is same aspect ratio as image.

    // Actually, usually we layer this over an image.

    canvas.save();
    // Move to center to rotate/scale
    canvas.translate(
      size.width / 2 + settings.offset.dx,
      size.height / 2 + settings.offset.dy,
    );
    canvas.rotate(settings.rotation);
    canvas.scale(settings.scale);
    canvas.translate(-size.width / 2, -size.height / 2);

    if (settings.type == GridType.rectangular) {
      _drawRectangularGrid(canvas, size, paint, subPaint);
    } else {
      _drawCircularGrid(canvas, size, paint, subPaint);
    }

    canvas.restore();
  }

  void _drawRectangularGrid(
    Canvas canvas,
    Size size,
    Paint paint,
    Paint subPaint,
  ) {
    double spacingX = settings.spacingX;
    double spacingY = settings.spacingY;

    if (settings.sizeMode == SizeMode.percent) {
      spacingX = size.width * (settings.spacingX / 100);
      spacingY = size.height * (settings.spacingY / 100);
    }

    // Safety check
    if (spacingX <= 0) spacingX = 1;
    if (spacingY <= 0) spacingY = 1;

    // Draw vertical lines
    // We draw extra to cover rotation
    // A simple heuristic: draw enough to cover diagonal.
    double diagonal =
        math.sqrt(size.width * size.width + size.height * size.height) *
        2; // generous padding
    double startX = -diagonal / 2;
    double startY = -diagonal / 2;
    double endX = size.width + diagonal / 2;
    double endY = size.height + diagonal / 2;

    // Adjust start to align with 0
    // We want a line at 0 relative to top left?
    // Let's just iterate from center out or just cover the area.

    // Vertical lines
    for (double x = 0; x <= endX; x += spacingX) {
      canvas.drawLine(Offset(x, startY), Offset(x, endY), paint);
      // Subdivisions
      if (settings.enableSubdivision && settings.subdivisionCount > 0) {
        double subSpacing = spacingX / (settings.subdivisionCount + 1);
        for (int k = 1; k <= settings.subdivisionCount; k++) {
          canvas.drawLine(
            Offset(x + subSpacing * k, startY),
            Offset(x + subSpacing * k, endY),
            subPaint,
          );
        }
      }
    }
    for (double x = -spacingX; x >= startX; x -= spacingX) {
      canvas.drawLine(Offset(x, startY), Offset(x, endY), paint);
      // Subdivisions
      if (settings.enableSubdivision && settings.subdivisionCount > 0) {
        double subSpacing = spacingX / (settings.subdivisionCount + 1);
        for (int k = 1; k <= settings.subdivisionCount; k++) {
          canvas.drawLine(
            Offset(x - subSpacing * k, startY),
            Offset(x - subSpacing * k, endY),
            subPaint,
          );
        }
      }
    }

    // Horizontal lines
    for (double y = 0; y <= endY; y += spacingY) {
      canvas.drawLine(Offset(startX, y), Offset(endX, y), paint);
      // Subdivisions
      if (settings.enableSubdivision && settings.subdivisionCount > 0) {
        double subSpacing = spacingY / (settings.subdivisionCount + 1);
        for (int k = 1; k <= settings.subdivisionCount; k++) {
          canvas.drawLine(
            Offset(startX, y + subSpacing * k),
            Offset(endX, y + subSpacing * k),
            subPaint,
          );
        }
      }
    }
    for (double y = -spacingY; y >= startY; y -= spacingY) {
      canvas.drawLine(Offset(startX, y), Offset(endX, y), paint);
      // Subdivisions
      if (settings.enableSubdivision && settings.subdivisionCount > 0) {
        double subSpacing = spacingY / (settings.subdivisionCount + 1);
        for (int k = 1; k <= settings.subdivisionCount; k++) {
          canvas.drawLine(
            Offset(startX, y - subSpacing * k),
            Offset(endX, y - subSpacing * k),
            subPaint,
          );
        }
      }
    }
  }

  void _drawCircularGrid(
    Canvas canvas,
    Size size,
    Paint paint,
    Paint subPaint,
  ) {
    Offset center = Offset(size.width / 2, size.height / 2);

    double maxRadius = math.sqrt(
      size.width * size.width + size.height * size.height,
    );

    double spacing = settings.spacingRadius;
    if (settings.sizeMode == SizeMode.percent) {
      // Percent of min dimension? or max? usually min dimension
      spacing =
          math.min(size.width, size.height) * (settings.spacingRadius / 100);
    }
    if (spacing <= 0) spacing = 1;

    // Rings
    for (double r = spacing; r < maxRadius; r += spacing) {
      canvas.drawCircle(center, r, paint);
      // Subdivision rings
      if (settings.enableSubdivision && settings.subdivisionCount > 0) {
        double subSpacing = spacing / (settings.subdivisionCount + 1);
        for (int k = 1; k <= settings.subdivisionCount; k++) {
          canvas.drawCircle(center, r + subSpacing * k, subPaint);
        }
      }
    }

    // Spokes / Segments
    int count = settings.segments;
    if (count < 1) count = 1;

    double angleStep = 2 * math.pi / count;

    for (int i = 0; i < count; i++) {
      double angle = i * angleStep;
      Offset end =
          center + Offset(math.cos(angle), math.sin(angle)) * maxRadius;
      canvas.drawLine(center, end, paint);

      // Subdivision spokes
      if (settings.enableSubdivision && settings.subdivisionCount > 0) {
        double subAngleStep = angleStep / (settings.subdivisionCount + 1);
        for (int k = 1; k <= settings.subdivisionCount; k++) {
          double subAngle = angle + subAngleStep * k;
          Offset subEnd =
              center +
              Offset(math.cos(subAngle), math.sin(subAngle)) * maxRadius;
          canvas.drawLine(center, subEnd, subPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) {
    // Simplifying equality check for now, ideally check all fields
    return true;
  }
}
