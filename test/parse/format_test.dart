import 'package:naruto_arena/naruto_arena.dart';
import 'package:test/test.dart';

main() {
  test('format parses two-way', () {
    var data = {
      'foo': 'bar',
      0: 'zero',
      'map': {
        'one': 1,
        'two': 2,
        'three': '3',
        'four': 4.0
      }
    };

    print('Original data: $data');

    var encoded = NARUTO_ARENA.encode(data);
    print('Encoded: $encoded');

    var decoded = NARUTO_ARENA.decode(encoded);
    print('Decoded: $decoded');

    expect(decoded, data);
  });
}