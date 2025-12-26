import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../models/app_state.dart';
import '../models/grid_model.dart';
import '../services/image_service.dart';

class ToolbarWidget extends StatelessWidget {
  final VoidCallback onOpen;
  final VoidCallback onCamera;
  final Function(ExportFormat) onExport; // Change signature
  final bool showCamera;

  const ToolbarWidget({
    super.key,
    required this.onOpen,
    required this.onCamera,
    required this.onExport,
    required this.showCamera,
  });

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Export Image"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text("PNG Image"),
              onTap: () {
                Navigator.pop(ctx);
                onExport(ExportFormat.png);
              },
            ),
            ListTile(
              title: const Text("JPG Image"),
              onTap: () {
                Navigator.pop(ctx);
                onExport(ExportFormat.jpg);
              },
            ),
            ListTile(
              title: const Text("PDF Document"),
              onTap: () {
                Navigator.pop(ctx);
                onExport(ExportFormat.pdf);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, child) {
        return Container(
          color: Theme.of(context).cardColor,
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              // Actions
              Wrap(
                alignment: WrapAlignment.spaceEvenly,
                spacing: 8,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.folder_open),
                    label: const Text("Open"),
                    onPressed: onOpen,
                  ),
                  if (showCamera)
                    ActionChip(
                      avatar: const Icon(Icons.camera_alt),
                      label: const Text("Camera"),
                      onPressed: onCamera,
                    ),
                  ActionChip(
                    avatar: const Icon(Icons.save_alt),
                    label: const Text("Export"),
                    onPressed: () => _showExportDialog(context),
                  ),
                ],
              ),
              const Divider(),

              // Mode Selector
              DropdownButtonFormField<GridMode>(
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: "Grid Mode",
                  border: OutlineInputBorder(),
                ),
                value: state.gridSettings.activeMode,
                onChanged: (val) {
                  if (val != null) state.updateGridMode(val);
                },
                items: [
                  const DropdownMenuItem(
                    value: GridMode.squareFixed,
                    child: Text("Square (Fixed)"),
                  ),
                  const DropdownMenuItem(
                    value: GridMode.square,
                    child: Text("Square"),
                  ),
                  const DropdownMenuItem(
                    value: GridMode.rectangularFixed,
                    child: Text("Rectangle (Fixed)"),
                  ),
                  const DropdownMenuItem(
                    value: GridMode.rectangular,
                    child: Text("Rectangle"),
                  ),
                  const DropdownMenuItem(
                    value: GridMode.circular,
                    child: Text("Circle"),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Dynamic Inputs
              ..._buildModeInputs(context, state),

              const Divider(),

              // Subdivision
              _buildSubdivision(context, state),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildModeInputs(BuildContext context, AppState state) {
    final mode = state.gridSettings.activeMode;
    final config = state.gridSettings.currentConfig;

    List<Widget> inputs = [];

    switch (mode) {
      case GridMode.square:
        if (config is SquareConfig) {
          inputs.add(
            _buildNumberInput(context, "Size", config.size, (v) {
              config.size = v;
              state.updateConfig(config);
            }, defaultValue: SquareConfig.defaultSize),
          );
        }
        break;
      case GridMode.squareFixed:
        if (config is SquareFixedConfig) {
          inputs.add(
            _buildIntInput(
              context,
              "Columns",
              config.columns,
              (v) {
                config.columns = v;
                state.updateConfig(config);
              },
              defaultValue: SquareFixedConfig.defaultColumns,
            ),
          );
        }
        break;
      case GridMode.rectangular:
        if (config is RectangularConfig) {
          inputs.add(
            _buildNumberInput(
              context,
              "Width",
              config.width,
              (v) {
                config.width = v;
                state.updateConfig(config);
              },
              defaultValue: RectangularConfig.defaultWidth,
            ),
          );
          inputs.add(const SizedBox(height: 8));
          inputs.add(
            _buildNumberInput(
              context,
              "Height",
              config.height,
              (v) {
                config.height = v;
                state.updateConfig(config);
              },
              defaultValue: RectangularConfig.defaultHeight,
            ),
          );
        }
        break;
      case GridMode.rectangularFixed:
        if (config is RectangularFixedConfig) {
          inputs.add(
            _buildIntInput(
              context,
              "Columns",
              config.columns,
              (v) {
                config.columns = v;
                state.updateConfig(config);
              },
              defaultValue: RectangularFixedConfig.defaultColumns,
            ),
          );
          inputs.add(const SizedBox(height: 8));
          inputs.add(
            _buildIntInput(
              context,
              "Rows",
              config.rows,
              (v) {
                config.rows = v;
                state.updateConfig(config);
              },
              defaultValue: RectangularFixedConfig.defaultRows,
            ),
          );
        }
        break;
      case GridMode.circular:
        if (config is CircularConfig) {
          inputs.add(
            _buildNumberInput(
              context,
              "Radius",
              config.radius,
              (v) {
                config.radius = v;
                state.updateConfig(config);
              },
              defaultValue: CircularConfig.defaultRadius,
            ),
          );
          inputs.add(const SizedBox(height: 8));
          inputs.add(
            _buildIntInput(
              context,
              "Segments",
              config.segments,
              (v) {
                config.segments = v;
                state.updateConfig(config);
              },
              defaultValue: CircularConfig.defaultSegments,
            ),
          );
        }
        break;
    }
    return inputs;
  }

  Widget _buildSubdivision(BuildContext context, AppState state) {
    final config = state.gridSettings.currentConfig;
    return Column(
      children: [
        SwitchListTile(
          title: const Text("Subdivision"),
          value: config.enableSubdivision,
          onChanged: (v) {
            config.enableSubdivision = v;
            state.updateConfig(config);
          },
        ),
        if (config.enableSubdivision)
          _buildIntInput(context, "Count", config.subdivisionCount, (v) {
            config.subdivisionCount = v;
            state.updateConfig(config);
          }, defaultValue: 2),
      ],
    );
  }

  Widget _buildNumberInput(
    BuildContext context,
    String label,
    double value,
    Function(double) onChanged, {
    required double defaultValue,
  }) {
    var controller = TextEditingController(text: value.toStringAsFixed(1));
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  onChanged(defaultValue);
                  controller.text = defaultValue.toStringAsFixed(1);
                },
              ),
            ),
            onSubmitted: (val) {
              final d = double.tryParse(val);
              if (d != null) onChanged(d);
            },
            onTapOutside: (_) {
              final d = double.tryParse(controller.text);
              if (d != null) onChanged(d);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildIntInput(
    BuildContext context,
    String label,
    int value,
    Function(int) onChanged, {
    required int defaultValue,
  }) {
    var controller = TextEditingController(text: value.toString());
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: false),
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  onChanged(defaultValue);
                  controller.text = defaultValue.toString();
                },
              ),
            ),
            onSubmitted: (val) {
              final d = int.tryParse(val);
              if (d != null) onChanged(d);
            },
            onTapOutside: (_) {
              final d = int.tryParse(controller.text);
              if (d != null) onChanged(d);
            },
          ),
        ),
      ],
    );
  }
}
