import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../models/grid_model.dart';

class ToolbarWidget extends StatelessWidget {
  final VoidCallback onOpen;
  final VoidCallback onCamera;
  final VoidCallback onExport;
  final bool showCamera;

  const ToolbarWidget({
    super.key,
    required this.onOpen,
    required this.onCamera,
    required this.onExport,
    required this.showCamera,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, child) {
        return Container(
          color: Theme.of(context).cardColor,
          child: ListView(
            padding: const EdgeInsets.all(8),
            children: [
              // Actions
              Wrap(
                alignment: WrapAlignment.spaceEvenly,
                spacing: 8,
                children: [
                  IconButton.filledTonal(
                    icon: const Icon(Icons.folder_open),
                    onPressed: onOpen,
                    tooltip: 'Open',
                  ),
                  if (showCamera)
                    IconButton.filledTonal(
                      icon: const Icon(Icons.camera_alt),
                      onPressed: onCamera,
                      tooltip: 'Camera',
                    ),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.save_alt),
                    onPressed: onExport,
                    tooltip: 'Export',
                  ),
                ],
              ),
              const Divider(),
              const Text(
                "Grid Settings",
                style: TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),

              // Grid Type
              DropdownButtonFormField<GridType>(
                decoration: const InputDecoration(labelText: "Type"),
                value: state.gridSettings.type,
                onChanged: (val) {
                  if (val != null) state.updateGridType(val);
                },
                items: GridType.values
                    .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                    .toList(),
              ),

              // Size Mode
              DropdownButtonFormField<SizeMode>(
                decoration: const InputDecoration(labelText: "Size Mode"),
                value: state.gridSettings.sizeMode,
                onChanged: (val) {
                  if (val != null) {
                    state.gridSettings.sizeMode = val;
                    state.updateGridSettings(state.gridSettings);
                  }
                },
                items: SizeMode.values
                    .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                    .toList(),
              ),

              // Controls based on type
              if (state.gridSettings.type == GridType.rectangular) ...[
                _buildSlider(
                  context,
                  "Spacing X",
                  state.gridSettings.spacingX,
                  10,
                  500,
                  (v) {
                    state.gridSettings.spacingX = v;
                    state.updateGridSettings(state.gridSettings);
                  },
                ),
                _buildSlider(
                  context,
                  "Spacing Y",
                  state.gridSettings.spacingY,
                  10,
                  500,
                  (v) {
                    state.gridSettings.spacingY = v;
                    state.updateGridSettings(state.gridSettings);
                  },
                ),
              ] else ...[
                _buildSlider(
                  context,
                  "Radius Spacing",
                  state.gridSettings.spacingRadius,
                  10,
                  500,
                  (v) {
                    state.gridSettings.spacingRadius = v;
                    state.updateGridSettings(state.gridSettings);
                  },
                ),
                _buildSlider(
                  context,
                  "Segments",
                  state.gridSettings.segments.toDouble(),
                  3,
                  36,
                  (v) {
                    state.gridSettings.segments = v.toInt();
                    state.updateGridSettings(state.gridSettings);
                  },
                  divisions: 33,
                ),
              ],

              // Subdivision
              SwitchListTile(
                title: const Text("Subdivision"),
                value: state.gridSettings.enableSubdivision,
                onChanged: (v) {
                  state.gridSettings.enableSubdivision = v;
                  state.updateGridSettings(state.gridSettings);
                },
                contentPadding: EdgeInsets.zero,
              ),
              if (state.gridSettings.enableSubdivision)
                _buildSlider(
                  context,
                  "Count",
                  state.gridSettings.subdivisionCount.toDouble(),
                  1,
                  10,
                  (v) {
                    state.gridSettings.subdivisionCount = v.toInt();
                    state.updateGridSettings(state.gridSettings);
                  },
                  divisions: 9,
                ),

              const Divider(),
              const Text(
                "Transform",
                style: TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              _buildSlider(
                context,
                "Rotation",
                state.gridSettings.rotation,
                0,
                6.28,
                (v) {
                  state.gridSettings.rotation = v;
                  state.updateGridSettings(state.gridSettings);
                },
                label:
                    "${(state.gridSettings.rotation * 180 / 3.14159).toStringAsFixed(0)}°",
              ),
              _buildSlider(
                context,
                "Scale",
                state.gridSettings.scale,
                0.1,
                5.0,
                (v) {
                  state.gridSettings.scale = v;
                  state.updateGridSettings(state.gridSettings);
                },
                label: "${state.gridSettings.scale.toStringAsFixed(2)}x",
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSlider(
    BuildContext context,
    String title,
    double value,
    double min,
    double max,
    Function(double) onChanged, {
    int? divisions,
    String? label,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          "$title: ${label ?? value.toStringAsFixed(1)}",
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
