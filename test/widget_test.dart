import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:proportion/main.dart';
import 'package:proportion/models/app_state.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // We need to wrap with provider as main() does, or use ProportionApp if it has provider inside?
    // main() wraps ProportionApp with MultiProvider. ProportionApp itself is just MaterialApp.
    // So we need to wrap ProportionApp or use main's structure.
    // But verify main.dart... main() calls runApp(MultiProvider(... child: ProportionApp())).
    // So if we pump ProportionApp directly, it won't have the Provider.

    await tester.pumpWidget(
      MultiProvider(
        providers: [ChangeNotifierProvider(create: (_) => AppState())],
        child: const ProportionApp(),
      ),
    );

    // Verify Grid Mode selector is present
    expect(find.text('Grid Mode'), findsOneWidget);

    // Verify dynamic inputs for default mode (SquareFixed)
    expect(find.text('Columns'), findsOneWidget);

    // Verify toolbar actions
    expect(find.byIcon(Icons.folder_open), findsOneWidget);
    expect(find.byIcon(Icons.save_alt), findsOneWidget);

    // Verify Grid Settings header is present (part of Toolbar)

    // Verify no image selected initially
    expect(find.text('No image selected'), findsOneWidget);
  });
}
