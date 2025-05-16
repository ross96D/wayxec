import 'package:fuzzy_string/fuzzy_string.dart';

void main() {
  var awesome = diceCoefficient;

  print('awesome: ${awesome('carrasco', 'parrazco')}');
  Stopwatch time = Stopwatch()..start();
  for (var i = 0; i < 5000; i++) {
    'amigo fiel'.similarityTo('amio file');
  }
  print(time.elapsed);
  time.stop();
  time..reset()..start();
  for (var i = 0; i < 5000; i++) {
  }
  time.stop();
  print(time.elapsed);
}
