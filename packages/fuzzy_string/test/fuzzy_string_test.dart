import 'package:fuzzy_string/fuzzy_string.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests', () {
    final damerauLevenshtein = DamerauLevenshtein();

    test('Case sensitive', () {
      expect(damerauLevenshtein.similarity('casa', 'Casa'), 1);
    });

    test('Case insensitive', () {
      expect(damerauLevenshtein.similarityIgnoreCase('casa', 'Casa'), 0);
    });
  });
}
