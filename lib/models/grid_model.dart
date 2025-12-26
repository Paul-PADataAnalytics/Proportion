import 'dart:ui';

enum GridType {
  rectangular,
  circular,
}

enum SizeMode {
  pixel,
  percent
}

class GridSettings {
  GridType type = GridType.rectangular;
  
  // Rectangular properties
  double spacingX = 50.0;
  double spacingY = 50.0;
  
  // Circular properties
  double spacingRadius = 50.0;
  int segments = 12;
  
  // Sizing mode
  SizeMode sizeMode = SizeMode.pixel;
  
  // Positioning
  Offset offset = Offset.zero;
  double rotation = 0.0;
  double scale = 1.0;
  
  // Styling
  Color color = const Color(0xFF000000); // Black default
  double strokeWidth = 1.0;
  
  // Subdivisions (not fully implemented structure yet, simple list of rects/sectors for now)
  // Logic: Store regions that have subdivision active.
  // For Rectangular: List<Rect> subdividedRegions
  // For Circular: List<CircularRegion> subdividedRegions
  
  // We'll keep it simple for now and just have consistent subdivision settings
  bool enableSubdivision = false;
  int subdivisionCount = 2;
  Color subdivisionColor = const Color(0xFF888888);
}
