import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'aksara_converter.dart';

void main() => runApp(const AksaraJawaApp());

/// Palette: lontar palm-leaf paper, wedelan indigo ink, one kencana gold accent.
class _Ink {
  const _Ink({
    required this.paper,
    required this.band,
    required this.ink,
    required this.muted,
    required this.rule,
    required this.gold,
  });

  final Color paper;
  final Color band;
  final Color ink;
  final Color muted;
  final Color rule;
  final Color gold;

  static const light = _Ink(
    paper: Color(0xFFECE5D3),
    band: Color(0xFFE1D6BA),
    ink: Color(0xFF1F2A44),
    muted: Color(0xFF6B6456),
    rule: Color(0xFFBDB39A),
    gold: Color(0xFF8A6514),
  );
  static const dark = _Ink(
    paper: Color(0xFF1B1D24),
    band: Color(0xFF262A34),
    ink: Color(0xFFE9E2CE),
    muted: Color(0xFFA39C88),
    rule: Color(0xFF4A4638),
    gold: Color(0xFFD2AE5A),
  );

  static _Ink of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

const _javaneseFonts = ['Noto Serif Javanese', 'Noto Sans Javanese', 'Javanese Text'];

TextStyle _text({
  required double size,
  required Color color,
  FontWeight weight = FontWeight.w400,
  double height = 1.5,
  FontStyle style = FontStyle.normal,
}) =>
    TextStyle(
      fontFamily: 'Noto Serif',
      fontFamilyFallback: ['Georgia', 'Times New Roman', ..._javaneseFonts],
      fontSize: size,
      color: color,
      fontWeight: weight,
      height: height,
      fontStyle: style,
    );

ThemeData _theme(Brightness brightness) {
  final c = brightness == Brightness.dark ? _Ink.dark : _Ink.light;
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: ColorScheme.fromSeed(seedColor: c.gold, brightness: brightness, surface: c.paper),
    scaffoldBackgroundColor: c.paper,
  );
}

class AksaraJawaApp extends StatelessWidget {
  const AksaraJawaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aksara Jawa',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      home: const ConverterPage(),
    );
  }
}

const _baseKeys = <(String, String)>[
  ('ꦲ', 'ha'), ('ꦤ', 'na'), ('ꦕ', 'ca'), ('ꦫ', 'ra'), ('ꦏ', 'ka'),
  ('ꦢ', 'da'), ('ꦠ', 'ta'), ('ꦱ', 'sa'), ('ꦮ', 'wa'), ('ꦭ', 'la'),
  ('ꦥ', 'pa'), ('ꦝ', 'dha'), ('ꦗ', 'ja'), ('ꦪ', 'ya'), ('ꦚ', 'nya'),
  ('ꦩ', 'ma'), ('ꦒ', 'ga'), ('ꦧ', 'ba'), ('ꦛ', 'tha'), ('ꦔ', 'nga'),
];
const _signKeys = <(String, String)>[
  ('ꦶ', 'wulu'), ('ꦸ', 'suku'), ('ꦼ', 'pepet'), ('ꦺ', 'taling'), ('ꦴ', 'tarung'),
  ('꧀', 'pangkon'), ('ꦁ', 'cecak'), ('ꦂ', 'layar'), ('ꦃ', 'wignyan'), ('ꦿ', 'cakra'),
  ('ꦾ', 'pengkal'),
];
const _examples = <String>['hanacaraka', 'sugeng enjang', 'aku tresno'];

class ConverterPage extends StatefulWidget {
  const ConverterPage({super.key});

  @override
  State<ConverterPage> createState() => _ConverterPageState();
}

class _ConverterPageState extends State<ConverterPage> {
  final _controller = TextEditingController();
  bool _toAksara = true;
  bool _murda = false;
  bool _keyboard = false;

  String get _output {
    final text = _controller.text;
    if (text.trim().isEmpty) return '';
    return _toAksara ? latinToAksara(text, useMurda: _murda) : aksaraToLatin(text);
  }

