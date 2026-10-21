import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khmer_horror_podcast/app/theme/app_theme.dart';
import 'package:khmer_horror_podcast/core/widgets/app_empty_state.dart';
import 'package:khmer_horror_podcast/core/widgets/app_error_state.dart';

void main() {
  testWidgets('AppEmptyState renders title, message and triggers action button', (WidgetTester tester) async {
    bool clicked = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: AppEmptyState(
            title: 'គ្មានទិន្នន័យ',
            message: 'សូមស្វែងរកម្តងទៀត',
            buttonText: 'ស្វែងរក',
            onButtonPressed: () => clicked = true,
          ),
        ),
      ),
    );

    expect(find.text('គ្មានទិន្នន័យ'), findsOneWidget);
    expect(find.text('សូមស្វែងរកម្តងទៀត'), findsOneWidget);
    expect(find.text('ស្វែងរក'), findsOneWidget);

    await tester.tap(find.text('ស្វែងរក'));
    expect(clicked, isTrue);
  });

  testWidgets('AppErrorState renders error text and retry button triggers callback', (WidgetTester tester) async {
    bool retried = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: AppErrorState(
            message: 'បណ្តាញមានបញ្ហា',
            onRetry: () => retried = true,
          ),
        ),
      ),
    );

    expect(find.text('មានបញ្ហាក្នុងការផ្ទុកទិន្នន័យ'), findsOneWidget);
    expect(find.text('បណ្តាញមានបញ្ហា'), findsOneWidget);
    expect(find.text('ព្យាយាមម្តងទៀត'), findsOneWidget);

    await tester.tap(find.text('ព្យាយាមម្តងទៀត'));
    expect(retried, isTrue);
  });
}
