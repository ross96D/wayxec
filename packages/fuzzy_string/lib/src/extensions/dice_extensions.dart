import 'package:fuzzy_string/fuzzy_string.dart';

extension StringDiceExtension on String {
  /// Returns a fraction between 0 and 1, which indicates the degree of
  /// similarity between the two strings. 0 indicates completely different
  /// strings, 1 indicates identical strings. The comparison is case-sensitive.
  double similarityTo(String other, {bool ignoreCase = false}) =>
      diceCoefficient(this, other, ignoreCase: ignoreCase);
}
