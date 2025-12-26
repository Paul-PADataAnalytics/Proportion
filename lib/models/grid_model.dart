import 'dart:ui';

enum GridMode { square, squareFixed, rectangular, rectangularFixed, circular }

abstract class GridConfig {
  bool enableSubdivision = false;
  int subdivisionCount = 2;

  GridConfig copyWith();
}

class SquareConfig extends GridConfig {
  double size = 50.0;

  // Default values
  static const double defaultSize = 50.0;

  @override
  SquareConfig copyWith({
    double? size,
    bool? enableSubdivision,
    int? subdivisionCount,
  }) {
    var config = SquareConfig();
    config.size = size ?? this.size;
    config.enableSubdivision = enableSubdivision ?? this.enableSubdivision;
    config.subdivisionCount = subdivisionCount ?? this.subdivisionCount;
    return config;
  }
}

class SquareFixedConfig extends GridConfig {
  int columns = 6;

  static const int defaultColumns = 6;

  @override
  SquareFixedConfig copyWith({
    int? columns,
    bool? enableSubdivision,
    int? subdivisionCount,
  }) {
    var config = SquareFixedConfig();
    config.columns = columns ?? this.columns;
    config.enableSubdivision = enableSubdivision ?? this.enableSubdivision;
    config.subdivisionCount = subdivisionCount ?? this.subdivisionCount;
    return config;
  }
}

class RectangularConfig extends GridConfig {
  double width = 50.0;
  double height = 50.0;

  static const double defaultWidth = 50.0;
  static const double defaultHeight = 50.0;

  @override
  RectangularConfig copyWith({
    double? width,
    double? height,
    bool? enableSubdivision,
    int? subdivisionCount,
  }) {
    var config = RectangularConfig();
    config.width = width ?? this.width;
    config.height = height ?? this.height;
    config.enableSubdivision = enableSubdivision ?? this.enableSubdivision;
    config.subdivisionCount = subdivisionCount ?? this.subdivisionCount;
    return config;
  }
}

class RectangularFixedConfig extends GridConfig {
  int columns = 6;
  int rows = 6;

  static const int defaultColumns = 6;
  static const int defaultRows = 6;

  @override
  RectangularFixedConfig copyWith({
    int? columns,
    int? rows,
    bool? enableSubdivision,
    int? subdivisionCount,
  }) {
    var config = RectangularFixedConfig();
    config.columns = columns ?? this.columns;
    config.rows = rows ?? this.rows;
    config.enableSubdivision = enableSubdivision ?? this.enableSubdivision;
    config.subdivisionCount = subdivisionCount ?? this.subdivisionCount;
    return config;
  }
}

class CircularConfig extends GridConfig {
  double radius = 50.0;
  int segments = 12;

  static const double defaultRadius = 50.0;
  static const int defaultSegments = 12;

  @override
  CircularConfig copyWith({
    double? radius,
    int? segments,
    bool? enableSubdivision,
    int? subdivisionCount,
  }) {
    var config = CircularConfig();
    config.radius = radius ?? this.radius;
    config.segments = segments ?? this.segments;
    config.enableSubdivision = enableSubdivision ?? this.enableSubdivision;
    config.subdivisionCount = subdivisionCount ?? this.subdivisionCount;
    return config;
  }
}

class GridSettings {
  GridMode activeMode = GridMode.squareFixed; // Default as per requirements

  // Persistence map
  final Map<GridMode, GridConfig> configs = {
    GridMode.square: SquareConfig(),
    GridMode.squareFixed: SquareFixedConfig(),
    GridMode.rectangular: RectangularConfig(),
    GridMode.rectangularFixed: RectangularFixedConfig(),
    GridMode.circular: CircularConfig(),
  };

  // Shared properties
  Offset offset = Offset.zero;
  double rotation = 0.0;
  double scale = 1.0;
  Color color = const Color(0xFF000000);
  Color subdivisionColor = const Color(0xFF888888);
  double strokeWidth = 1.0;

  // Helpers to get current config safely
  T getConfig<T extends GridConfig>() {
    return configs[activeMode] as T;
  }

  GridConfig get currentConfig => configs[activeMode]!;
}
