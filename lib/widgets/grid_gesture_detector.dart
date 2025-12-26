import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

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

  // For Rotation (Disabled)
  // double _baseRotation = 0.0;
  // Offset? _rotationPivot;

  void _onScaleStart(ScaleStartDetails details) {
    _baseScale = widget.state.gridSettings.scale;
    // _baseRotation = widget.state.gridSettings.rotation;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    final settings = widget.state.gridSettings;

    // Scale
    if (details.scale != 1.0) {
      settings.scale = (_baseScale * details.scale).clamp(0.1, 5.0);
    }

    // Rotate (Disabled)
    // if (details.rotation != 0.0) {
    //   settings.rotation = (_baseRotation + details.rotation) % (2 * math.pi);
    // }

    // Move (Pan)
    if (details.pointerCount == 1) {
      settings.offset += details.focalPointDelta;
    } else {
      settings.offset += details.focalPointDelta;
    }

    widget.state.updateGridSettings(settings); // notifies listeners
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
      // Right-click rotation is disabled
      /*
      onPointerDown: (event) {
        if (event.kind == PointerDeviceKind.mouse &&
            event.buttons == kSecondaryMouseButton) {
          _rotationPivot = event.localPosition;
          _baseRotation = widget.state.gridSettings.rotation;
        }
      },
      onPointerMove: (event) {
        if (_rotationPivot != null && event.kind == PointerDeviceKind.mouse) {
           // Rotation logic removed
        }
      },
      onPointerUp: (event) {
        if (_rotationPivot != null && event.kind == PointerDeviceKind.mouse) {
          _rotationPivot = null;
        }
      },
      */
      child: GestureDetector(
        onScaleStart: _onScaleStart,
        onScaleUpdate: _onScaleUpdate,
        child: widget.child,
      ),
    );
  }
}
