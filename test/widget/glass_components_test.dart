import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khmer_horror_podcast/app/theme/app_theme.dart';
import 'package:khmer_horror_podcast/core/widgets/glass_app_bar.dart';
import 'package:khmer_horror_podcast/core/widgets/glass_card.dart';
import 'package:khmer_horror_podcast/core/widgets/glass_container.dart';

void main() {
  testWidgets('GlassContainer renders child with proper blur structure', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: GlassContainer(
            child: Text('Khmer Horror Card'),
          ),
        ),
      ),
    );

    expect(find.text('Khmer Horror Card'), findsOneWidget);
    expect(find.byType(GlassContainer), findsOneWidget);
    expect(find.byType(BackdropFilter), findsOneWidget);
  });

  testWidgets('GlassCard handles tap interactions smoothly', (WidgetTester tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: GlassCard(
            onTap: () => tapped = true,
            child: const Text('Tap Me'),
          ),
        ),
      ),
    );

    expect(find.text('Tap Me'), findsOneWidget);
    await tester.tap(find.text('Tap Me'));
    expect(tapped, isTrue);
  });

  testWidgets('GlassAppBar displays title and back icon', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          appBar: GlassAppBar(
            title: 'រឿងខ្មោចបាត់ដំបង',
            showBack: true,
          ),
          body: SizedBox.shrink(),
        ),
      ),
    );

    expect(find.text('រឿងខ្មោចបាត់ដំបង'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
  });
}
