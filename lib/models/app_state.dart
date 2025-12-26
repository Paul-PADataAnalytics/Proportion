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

  Uint8List? _originalBytes;
  Uint8List? get originalBytes => _originalBytes;

  final GridSettings _gridSettings = GridSettings();
  GridSettings get gridSettings => _gridSettings;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> loadImage(XFile file) async {
    _isLoading = true;
    notifyListeners();

    try {
      final bytes = await file.readAsBytes();
      _originalBytes = bytes; // Store for export optimization
      _image = await _imageService.loadImage(bytes);
      _fileName = file.name;
    } catch (e) {
      debugPrint("Error loading image: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Uint8List?> exportImage({
    ExportFormat format = ExportFormat.png,
  }) async {
    if (_image == null) return null;
    return _imageService.exportImage(
      _image!,
      _gridSettings,
      originalBytes: _originalBytes,
      format: format,
    );
  }

  // V3 Updates
  void updateGridMode(GridMode mode) {
    _gridSettings.activeMode = mode;
    notifyListeners();
  }

  void updateConfig(GridConfig config) {
    // Configs are stored by reference in the map, but if we replaced the object we need to ensure map is updated.
    // In the current implementation we probably modify properties of the config in the map directly.
    // So just notifyListeners is enough if calling code mutated the config object properly.
    notifyListeners();
  }

  void updateGridSettings(GridSettings newSettings) {
    // This replaces the entire settings object which breaks our persistence if not careful.
    // For V3, we should avoid replacing the whole object and instead mutate properties or configs.
    // But for backward compatibility with existing calls, let's keep it but ideally we don't use this anymore.
    // _gridSettings = newSettings;
    notifyListeners();
  }

  void updateGlobalSettings({Offset? offset, double? rotation, double? scale}) {
    if (offset != null) _gridSettings.offset = offset;
    if (rotation != null) _gridSettings.rotation = rotation;
    if (scale != null) _gridSettings.scale = scale;
    notifyListeners();
  }
}
