import 'package:flutter_driver/flutter_driver.dart' as driver;
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() {
  return integrationDriver(
    responseDataCallback: (data) async {
      if (data == null) {
        throw AssertionError("no response data");
      }
      final timeline = driver.Timeline.fromJson(
        data['startup_trace'] as Map<String, dynamic>,
      );

      // Convert the Timeline into a TimelineSummary that's easier to
      // read and understand.
      final summary = driver.TimelineSummary.summarize(timeline);

      // Then, write the entire timeline to disk in a json format.
      // This file can be opened in the Chrome browser's tracing tools
      // found by navigating to chrome://tracing.
      // Optionally, save the summary to disk by setting includeSummary
      // to true
      await summary.writeTimelineToFile(
        'startup_trace',
        pretty: true,
        includeSummary: true,
      );
    },
  );
}
