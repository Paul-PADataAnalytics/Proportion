import 'package:flutter/foundation.dart';
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
import '../services/image_service.dart'; // For ExportFormat

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

  Future<void> _exportImage(BuildContext context, ExportFormat format) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Dialog(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            "Please wait, exporting...",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );

    try {
      final state = context.read<AppState>();

      // Artificial delay to ensure dialog shows up and animation starts
      // This helps if the subsequent compute() call blocks the UI thread momentarily during serialization (Web Debug mode)
      await Future.delayed(const Duration(milliseconds: 200));

      final bytes = await state.exportImage(format: format);

      // Close dialog
      if (context.mounted) Navigator.pop(context);

      if (bytes == null) return;

      final String fileName = state.fileName ?? "proportion_export";
      final String nameWithoutExt = fileName.split('.').first;

      String ext = "png";
      if (format == ExportFormat.jpg) ext = "jpg";
      if (format == ExportFormat.pdf) ext = "pdf";

      final String exportName = "${nameWithoutExt}_gridded.$ext";

      String mime = 'image/png';
      if (format == ExportFormat.jpg) mime = 'image/jpeg';
      if (format == ExportFormat.pdf) mime = 'application/pdf';

      if (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS)) {
        final tempDir = await getTemporaryDirectory();
        final path = '${tempDir.path}/$exportName';

        final xFile = XFile.fromData(bytes, mimeType: mime, name: exportName);
        await xFile.saveTo(path);

        final fileToShare = XFile(path, mimeType: mime, name: exportName);
        await Share.shareXFiles([
          fileToShare,
        ], text: 'Exported from Proportion');
      } else {
        // Desktop or Web
        if (kIsWeb) {
          final XFile textFile = XFile.fromData(
            bytes,
            mimeType: mime,
            name: exportName,
          );
          await textFile.saveTo(exportName);
        } else {
          final FileSaveLocation? result = await getSaveLocation(
            suggestedName: exportName,
          );
          if (result != null) {
            final XFile textFile = XFile.fromData(
              bytes,
              mimeType: mime,
              name: exportName,
            );
            await textFile.saveTo(result.path);
          }
        }
      }
    } catch (e) {
      // Close dialog if error
      if (context.mounted) Navigator.pop(context);
      debugPrint("Export Error: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Export failed: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool showCamera =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool isDesktop =
                !kIsWeb &&
                (defaultTargetPlatform == TargetPlatform.linux ||
                    defaultTargetPlatform == TargetPlatform.windows ||
                    defaultTargetPlatform == TargetPlatform.macOS);
            // On Web we also treat as desktop-like if wide usually?
            // "on desktops, the tool bar is at the right side of the screen"
            if (kIsWeb)
              isDesktop =
                  true; // Treat web as desktop regarding layout preference?
            // "Right for Landscape/Wide/Desktop".

            bool isWide = constraints.maxWidth > constraints.maxHeight;

            bool useSideBar;
            if (isDesktop) {
              useSideBar = true; // Always right on desktop (and web now)
            } else {
              useSideBar = isWide; // Landscape/Wide on mobile
            }

            final toolbar = ToolbarWidget(
              onOpen: () => _pickImage(context),
              onCamera: () => _takePhoto(context),
              onExport: (format) => _exportImage(context, format),
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
              return Column(
                children: [
                  canvasArea,
                  SizedBox(height: 300, child: toolbar),
                ],
              );
            }
          },
        ),
      ),
    );
  }
}
