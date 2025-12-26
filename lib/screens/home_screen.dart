import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../models/app_state.dart';
import '../widgets/grid_painter.dart';
import '../widgets/toolbar_widget.dart';
import '../widgets/grid_gesture_detector.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _pickImage(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
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
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$exportName');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Exported from Proportion');
    } else {
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
    bool showCamera = Platform.isAndroid || Platform.isIOS;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // On desktop we prefer side bar usually, unless window is very narrow.
            // Requirement: "on phones and tablets, when in a portrait mode, or [..] taller than wide => bottom"
            // "on phones and tablets, when in a landscape mode, or [..] wider than tall => right"
            // "on desktops, the tool bar is at the right side of the screen"

            bool isDesktop =
                Platform.isLinux || Platform.isWindows || Platform.isMacOS;
            bool isWide = constraints.maxWidth > constraints.maxHeight;

            bool useSideBar;
            if (isDesktop) {
              useSideBar = true; // Always right on desktop
            } else {
              useSideBar = isWide; // Landscape/Wide on mobile
            }

            final toolbar = ToolbarWidget(
              onOpen: () => _pickImage(context),
              onCamera: () => _takePhoto(context),
              onExport: () => _exportImage(context),
              showCamera: showCamera,
            );

            final canvasArea = Expanded(
              child: Container(
                color: Colors.black, // Canvas background
                child: Consumer<AppState>(
                  builder: (context, state, child) {
                    if (state.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state.image == null) {
                      return const Center(
                        child: Text(
                          'No image selected',
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }

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
                                child: GridGestureDetector(
                                  state: state,
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
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );

            if (useSideBar) {
              return Row(
                children: [
                  canvasArea,
                  SizedBox(width: 300, child: toolbar),
                ],
              );
            } else {
              // Portrait - Bottom bar
              // We might want to limit height of toolbar or let it scroll?
              // Let's give it a fixed height or flexible.
              // A bottom sheet style but persistent.
              return Column(
                children: [
                  canvasArea,
                  SizedBox(
                    height: 300, // Fixed height for bottom toolbar
                    child: toolbar,
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }
}
