Set<String> _getBigrams(String s) {
  final Set<String> result = {};
  for (int i = 0; i < s.length - 1; i++) {
    result.add(s.substring(i, i+2));
  }
  return result;
}

Set _intersect(Set<String> set1, Set<String> set2) {
  return Set.from(set1.where((x) => set2.contains(x)));
}

double diceCoefficient(String s1, String s2, {
  ignoreCase = false,
}) {
  if (ignoreCase) {
    s1 = s1.toLowerCase();
    s2 = s2.toLowerCase();
  }
	// Quick check to catch identical objects:
	if (s1 == s2) return 1;
  // avoid exception for single character searches
  if (s1.length < 2 || s2.length < 2) return 0;

	// Create the bigrams
  Set<String> bigramS1 = _getBigrams(s1);
  Set<String> bigramS2 = _getBigrams(s2);

  return (2 * _intersect(bigramS1, bigramS2).length) / (bigramS1.length + bigramS2.length);
}