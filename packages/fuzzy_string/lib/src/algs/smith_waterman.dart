import 'dart:math';

import 'package:fuzzy_string/src/matcher.dart';

class SmithWaterman extends FuzzyStringMatcher {
  const SmithWaterman();

  @override
  int similarity(String s1, String s2) {
    return smithWaterman(s1, s2).score;
  }

  @override
  double normalSimilarity(String s1, String s2) {
    final minLen = min(s1.length, s2.length);
    final maxSimilarity = minLen * 2;
    return similarity(s1, s2) / maxSimilarity;
  }
}

class LocalAlignment {
  final String alignedSeq1;
  final String alignedSeq2;
  final int score;

  LocalAlignment(this.alignedSeq1, this.alignedSeq2, this.score);
}

LocalAlignment smithWaterman(String seq1, String seq2,
    {int match = 2, int mismatch = -1, int gap = -1}) {
  int rows = seq1.length + 1;
  int cols = seq2.length + 1;

  // Initialize the scoring matrix with zeros
  List<List<int>> matrix = List.generate(rows, (_) => List.filled(cols, 0));

  // Variables to track the position of the highest score
  int maxScore = 0;
  int maxI = 0;
  int maxJ = 0;

  // Fill the scoring matrix
  for (int i = 1; i < rows; i++) {
    for (int j = 1; j < cols; j++) {
      int diagonal = matrix[i - 1][j - 1] + (seq1[i - 1] == seq2[j - 1] ? match : mismatch);
      int up = matrix[i - 1][j] + gap;
      int left = matrix[i][j - 1] + gap;

      int score = [0, diagonal, up, left].reduce((a, b) => a > b ? a : b);
      matrix[i][j] = score;

      // Track the highest score
      if (score > maxScore) {
        maxScore = score;
        maxI = i;
        maxJ = j;
      }
    }
  }

  // Traceback to construct the aligned sequences
  String align1 = '';
  String align2 = '';
  int i = maxI;
  int j = maxJ;

  while (i > 0 && j > 0 && matrix[i][j] != 0) {
    int current = matrix[i][j];
    int diagonal = matrix[i - 1][j - 1];
    int up = matrix[i - 1][j];
    int left = matrix[i][j - 1];

    if (current == diagonal + (seq1[i - 1] == seq2[j - 1] ? match : mismatch)) {
      align1 = seq1[i - 1] + align1;
      align2 = seq2[j - 1] + align2;
      i--;
      j--;
    } else if (current == up + gap) {
      align1 = seq1[i - 1] + align1;
      align2 = '-$align2';
      i--;
    } else if (current == left + gap) {
      align1 = '-$align1';
      align2 = seq2[j - 1] + align2;
      j--;
    }
  }

  return LocalAlignment(align1, align2, maxScore);
}

void main() {
  // String sequence1 = 'ACACACTA';
  String sequence1 = 'abcd';
  // String sequence2 = 'AGCACACA';
  String sequence2 = 'asdsabcdasd';

  int a = 3;
  int b = 2;
  LocalAlignment result = smithWaterman(sequence1, sequence2);
  print('Aligned Sequence 1: ${result.alignedSeq1}');
  print('Aligned Sequence 2: ${result.alignedSeq2}');
  print('Alignment Score: ${result.score.toDouble()} ${a/b}');
}
