import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:task_manager_flutter/main.dart' as app;
import 'task_test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Create Task Integration Test', () {
    tearDown(() async {
      // Additional cleanup to ensure no hanging semantics handles
      await Future.delayed(const Duration(milliseconds: 100));
    });

    testWidgets('should create a task and verify basic functionality',
        (WidgetTester tester) async {
      // Launch the app
      app.main();
      await TaskTestHelpers.waitForAppToLoad(tester);
      await tester.pumpAndSettle();

      // Create a simple task
      const taskTitle = 'Simple Test Task';
      const taskDescription = 'A simple task for testing';

      // Create the task using helper
      await TaskTestHelpers.createTask(tester, taskTitle, taskDescription);

      // Wait for the task to appear
      final taskFound = await TaskTestHelpers.waitForTaskToAppear(
        tester,
        taskTitle,
        maxRetries: 8,
      );

      expect(taskFound, isTrue, reason: 'Task should be created and visible');

      if (taskFound) {
        print('✅ SUCCESS: Task created and found on homepage');

        // Verify we're back on homepage
        final isOnHomepage = find.text('Tasks').evaluate().isNotEmpty ||
            find.byType(FloatingActionButton).evaluate().isNotEmpty ||
            find.byType(BottomNavigationBar).evaluate().isNotEmpty;

        expect(isOnHomepage, isTrue, reason: 'Should be back on homepage');
        print('✅ SUCCESS: Homepage is accessible');
      }

      // Perform cleanup
      await TaskTestHelpers.performCleanup(tester);
    });
  });
}
