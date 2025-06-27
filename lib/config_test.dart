// ignore: depend_on_referenced_packages
import 'package:config/config.dart';
import 'package:test/test.dart';
import 'package:wayxec/config.dart';

void main() {
  test("parse correct configuration", () {
    String input = """
opacity = 0.5
""";

    final resp = parseConfigFromString(input);

    expect(resp.$2, isNotNull);
    expect(resp.$2!.errors.where((e) => e.gravity > Gravity.warn), isEmpty);
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
    expect(resp.$2!.errors.length, equals(4), reason: resp.$2!.errors.join("\n"));
    expect(resp.$2!.errors[0], isA<RangeValidationError>());
    expect(resp.$2!.errors[1], isA<MissingKeyError>());
    expect(resp.$2!.errors[2], isA<MissingKeyError>());
    expect(resp.$2!.errors[3], isA<ValueNotUsed>());
  });

  test("gravity", () {
    final errors1 = ReadConfigErrors([
      ConfigurationParseError(IlegalTokenFound(Token.empty(), "")),
      RangeValidationError(actual: 0, end: 2, start: 1),
    ]);

    expect(errors1.gravity, equals(Gravity.fatal));
  });
}