  void _insert(String s) {
    HapticFeedback.selectionClick();
    final sel = _controller.selection;
    final text = _controller.text;
    final start = sel.isValid ? sel.start : text.length;
    final end = sel.isValid ? sel.end : text.length;
    _controller.value = TextEditingValue(
      text: text.replaceRange(start, end, s),
      selection: TextSelection.collapsed(offset: start + s.length),
    );
    setState(() {});
  }

  void _backspace() {
    final sel = _controller.selection;
    final text = _controller.text;
    if (text.isEmpty) return;
    final end = sel.isValid ? sel.end : text.length;
    final start = sel.isValid && sel.start != sel.end ? sel.start : (end - 1).clamp(0, end);
    _controller.value = TextEditingValue(
      text: text.replaceRange(start, end, ''),
      selection: TextSelection.collapsed(offset: start),
    );
    setState(() {});
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _output));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Teks disalin'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _setMode(bool toAksara) => setState(() {
        _toAksara = toAksara;
        _controller.clear();
      });

  void _useExample(String example) => setState(() {
        _toAksara = true;
        _controller.text = example;
      });

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _Ink.of(context);
    final output = _output;
    final hasInput = _controller.text.isNotEmpty;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
              children: [
                Row(
                  children: [
                    Text('ꦄ', style: _text(size: 34, color: c.gold, weight: FontWeight.w600, height: 1.2)),
                    const SizedBox(width: 12),
                    Text('Aksara Jawa', style: _text(size: 28, color: c.ink, weight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Tulis, konversi, dan salin teks dengan keyboard aksara.',
                  style: _text(size: 16, color: c.muted, style: FontStyle.italic),
                ),
                const SizedBox(height: 28),
                _ModeTabs(toAksara: _toAksara, onChanged: _setMode),
                const SizedBox(height: 20),
                Text(_toAksara ? 'Teks Latin' : 'Aksara Jawa', style: _text(size: 14, color: c.muted)),
                Semantics(
                  label: _toAksara ? 'Input teks Latin' : 'Input Aksara Jawa',
                  child: TextField(
                    controller: _controller,
                    minLines: 3,
                    maxLines: 6,
                    cursorColor: c.gold,
                    style: _toAksara
                        ? _text(size: 22, color: c.ink, height: 1.6)
                        : _text(size: 30, color: c.ink, height: 1.7),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: _toAksara
                          ? 'Ketik teks Latin di sini...'
                          : 'Ketik atau tempel Aksara Jawa di sini...',
                      hintStyle: _text(size: 18, color: c.muted, style: FontStyle.italic),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: UnderlineInputBorder(borderSide: BorderSide(color: c.rule)),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: c.rule)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: c.gold, width: 2)),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Text('${_controller.text.length} karakter', style: _text(size: 13, color: c.muted)),
                    const Spacer(),
                    if (hasInput)
                      TextButton(
                        onPressed: () => setState(_controller.clear),
                        style: TextButton.styleFrom(foregroundColor: c.ink, textStyle: _text(size: 15, color: c.ink)),
                        child: const Text('Hapus teks'),
                      ),
                  ],
                ),
                Wrap(
                  spacing: 4,
                  children: [
                    for (final ex in _examples)
                      TextButton(
                        onPressed: () => _useExample(ex),
                        style: TextButton.styleFrom(
                          foregroundColor: c.ink,
                          textStyle: _text(size: 15, color: c.ink, style: FontStyle.italic),
                        ),
                        child: Text(ex),
                      ),
                  ],
                ),
                if (_toAksara)
                  CheckboxListTile(
                    value: _murda,
                    onChanged: (v) => setState(() => _murda = v ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    activeColor: c.ink,
                    checkColor: c.paper,
                    title: Text('Aksara murda untuk huruf kapital', style: _text(size: 15, color: c.ink)),
                    subtitle: Text('Huruf kapital di awal kata', style: _text(size: 13, color: c.muted)),
                  ),
                const SizedBox(height: 32),
                Container(
                  constraints: const BoxConstraints(minHeight: 200),
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                  decoration: BoxDecoration(
                    color: c.band,
                    border: Border(top: BorderSide(color: c.gold, width: 2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _toAksara ? 'Hasil Aksara Jawa' : 'Hasil Latin',
                              style: _text(size: 14, color: c.muted),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: output.isEmpty ? null : _copy,
                            icon: const Icon(Icons.content_copy_rounded, size: 18),
                            label: const Text('Salin'),
                            style: TextButton.styleFrom(
                              foregroundColor: c.ink,
                              textStyle: _text(size: 15, color: c.ink, weight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      AnimatedSwitcher(
                        duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 180),
                        child: output.isEmpty
                            ? Padding(
                                key: const ValueKey('empty'),
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                child: Text(
                                  'Hasil akan muncul di sini. Ketik teks di atas untuk mulai.',
                                  style: _text(size: 18, color: c.muted, style: FontStyle.italic),
                                ),
                              )
                            : Padding(
                                key: ValueKey(output),
                                padding: const EdgeInsets.only(top: 8),
                                child: SelectableText(
                                  output,
                                  style: _toAksara
                                      ? _text(size: 40, color: c.ink, height: 1.7)
                                      : _text(size: 22, color: c.ink),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TextButton.icon(
                  onPressed: () => setState(() => _keyboard = !_keyboard),
                  icon: Icon(_keyboard ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                  label: Text(_keyboard ? 'Tutup keyboard aksara' : 'Buka keyboard aksara'),
                  style: TextButton.styleFrom(foregroundColor: c.ink, textStyle: _text(size: 15, color: c.ink)),
                ),
                AnimatedSize(
                  duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  alignment: Alignment.topCenter,
                  child: _keyboard
                      ? Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: _backspace,
                                  icon: const Icon(Icons.backspace_outlined, size: 18),
                                  label: const Text('Hapus'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: c.ink,
                                    textStyle: _text(size: 15, color: c.ink),
                                  ),
                                ),
                              ),
                              _KeyGrid(keys: _baseKeys, onTap: _insert),
                              _KeyGrid(keys: _signKeys, onTap: _insert, withBase: true),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Latin / Aksara direction as two underlined tabs sitting on a ruled line.
class _ModeTabs extends StatelessWidget {
  const _ModeTabs({required this.toAksara, required this.onChanged});

  final bool toAksara;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = _Ink.of(context);
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.rule))),
      child: Row(
        children: [
          _ModeTab(label: 'Latin → Aksara', selected: toAksara, ink: c.ink, gold: c.gold, muted: c.muted, onTap: () => onChanged(true)),
          const SizedBox(width: 24),
          _ModeTab(label: 'Aksara → Latin', selected: !toAksara, ink: c.ink, gold: c.gold, muted: c.muted, onTap: () => onChanged(false)),
        ],
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  const _ModeTab({
    required this.label,
    required this.selected,
    required this.ink,
    required this.gold,
    required this.muted,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color ink;
  final Color gold;
  final Color muted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 10, 0, 8),
              child: Text(
                label,
                style: _text(
                  size: 16,
                  color: selected ? ink : muted,
                  weight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            AnimatedContainer(
              duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 180),
              height: 2,
              width: 40,
              color: selected ? gold : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }
}

class _KeyGrid extends StatelessWidget {
  const _KeyGrid({required this.keys, required this.onTap, this.withBase = false});

  final List<(String, String)> keys;
  final ValueChanged<String> onTap;
  final bool withBase;

  @override
  Widget build(BuildContext context) {
    final c = _Ink.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        // One pixel is reserved for the grid's left border.
        final inner = constraints.maxWidth - 1;
        final perRow = (inner / 72).floor().clamp(5, 10);
        final cellWidth = inner / perRow;
        return Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: c.rule), left: BorderSide(color: c.rule)),
          ),
          child: Wrap(
            children: [
              for (final (char, label) in keys)
                Semantics(
                  button: true,
                  label: label,
                  child: InkWell(
                    onTap: () => onTap(char),
                    child: Container(
                      width: cellWidth,
                      height: 68,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(color: c.rule),
                          bottom: BorderSide(color: c.rule),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            withBase ? 'ꦲ$char' : char,
                            style: _text(size: 24, color: c.ink, height: 1.3),
                          ),
                          Text(label, style: _text(size: 11, color: c.muted)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
