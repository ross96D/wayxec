// ignore: depend_on_referenced_packages
import 'package:test/test.dart';
import 'package:wayxec/config.dart';

void main() {
  test("parse correct configuration", () {
    String input = """
opacity = 0.5
""";

    final resp = parseConfig(input);

    expect(resp.$1, equals(Configuration(opacity: 0.5)));
  });

  test("parse incorrect configuration", () {
    String input = """
opacity = 12
invalid_key = 23
""";
    final resp = parseConfig(input);
    expect(resp.$1, equals(Configuration()));
    expect(resp.$2.length, equals(2));
    expect(resp.$2[0], isA<ValueParsingError>());
    expect(resp.$2[1], isA<KeyNotFound>());
    expect((resp.$2[1] as KeyNotFound).lineNumber, 2);
  });
}
