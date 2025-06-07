import 'package:fuzzy_string/fuzzy_string.dart';

/// Base class for the fuzzy string matchers
abstract class FuzzyStringMatcher {
  const FuzzyStringMatcher();

  int similarity(String s1, String s2);

  int similarityIgnoreCase(String s1, String s2) {
    return similarity(s1.toLowerCase(), s2.toLowerCase());
  }

  double normalSimilarity(String s1, String s2);

  double normalSimilarityIgnoreCase(String s1, String s2) {
    return normalSimilarity(s1.toLowerCase(), s2.toLowerCase());
  }
}

FuzzyStringMatcher _base = DamerauLevenshtein();
void changeFuzzyMatcherExtDefault(FuzzyStringMatcher newBase) {
  _base = newBase;
}

extension FuzzyMatcherExtension on String {
  int similarityTo(String other, {FuzzyStringMatcher? matcher, bool ignoreCase = false}) {
    matcher ??= _base;
    if (ignoreCase) {
      return matcher.similarityIgnoreCase(this, other);
    } else {
      return matcher.similarity(this, other);
    }
  }

  double similarityScoreTo(String other, {FuzzyStringMatcher? matcher, bool ignoreCase = false}) {
    matcher ??= _base;
    if (ignoreCase) {
      return matcher.normalSimilarityIgnoreCase(this, other);
    } else {
      return matcher.normalSimilarity(this, other);
    }
  }
}
