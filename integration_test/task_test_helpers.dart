import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class TaskTestHelpers {
  /// Helper method to wait for app to load
  static Future<void> waitForAppToLoad(WidgetTester tester) async {
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }
  /// Helper method to wait for task to appear with retries
  static Future<bool> waitForTaskToAppear(
    WidgetTester tester,
    String taskTitle, {
    int maxRetries = 10,
  }) async {
    for (int i = 0; i < maxRetries; i++) {
      await tester.pumpAndSettle();

      if (find.text(taskTitle).evaluate().isNotEmpty) {
        print('✓ Task "$taskTitle" found after ${i + 1} attempts');
        return true;
      }

      print('⏳ Attempt ${i + 1}: Task "$taskTitle" not found, waiting...');

      // Try to refresh the list by pulling down
      final scrollView = find.byType(CustomScrollView);
      if (scrollView.evaluate().isNotEmpty) {
        await tester.fling(scrollView, const Offset(0, 300), 1000);
        await tester.pumpAndSettle();
      }

      // Wait before next attempt
      await Future.delayed(const Duration(seconds: 2));
    }

    print('❌ Task "$taskTitle" not found after $maxRetries attempts');
    return false;
  }

  /// Helper method to create a basic task
  static Future<void> createTask(
    WidgetTester tester,
    String title,
    String description,
  ) async {
    // Tap New Task button
    final newTaskButton = find.text('New Task');
    expect(newTaskButton, findsAtLeastNWidgets(1));
    await tester.tap(newTaskButton.first);
    await tester.pumpAndSettle();

    // Fill form
    await tester.enterText(find.byType(TextFormField).first, title);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(1), description);
    await tester.pumpAndSettle();

    // Create the task
    final createButton = find.widgetWithText(ElevatedButton, 'Create Task');
    expect(createButton, findsOneWidget);
    await tester.tap(createButton);
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Wait for navigation back to homepage
    await Future.delayed(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  }

  /// Helper method to perform test cleanup
  static Future<void> performCleanup(WidgetTester tester) async {
    // Multiple cleanup attempts to ensure all handles are disposed
    for (int i = 0; i < 3; i++) {
      await tester.pumpAndSettle();
      
      // Close any open overlays, dropdowns, or dialogs
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      
      // Small delay between cleanup attempts
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    // Final pump to ensure everything is settled
    await tester.pumpAndSettle();
  }
}