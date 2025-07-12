import 'package:flutter/foundation.dart';
import 'package:wayxec/main.dart' as app;
import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App Startup Benchmark', (WidgetTester tester) async {
    if (!(kReleaseMode || kProfileMode)) {
      markTestSkipped("startup benchmark needs release or profile mode (found ${kDebugMode ? 'debug' : kProfileMode ? 'profile' : 'release'})");
      return;
    }
    // Start tracing before app launch
    await binding.traceAction(
      () async {
        // Launch the app
        app.main([]);

        // Wait until app is fully settled (first frame + async work)
        await tester.pumpAndSettle(
          const Duration(milliseconds: 50), // Extended timeout
          EnginePhase.sendSemanticsUpdate, // Final phase
          const Duration(seconds: 1), // Frame timeout
        );
      },
      reportKey: 'startup_trace',
    );

    final time = IntegrationTestWidgetsFlutterBinding.instance.reportData!['startup_trace']
        ["timeExtentMicros"];
    expect(time, lessThan(100000));
  });
}
