import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'aksara_converter.dart';

void main() => runApp(const AksaraJawaApp());

class AksaraJawaApp extends StatelessWidget {
  const AksaraJawaApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF0F766E);
    return MaterialApp(
      title: 'AksaraJawa',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light),
        scaffoldBackgroundColor: const Color(0xFFF5F3EF),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark),
      ),
      home: const ConverterPage(),
    );
  }
}

const _javaneseStyle = TextStyle(
  fontSize: 26,
  height: 1.7,
  fontFamilyFallback: ['Noto Sans Javanese', 'Javanese Text'],
);

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
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final output = _output;
    final hasInput = _controller.text.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                'ꦄ',
                style: TextStyle(
                  fontSize: 20,
                  color: scheme.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text('AksaraJawa'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Ganti arah konversi',
            onPressed: () => _setMode(!_toAksara),
            icon: const Icon(Icons.swap_horiz_rounded),
          ),
          const SizedBox(width: 4),
        ],
        centerTitle: false,
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: scheme.outlineVariant),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Konverter Latin ↔ Aksara Jawa',
                style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Tulis, konversi, dan salin teks dengan keyboard aksara.',
                style: textTheme.bodyMedium?.copyWith(color: scheme.outline),
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: scheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SegmentedButton<bool>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(value: true, label: Text('Latin → Aksara'), icon: Icon(Icons.arrow_forward)),
                          ButtonSegment(value: false, label: Text('Aksara → Latin'), icon: Icon(Icons.arrow_back)),
                        ],
                        selected: {_toAksara},
                        onSelectionChanged: (s) => _setMode(s.first),
                      ),
                      if (_toAksara) ...[
                        const SizedBox(height: 8),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Aksara Murda'),
                          subtitle: const Text('Huruf kapital di awal kata'),
                          value: _murda,
                          onChanged: (v) => setState(() => _murda = v),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 720;
                  final inputPanel = _Panel(
                    title: _toAksara ? 'Teks Latin' : 'Aksara Jawa',
                    trailing: Text(
                      '${_controller.text.length} karakter',
                      style: textTheme.labelMedium?.copyWith(color: scheme.outline),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Semantics(
                          label: _toAksara ? 'Input teks Latin' : 'Input Aksara Jawa',
                          child: TextField(
                            controller: _controller,
                            minLines: 4,
                            maxLines: 6,
                            style: _toAksara ? null : _javaneseStyle,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: scheme.outlineVariant),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: scheme.outlineVariant),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: scheme.primary, width: 2),
                              ),
                              filled: true,
                              fillColor: scheme.surfaceContainerLow,
                              hintText: _toAksara
                                  ? 'Ketik teks Latin di sini...'
                                  : 'Ketik atau tempel Aksara Jawa di sini...',
                              suffixIcon: hasInput
                                  ? IconButton(
                                      tooltip: 'Hapus teks',
                                      icon: const Icon(Icons.clear),
                                      onPressed: () => setState(_controller.clear),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final ex in _examples)
                              ActionChip(
                                label: Text(ex),
                                onPressed: () => _useExample(ex),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                  final outputPanel = _Panel(
                    title: _toAksara ? 'Hasil Aksara Jawa' : 'Hasil Latin',
                    trailing: FilledButton.tonalIcon(
                      onPressed: output.isEmpty ? null : _copy,
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Salin'),
                    ),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 132),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: scheme.primary.withValues(alpha: 0.25)),
                      ),
                      alignment: Alignment.topLeft,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: output.isEmpty
                            ? Row(
                                key: const ValueKey('empty'),
                                children: [
                                  Icon(Icons.translate_rounded, size: 20, color: scheme.outline),
                                  const SizedBox(width: 10),
                                  Flexible(
                                    child: Text(
                                      'Hasil akan muncul di sini. Ketik teks di atas untuk mulai.',
                                      style: textTheme.bodyLarge?.copyWith(color: scheme.outline),
                                    ),
                                  ),
                                ],
                              )
                            : SelectableText(
                                output,
                                key: ValueKey(output),
                                style: _toAksara ? _javaneseStyle : const TextStyle(fontSize: 20),
                              ),
                      ),
                    ),
                  );

                  if (wide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: inputPanel),
                        const SizedBox(width: 16),
                        Expanded(child: outputPanel),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      inputPanel,
                      const SizedBox(height: 16),
                      outputPanel,
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => setState(() => _keyboard = !_keyboard),
                icon: Icon(_keyboard ? Icons.keyboard_hide : Icons.keyboard),
                label: Text(_keyboard ? 'Tutup Keyboard Aksara' : 'Buka Keyboard Aksara'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                child: _keyboard
                    ? Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: _Panel(
                          title: 'Keyboard Aksara',
                          trailing: TextButton.icon(
                            onPressed: _backspace,
                            icon: const Icon(Icons.backspace_outlined),
                            label: const Text('Hapus'),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _KeyGrid(keys: _baseKeys, onTap: _insert),
                              const SizedBox(height: 12),
                              _KeyGrid(keys: _signKeys, onTap: _insert, withBase: true),
                            ],
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  trailing!,
                ],
              ],
            ),
            const SizedBox(height: 12),
            child,
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
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 6.0;
        final perRow = ((constraints.maxWidth + gap) / 78).floor().clamp(5, 10);
        final keyWidth = (constraints.maxWidth - gap * (perRow - 1)) / perRow;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final (char, label) in keys)
              SizedBox(
                width: keyWidth,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    minimumSize: const Size(0, 58),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    side: BorderSide(color: scheme.outlineVariant),
                  ),
                  onPressed: () => onTap(char),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        withBase ? 'ꦲ$char' : char,
                        style: _javaneseStyle.copyWith(fontSize: 20, height: 1.3),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        style: TextStyle(fontSize: 10, color: scheme.outline),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
