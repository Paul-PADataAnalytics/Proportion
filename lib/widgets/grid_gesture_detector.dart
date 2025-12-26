import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/app_state.dart';

class GridGestureDetector extends StatefulWidget {
  final Widget child;
  final AppState state;

  const GridGestureDetector({
    super.key,
    required this.child,
    required this.state,
  });

  @override
  State<GridGestureDetector> createState() => _GridGestureDetectorState();
}

class _GridGestureDetectorState extends State<GridGestureDetector> {
  // For standard scale/pan gestures (Touch)
  double _baseScale = 1.0;
  double _baseRotation = 0.0;

  // For Right-click Rotate (Desktop)
  Offset? _rotationPivot;

  void _onScaleStart(ScaleStartDetails details) {
    _baseScale = widget.state.gridSettings.scale;
    _baseRotation = widget.state.gridSettings.rotation;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    final settings = widget.state.gridSettings;

    // Scale
    if (details.scale != 1.0) {
      settings.scale = (_baseScale * details.scale).clamp(0.1, 5.0);
    }

    // Rotate
    if (details.rotation != 0.0) {
      settings.rotation = (_baseRotation + details.rotation) % (2 * math.pi);
    }

    // Move (Pan)
    // ScaleUpdate details.focalPointDelta gives delta since last update? No, since start?
    // Actually details.focalPoint is the current focal point.
    // details.localFocalPoint

    // Ideally we want delta.
    // If pointer count == 1, it's a pan.
    // If pointer count > 1, it's scale/rotate.

    if (details.pointerCount == 1) {
      // Pan
      // We can use the delta from the previous frame effectively if we rely on the implementation,
      // but ScaleUpdateDetails has focalPointDelta.
      settings.offset += details.focalPointDelta;
    } else {
      // During scale/rotate, the focal point might move too.
      // We can allow panning while scaling.
      settings.offset += details.focalPointDelta;
    }

    widget.state.updateGridSettings(settings);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) {
          final settings = widget.state.gridSettings;
          // Scroll wheel zoom
          // DY negative = up/away = zoom in? Matches typical maps.
          double zoomFactor = 0.1;
          if (event.scrollDelta.dy < 0) {
            settings.scale = (settings.scale + zoomFactor).clamp(0.1, 5.0);
          } else {
            settings.scale = (settings.scale - zoomFactor).clamp(0.1, 5.0);
          }
          widget.state.updateGridSettings(settings);
        }
      },
      onPointerDown: (event) {
        if (event.kind == PointerDeviceKind.mouse &&
            event.buttons == kSecondaryMouseButton) {
          // Right click start
          _rotationPivot = event.localPosition;

          // Calculate initial angle relative to current rotation?
          // Actually requirement: "functions as positioning a pivot point ... and then calculating the rotation as a line from the pivot point to the current point"
          // "where this is 90 degrees top vertical"

          // This sounds like typical dial rotation interaction.
          // We'll store the starting angle of the pointer relative to pivot.
          // And the base rotation of the grid.
          _baseRotation = widget.state.gridSettings.rotation;
          // _rotationStartAngle is not key, we recalculate angle on move.
        }
      },
      onPointerMove: (event) {
        if (_rotationPivot != null && event.kind == PointerDeviceKind.mouse) {
          // Calculate angle
          final dx = event.localPosition.dx - _rotationPivot!.dx;
          final dy = event.localPosition.dy - _rotationPivot!.dy;

          // We want "line from pivot to current point"
          // "where this is 90 degrees top vertical"
          // atan2(dy, dx) returns angle from X axis (0 is right).
          // Vertical top (-Y) is -PI/2.

          // If we want the *interaction* to just rotate the grid:
          // usually we take the delta angle.

          // Requirement says: "fixed at the point of release".
          // "calculating the rotation as a line from the pivot point to the current point"

          double angle = math.atan2(dy, dx);

          // If we map this angle directly to rotation?
          // Then moving mouse around pivot rotates the grid matching the mouse.
          // offset by -PI/2 so that straight up is 0/90?

          // Let's assume standard atan2 + offset.
          // settings.rotation = angle;

          // But we need it to feel natural. Usually user wants to grab and twist.
          // So we should track the *difference* in angle from start.
          // But the requirement implies an absolute mapping or a "look at" behavior.
          // "Fixed at the point of release" -> Pivot is fixed.
          // "calculating the rotation as a line from the pivot point to the current point"

          // Let's try direct mapping offset by 90 degrees usage.
          // Grid rotation 0 is usually standard.
          // If I drag up-right, angle is -45 deg.

          final settings = widget.state.gridSettings;
          settings.rotation = angle + math.pi / 2; // +90 deg so Up is 0?
          widget.state.updateGridSettings(settings);
        }
      },
      onPointerUp: (event) {
        if (_rotationPivot != null && event.kind == PointerDeviceKind.mouse) {
          _rotationPivot = null;
        }
      },
      child: GestureDetector(
        onScaleStart: _onScaleStart,
        onScaleUpdate: _onScaleUpdate,
        child: widget.child,
      ),
    );
  }
}
