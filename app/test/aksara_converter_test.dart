import 'package:flutter_test/flutter_test.dart';
import 'package:aksara_jawa/aksara_converter.dart';

void main() {
  const cases = <String, String>{
    'hanacaraka': 'ꦲꦤꦕꦫꦏ',
    'sugeng enjang': 'ꦱꦸꦒꦼꦁ ꦌꦤ꧀ꦗꦁ',
    'aku tresno': 'ꦄꦏꦸ ꦠꦿꦼꦱ꧀ꦤꦺꦴ',
    'kanca': 'ꦏꦤ꧀ꦕ',
    'bangsa': 'ꦧꦁꦱ',
    'kursi': 'ꦏꦸꦂꦱꦶ',
    'ibu': 'ꦆꦧꦸ',
    'nggawa': 'ꦔ꧀ꦒꦮ',
    'mangan': 'ꦩꦔꦤ꧀',
  };

  for (final e in cases.entries) {
    test('"${e.key}" round trips', () {
      expect(latinToAksara(e.key), e.value);
      expect(aksaraToLatin(e.value), e.key);
    });
  }

  test('murda only for capitalised first letter', () {
    expect(latinToAksara('Sugeng', useMurda: true), 'ꦯꦸꦒꦼꦁ');
    expect(latinToAksara('sugeng', useMurda: true), 'ꦱꦸꦒꦼꦁ');
  });

  test('sigeg keeps inherent a in reverse', () {
    expect(aksaraToLatin('ꦩꦁ'), 'mang');
  });
}
