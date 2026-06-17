import 'dart:math';

class IdGenerator {
  IdGenerator._();

  static final _random = Random();

  static String create() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final suffix = _random.nextInt(0x7fffffff).toRadixString(16);
    return '$now-$suffix';
  }
}
