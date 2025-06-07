import 'dart:math';

import 'package:fuzzy_string/src/matcher.dart';

class DamerauLevenshtein extends FuzzyStringMatcher {
  const DamerauLevenshtein();

  @override
  int similarity(String s1, String s2) {
    return optimalStringAlignmentDistance(s1, s2);
  }
  
  @override
  double normalSimilarity(String s1, String s2) {
    final averageLenght = (s1.length + s2.length) / 2;
    final distance = optimalStringAlignmentDistance(s1, s2);
    return (averageLenght - distance > 0 ? averageLenght - distance : 0) / averageLenght;
  }
}

/// Optimal String Alignment Distance
///
/// Is a Damerau-Levenshtein distance alghoritm but is not allowed to apply
/// multiple transformations on a same substring
///
/// See: https://stats.stackexchange.com/a/467772
int optimalStringAlignmentDistance(String s1, String s2, {
  bool ignoreCase = false,
}) {
  if (ignoreCase) {
    s1 = s1.toLowerCase();
    s2 = s2.toLowerCase();
  }

  // Checks before init
  if (s1 == s2) {
    return 0;
  }
  if (s1.isEmpty) {
    return s2.length;
  }
  if (s2.isEmpty) {
    return s1.length;
  }

  
  List<List<int>> dp = [];

  // Create matrix
  for (int i = 0; i < s1.length + 1; i++) {
    List<int> internal = [];
    for (int j = 0; j < s2.length + 1; j++) {
      internal.add(0);
    }
    dp.add(internal);
  }
  
  // Initialize the table
  for (var i = 0; i < dp.length; i++) {
    dp[i][0] = i;
  }
  for (var j = 0; j < dp[0].length; j++) {
    dp[0][j] = j;
  }

  // Populate the table using dynamic programming
  for (int i = 1; i <= s1.length; i++) {
    for (int j = 1; j <= s2.length; j++) {
      if (s1[i - 1] == s2[j - 1]) {
        dp[i][j] = dp[i - 1][j - 1];
      } else {
        dp[i][j] = 1 + min(min(dp[i - 1][j], dp[i][j - 1]), dp[i - 1][j - 1]);
      }
      if (i > 1 && j > 1 && s1[i-1] == s2[j-2] && s1[i-2] == s2[j-1]) {
        dp[i][j] = min(dp[i][j], dp[i-2][j-2] + 1);
      }
    }
  }
  // Return the edit distance
  return dp[s1.length][s2.length];
}
