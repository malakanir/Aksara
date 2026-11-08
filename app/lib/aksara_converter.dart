/// Latin <-> Aksara Jawa conversion. Pure Dart, no Flutter dependency.
library;

const _nglegena = <String, String>{
  'h': 'ꦲ', 'n': 'ꦤ', 'c': 'ꦕ', 'r': 'ꦫ', 'k': 'ꦏ', 'd': 'ꦢ', 't': 'ꦠ', 's': 'ꦱ',
  'w': 'ꦮ', 'l': 'ꦭ', 'p': 'ꦥ', 'dh': 'ꦝ', 'j': 'ꦗ', 'y': 'ꦪ', 'ny': 'ꦚ',
  'm': 'ꦩ', 'g': 'ꦒ', 'b': 'ꦧ', 'th': 'ꦛ', 'ng': 'ꦔ',
};
const _foreign = <String, String>{'f': 'p', 'v': 'w', 'z': 'j', 'q': 'k', 'x': 's'};
const _murda = <String, String>{
  'n': 'ꦟ', 'k': 'ꦑ', 't': 'ꦡ', 's': 'ꦯ', 'p': 'ꦦ', 'ny': 'ꦘ', 'g': 'ꦓ', 'b': 'ꦨ',
};
const _swara = <String, String>{
  'a': 'ꦄ', 'i': 'ꦆ', 'u': 'ꦈ', 'e': 'ꦌ', 'é': 'ꦌ', 'è': 'ꦌ', 'o': 'ꦎ',
};
const _sandhangan = <String, String>{
  'a': '', 'i': 'ꦶ', 'u': 'ꦸ', 'e': 'ꦼ', 'é': 'ꦺ', 'è': 'ꦺ', 'o': 'ꦺꦴ',
};
const _sigeg = <String, String>{'h': 'ꦃ', 'r': 'ꦂ', 'ng': 'ꦁ'};
const _pangkon = '꧀';
const _cakra = 'ꦿ';
const _pengkal = 'ꦾ';

final _baseRev = <String, String>{
  for (final e in _nglegena.entries) e.value: e.key,
  for (final e in _murda.entries) e.value: e.key,
};
const _swaraRev = <String, String>{'ꦄ': 'a', 'ꦆ': 'i', 'ꦈ': 'u', 'ꦌ': 'e', 'ꦎ': 'o'};
const _sandhanganRev = <String, String>{'ꦶ': 'i', 'ꦸ': 'u', 'ꦼ': 'e'};
const _sigegRev = <String, String>{'ꦃ': 'h', 'ꦂ': 'r', 'ꦁ': 'ng'};

class _Token {
  const _Token.consonant(this.c, this.upper) : v = null;
  const _Token.vowel(this.v)
      : c = null,
        upper = false;
  final String? c;
  final String? v;
  final bool upper;
}

List<_Token> _tokenize(String word) {
  final tokens = <_Token>[];
  var i = 0;
  while (i < word.length) {
    final rest = word.substring(i).toLowerCase();
    final upper = word[i] != word[i].toLowerCase();
    final two = rest.length >= 2 ? rest.substring(0, 2) : '';
    if (const ['ny', 'ng', 'dh', 'th'].contains(two)) {
      tokens.add(_Token.consonant(two, upper));
      i += 2;
      continue;
    }
    final ch = _foreign[rest[0]] ?? rest[0];
    if (_nglegena.containsKey(ch)) {
      tokens.add(_Token.consonant(ch, upper));
    } else if (_sandhangan.containsKey(rest[0])) {
      tokens.add(_Token.vowel(rest[0]));
    }
    i++;
  }
  return tokens;
}

String _processWord(String word, bool useMurda) {
  final tokens = _tokenize(word);
  final out = StringBuffer();
  var last = '';
  var dead = false; // consonant written without vowel, waiting for pasangan/pangkon

  void emit(String s) {
    out.write(s);
    last = s.isEmpty ? last : s[s.length - 1];
  }

  String writeCons(String c, bool murda) {
    if (dead) {
      dead = false;
      if (c == 'r') return _cakra;
      if (c == 'y') return _pengkal;
      return _pangkon + _nglegena[c]!;
    }
    return (murda ? _murda[c] : null) ?? _nglegena[c]!;
  }

  for (var k = 0; k < tokens.length; k++) {
    final t = tokens[k];
    final next = k + 1 < tokens.length ? tokens[k + 1] : null;

    if (t.v != null) {
      emit(k == 0 ? _swara[t.v]! : _nglegena['h']! + _sandhangan[t.v]!);
      continue;
    }

    final c = t.c!;
    final murda = useMurda && k == 0 && t.upper;
    if (next?.v != null) {
      emit(writeCons(c, murda) + _sandhangan[next!.v]!);
      k++;
      continue;
    }

    if (!dead && k > 0 && _sigeg.containsKey(c)) {
      emit(_sigeg[c]!);
    } else {
      emit(writeCons(c, murda));
      if (last != _cakra && last != _pengkal) {
        if (next == null) {
          emit(_pangkon);
        } else {
          dead = true;
        }
      }
    }
  }
  return out.toString();
}

/// Latin -> Aksara Jawa. [useMurda] turns a capitalised first letter into aksara murda.
String latinToAksara(String text, {bool useMurda = false}) =>
    text.replaceAllMapped(RegExp('[A-Za-zéèÉÈ]+'), (m) => _processWord(m[0]!, useMurda));

/// Aksara Jawa -> Latin.
String aksaraToLatin(String text) {
  final out = StringBuffer();
  var pending = false; // last consonant still carries its inherent "a"
  void flush() {
    if (pending) {
      out.write('a');
      pending = false;
    }
  }

  for (var i = 0; i < text.length; i++) {
    final ch = text[i];
    if (_baseRev.containsKey(ch)) {
      flush();
      out.write(_baseRev[ch]);
      pending = true;
    } else if (_swaraRev.containsKey(ch)) {
      flush();
      out.write(_swaraRev[ch]);
    } else if (_sandhanganRev.containsKey(ch)) {
      pending = false;
      out.write(_sandhanganRev[ch]);
    } else if (ch == 'ꦺ') {
      pending = false;
      if (i + 1 < text.length && text[i + 1] == 'ꦴ') {
        out.write('o');
        i++;
      } else {
        out.write('é');
      }
    } else if (ch == _pangkon) {
      pending = false;
    } else if (ch == _cakra || ch == _pengkal) {
      out.write(ch == _cakra ? 'r' : 'y');
      pending = true;
    } else if (_sigegRev.containsKey(ch)) {
      flush();
      out.write(_sigegRev[ch]);
    } else if (ch == 'ꦴ') {
      // tarung without taling: ignore
    } else {
      flush();
      out.write(ch);
    }
  }
  flush();
  return out.toString();
}
