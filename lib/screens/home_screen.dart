import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart'; // Mobile/Web import
import 'package:file_selector/file_selector.dart'; // Desktop save import
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../models/app_state.dart';
import '../models/grid_model.dart';
import '../widgets/grid_painter.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _pickImage(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    // image_picker works on Android, iOS, Web, and recently Desktop support is improving but file_selector is safer for desktop.
    // We'll try image_picker first as it's added.
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      context.read<AppState>().loadImage(image);
    }
  }

  Future<void> _takePhoto(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      context.read<AppState>().loadImage(photo);
    }
  }

  Future<void> _exportImage(BuildContext context) async {
    final state = context.read<AppState>();
    final bytes = await state.exportImage();
    if (bytes == null) return;

    final String fileName = state.fileName ?? "proportion_export.png";
    final String nameWithoutExt = fileName.split('.').first;
    final String exportName = "${nameWithoutExt}_gridded.png";

    if (Platform.isAndroid || Platform.isIOS) {
      // On mobile, share or save using path_provider then share
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$exportName');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Exported from Proportion');
    } else {
      // Desktop / Web
      // For web, file_selector's getSaveLocation might not be fully supported or behaves like download.
      // For desktop, it opens a dialog.

      final FileSaveLocation? result = await getSaveLocation(
        suggestedName: exportName,
      );
      if (result != null) {
        final XFile textFile = XFile.fromData(
          bytes,
          mimeType: 'image/png',
          name: exportName,
        );
        await textFile.saveTo(result.path);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine platform for camera button
    bool showCamera = Platform.isAndroid || Platform.isIOS;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Proportion'),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: () => _pickImage(context),
            tooltip: 'Open Image',
          ),
          if (showCamera)
            IconButton(
              icon: const Icon(Icons.camera_alt),
              onPressed: () => _takePhoto(context),
              tooltip: 'Take Photo',
            ),
          IconButton(
            icon: const Icon(Icons.save_alt),
            onPressed: () => _exportImage(context),
            tooltip: 'Export',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              _showGridSettings(context);
            },
            tooltip: 'Grid Settings',
          ),
        ],
      ),
      body: Consumer<AppState>(
        builder: (context, state, child) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.image == null) {
            return const Center(child: Text('No image selected'));
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              // We need to fit the image into the constraints while maintaining aspect ratio
              // and then overlay the grid.

              // FittedBox is good for this.
              // But we need to know the size for the CustomPainter.

              return Center(
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: state.image!.width.toDouble(),
                    height: state.image!.height.toDouble(),
                    child: Stack(
                      children: [
                        RawImage(image: state.image!),
                        Positioned.fill(
                          child: CustomPaint(
                            painter: GridPainter(
                              settings: state.gridSettings,
                              imageSize: Size(
                                state.image!.width.toDouble(),
                                state.image!.height.toDouble(),
                              ),
                            ),
                          ),
                        ),
                        // TODO: Gestures for manipulating grid (scale, rotate, move)
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showGridSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Consumer<AppState>(
          builder: (context, state, child) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  "Grid Settings",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const Divider(),
                ListTile(
                  title: const Text("Grid Type"),
                  trailing: DropdownButton<GridType>(
                    value: state.gridSettings.type,
                    onChanged: (val) {
                      if (val != null) state.updateGridType(val);
                      // We need a proper copyWith or update method in AppState to notify listeners
                      // Currently updateGridType works but for deep properties we need to be careful.
                      // For now we assume direct mutation + notify.
                    },
                    items: GridType.values
                        .map(
                          (e) =>
                              DropdownMenuItem(value: e, child: Text(e.name)),
                        )
                        .toList(),
                  ),
                ),
                ListTile(
                  title: const Text("Size Mode"),
                  trailing: DropdownButton<SizeMode>(
                    value: state.gridSettings.sizeMode,
                    onChanged: (val) {
                      if (val != null) {
                        state.gridSettings.sizeMode = val;
                        state.updateGridSettings(
                          state.gridSettings,
                        ); // Trigger notify
                      }
                    },
                    items: SizeMode.values
                        .map(
                          (e) =>
                              DropdownMenuItem(value: e, child: Text(e.name)),
                        )
                        .toList(),
                  ),
                ),
                if (state.gridSettings.type == GridType.rectangular) ...[
                  ListTile(
                    title: Text(
                      "Spacing X: ${state.gridSettings.spacingX.toStringAsFixed(1)}",
                    ),
                    subtitle: Slider(
                      min: 10,
                      max: 500,
                      value: state.gridSettings.spacingX,
                      onChanged: (v) {
                        state.gridSettings.spacingX = v;
                        state.updateGridSettings(state.gridSettings);
                      },
                    ),
                  ),
                  ListTile(
                    title: Text(
                      "Spacing Y: ${state.gridSettings.spacingY.toStringAsFixed(1)}",
                    ),
                    subtitle: Slider(
                      min: 10,
                      max: 500,
                      value: state.gridSettings.spacingY,
                      onChanged: (v) {
                        state.gridSettings.spacingY = v;
                        state.updateGridSettings(state.gridSettings);
                      },
                    ),
                  ),
                ] else ...[
                  ListTile(
                    title: Text(
                      "Radius Spacing: ${state.gridSettings.spacingRadius.toStringAsFixed(1)}",
                    ),
                    subtitle: Slider(
                      min: 10,
                      max: 500,
                      value: state.gridSettings.spacingRadius,
                      onChanged: (v) {
                        state.gridSettings.spacingRadius = v;
                        state.updateGridSettings(state.gridSettings);
                      },
                    ),
                  ),
                  ListTile(
                    title: Text("Segments: ${state.gridSettings.segments}"),
                    subtitle: Slider(
                      min: 3,
                      max: 36,
                      divisions: 33,
                      value: state.gridSettings.segments.toDouble(),
                      onChanged: (v) {
                        state.gridSettings.segments = v.toInt();
                        state.updateGridSettings(state.gridSettings);
                      },
                    ),
                  ),
                ],
                SwitchListTile(
                  title: const Text("Enable Subdivision"),
                  value: state.gridSettings.enableSubdivision,
                  onChanged: (v) {
                    state.gridSettings.enableSubdivision = v;
                    state.updateGridSettings(state.gridSettings);
                  },
                ),
                if (state.gridSettings.enableSubdivision)
                  ListTile(
                    title: Text(
                      "Subdivisions: ${state.gridSettings.subdivisionCount}",
                    ),
                    subtitle: Slider(
                      min: 1,
                      max: 10,
                      divisions: 9,
                      value: state.gridSettings.subdivisionCount.toDouble(),
                      onChanged: (v) {
                        state.gridSettings.subdivisionCount = v.toInt();
                        state.updateGridSettings(state.gridSettings);
                      },
                    ),
                  ),

                // Transformation controls (Translate, Rotate, Scale)
                const Divider(),
                const Text("Transformation"),
                ListTile(
                  title: Text(
                    "Rotation: ${(state.gridSettings.rotation * 180 / 3.14159).toStringAsFixed(0)}°",
                  ),
                  subtitle: Slider(
                    min: 0,
                    max: 6.28,
                    value: state.gridSettings.rotation,
                    onChanged: (v) {
                      state.gridSettings.rotation = v;
                      state.updateGridSettings(state.gridSettings);
                    },
                  ),
                ),
                ListTile(
                  title: Text(
                    "Scale: ${state.gridSettings.scale.toStringAsFixed(2)}x",
                  ),
                  subtitle: Slider(
                    min: 0.1,
                    max: 5.0,
                    value: state.gridSettings.scale,
                    onChanged: (v) {
                      state.gridSettings.scale = v;
                      state.updateGridSettings(state.gridSettings);
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
