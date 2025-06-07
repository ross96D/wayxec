import 'package:fuzzy_string/src/matcher.dart';

Set<String> _getBigrams(String s) {
  final Set<String> result = {};
  for (int i = 0; i < s.length - 1; i++) {
    result.add(s.substring(i, i + 2));
  }
  return result;
}

Set _intersect(Set<String> set1, Set<String> set2) {
  return Set.from(set1.where((x) => set2.contains(x)));
}

class DiceCoefficient extends FuzzyStringMatcher {
  const DiceCoefficient();

  @override
  double normalSimilarity(String s1, String s2) {
    if (s1.length < 2 || s2.length < 2) return 0;

    Set<String> bigramS1 = _getBigrams(s1);
    Set<String> bigramS2 = _getBigrams(s2);

    return (2 * _intersect(bigramS1, bigramS2).length) / (bigramS1.length + bigramS2.length);
  }

  @override
  int similarity(String s1, String s2) {
    if (s1.length < 2 || s2.length < 2) return 0;

    Set<String> bigramS1 = _getBigrams(s1);
    Set<String> bigramS2 = _getBigrams(s2);
    return _intersect(bigramS1, bigramS2).length;
  }
}
