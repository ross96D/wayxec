// ignore: depend_on_referenced_packages
import 'package:test/test.dart';
import 'package:wayxec/config.dart';

void main() {
  test("parse correct configuration", () {
    String input = """
opacity = 0.5
""";

    final resp = parseConfigFromString(input);

    expect(resp.$2, isNull);
    expect(resp.$1, equals(Configuration(opacity: 0.5)));
  });

  test("parse incorrect configuration", () {
    String input = """
opacity = 12
invalid_key = 23
""";
    final resp = parseConfigFromString(input);
    expect(resp.$1, equals(Configuration()));
    expect(resp.$2, isNotNull);
    expect(resp.$2!.errors.length, equals(2), reason: resp.$2!.errors.join("\n"));
    expect(resp.$2!.errors[0], isA<RangeValidationError>());
    expect(resp.$2!.errors[1], isA<ValueNotUsed>());
  });
}
