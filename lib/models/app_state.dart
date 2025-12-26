import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:cross_file/cross_file.dart';
import 'grid_model.dart';
import '../services/image_service.dart';

class AppState extends ChangeNotifier {
  final ImageService _imageService = ImageService();

  ui.Image? _image;
  ui.Image? get image => _image;

  String? _fileName;
  String? get fileName => _fileName;

  GridSettings _gridSettings = GridSettings();
  GridSettings get gridSettings => _gridSettings;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> loadImage(XFile file) async {
    _isLoading = true;
    notifyListeners();

    try {
      final bytes = await file.readAsBytes();
      _image = await _imageService.loadImage(bytes);
      _fileName = file.name;
    } catch (e) {
      debugPrint("Error loading image: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Uint8List?> exportImage() async {
    if (_image == null) return null;
    return _imageService.exportImage(_image!, _gridSettings);
  }

  void updateGridSettings(GridSettings newSettings) {
    _gridSettings = newSettings;
    notifyListeners();
  }

  void updateGridType(GridType type) {
    _gridSettings.type = type;
    notifyListeners();
  }

  void updateGridColor(Color color) {
    _gridSettings.color = color;
    notifyListeners();
  }

  // Add more granular updates as needed or just replace the object
}
