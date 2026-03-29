const _alphabet =
    "LceIyBZ3zTE4dPAhlFDRn8aMiuKg5x21JWXCQ7otGOHYU0mfVvS6bsrqj9wkNp";

String encodeId(int number) {
  final base = _alphabet.length;
  var n = number;
  final chars = <String>[];

  while (true) {
    final r = n % base;
    //print('r = $r');
    n = n ~/ base;
    //print('n = $n');
    //print(_alphabet[r]);
    chars.add(_alphabet[r]);
    if (n == 0) break;
  }

  return chars.reversed.join();
}
