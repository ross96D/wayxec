import 'package:fuzzy_string/fuzzy_string.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests', () {
    final damerauLevenshtein = optimalStringAlignmentDistance;
    final dice = diceCoefficient;

    setUp(() {
      // Additional setup goes here.
    });

    test('Case sensitive', () {
      expect(damerauLevenshtein('casa', 'Casa', ignoreCase: false), 1);
    });

    test('Case insensitive', () {
      expect(damerauLevenshtein('casa', 'Casa', ignoreCase: true), 0);
    });
  });
}
