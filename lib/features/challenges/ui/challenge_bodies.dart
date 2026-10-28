import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/challenge_engines.dart';

/// Events a challenge body reports to the screen that hosts it.
class ChallengeCallbacks {
  const ChallengeCallbacks({
    required this.onInput,
    required this.onWrong,
    required this.onSolved,
  });

  /// Any interaction; keeps the sound lowered.
  final VoidCallback onInput;

  /// A wrong answer and the time spent on that question.
  final Future<void> Function(Duration taken) onWrong;

  /// The correct answer and the time spent on that question.
  final Future<void> Function(Duration taken) onSolved;
}

InputDecoration _fieldDecoration(AppColors c, String hint, {String? error}) =>
    InputDecoration(
      hintText: hint,
      errorText: error,
      filled: true,
      fillColor: c.inputBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        borderSide: BorderSide.none,
      ),
    );

Widget _submitButton(String label, VoidCallback? onPressed) => SizedBox(
      height: 52,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
        ),
        child: Text(label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );

Widget _card(AppColors c, Widget child) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: c.border),
      ),
      child: child,
    );

// Maths --------------------------------------------------------------------

class MathsChallengeBody extends StatefulWidget {
  const MathsChallengeBody({
    super.key,
    required this.level,
    required this.callbacks,
  });

  final int level;
  final ChallengeCallbacks callbacks;

  @override
  State<MathsChallengeBody> createState() => _MathsChallengeBodyState();
}

class _MathsChallengeBodyState extends State<MathsChallengeBody> {
  final _engine = MathsEngine();
  final _controller = TextEditingController();
  late MathsQuestion _question = _engine.generate(widget.level);
  DateTime _shownAt = DateTime.now();
  String? _message;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    widget.callbacks.onInput();
    final taken = DateTime.now().difference(_shownAt);
    if (_engine.check(_question, _controller.text)) {
      await widget.callbacks.onSolved(taken);
      return;
    }
    await widget.callbacks.onWrong(taken);
    if (!mounted) return;
    setState(() {
      _question = _engine.next(widget.level, _question);
      _controller.clear();
      _shownAt = DateTime.now();
      _message = 'Not quite. Here is a new question.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return ListView(
      children: [
        const SizedBox(height: 24),
        _card(
          c,
          Text(
            _question.text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 40,
              fontWeight: FontWeight.w500,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: c.foreground,
            ),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(signed: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[-0-9]'))],
          onChanged: (_) => widget.callbacks.onInput(),
          onSubmitted: (_) => _submit(),
          decoration: _fieldDecoration(c, 'Your answer', error: _message),
        ),
        const SizedBox(height: 12),
        _submitButton('Submit', _submit),
        const SizedBox(height: 10),
        Text(
          'A wrong answer gives a new question. The alarm stops only when '
          'the answer is right.',
          style: TextStyle(fontSize: 12, color: c.mutedForeground),
        ),
      ],
    );
  }
}

// Memory -------------------------------------------------------------------

class MemoryChallengeBody extends StatefulWidget {
  const MemoryChallengeBody({
    super.key,
    required this.level,
    required this.callbacks,
  });

  final int level;
  final ChallengeCallbacks callbacks;

  @override
  State<MemoryChallengeBody> createState() => _MemoryChallengeBodyState();
}

class _MemoryChallengeBodyState extends State<MemoryChallengeBody> {
  final _engine = MemoryEngine();
  late List<int> _sequence = _engine.generate(widget.level);
  final _entered = <int>[];
  int? _lit;
  bool _playing = true;
  int _playToken = 0;
  DateTime _shownAt = DateTime.now();
  String? _message;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _play();
    });
  }

  @override
  void dispose() {
    _playToken++;
    super.dispose();
  }

  /// Lights the tiles of the sequence one after another.
  Future<void> _play() async {
    final token = ++_playToken;
    setState(() {
      _playing = true;
      _entered.clear();
    });
    await Future<void>.delayed(const Duration(milliseconds: 400));
    for (final tile in _sequence) {
      if (!mounted || token != _playToken) return;
      setState(() => _lit = tile);
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (!mounted || token != _playToken) return;
      setState(() => _lit = null);
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    if (!mounted || token != _playToken) return;
    setState(() {
      _playing = false;
      _shownAt = DateTime.now();
    });
  }

  Future<void> _tap(int tile) async {
    if (_playing || _entered.length >= _sequence.length) return;
    widget.callbacks.onInput();
    setState(() {
      _entered.add(tile);
      _lit = tile;
      _message = null;
    });
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (mounted && _lit == tile) setState(() => _lit = null);
  }

  Future<void> _check() async {
    widget.callbacks.onInput();
    final taken = DateTime.now().difference(_shownAt);
    if (_engine.check(_sequence, _entered)) {
      await widget.callbacks.onSolved(taken);
      return;
    }
    await widget.callbacks.onWrong(taken);
    if (!mounted) return;
    setState(() {
      _sequence = _engine.generate(widget.level);
      _message = 'Not quite. Watch the new pattern.';
    });
    await _play();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final status = _playing
        ? 'Watch the pattern'
        : 'Step ${math.min(_entered.length + 1, _sequence.length)} of '
            '${_sequence.length} · Repeat the pattern';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(status,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: c.mutedForeground)),
        if (_message != null) ...[
          const SizedBox(height: 4),
          Text(_message!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: c.destructive)),
        ],
        const SizedBox(height: 14),
        AspectRatio(
          aspectRatio: 1,
          child: GridView.count(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (var tile = 0; tile < MemoryEngine.tileCount; tile++)
                Semantics(
                  button: true,
                  label: 'Tile ${tile + 1}',
                  child: Material(
                    color: _lit == tile ? c.primary : c.card,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      side: BorderSide(color: c.border),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      onTap: () => _tap(tile),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            TextButton.icon(
              onPressed: _playing ? null : _play,
              icon: const Icon(Icons.replay_rounded),
              label: const Text('Show again'),
            ),
            const Spacer(),
            TextButton(
              onPressed: _playing || _entered.isEmpty
                  ? null
                  : () => setState(_entered.clear),
              child: const Text('Clear'),
            ),
          ],
        ),
        const Spacer(),
        _submitButton(
          'Check pattern',
          !_playing && _entered.length == _sequence.length ? _check : null,
        ),
      ],
    );
  }
}

// Phrase -------------------------------------------------------------------

class PhraseChallengeBody extends StatefulWidget {
  const PhraseChallengeBody({
    super.key,
    required this.level,
    required this.callbacks,
  });

  final int level;
  final ChallengeCallbacks callbacks;

  @override
  State<PhraseChallengeBody> createState() => _PhraseChallengeBodyState();
}

class _PhraseChallengeBodyState extends State<PhraseChallengeBody> {
  final _engine = PhraseEngine();
  final _controller = TextEditingController();
  late String _phrase = _engine.generate(widget.level);
  DateTime _shownAt = DateTime.now();
  String? _message;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    widget.callbacks.onInput();
    final taken = DateTime.now().difference(_shownAt);
    if (_engine.check(_phrase, _controller.text)) {
      await widget.callbacks.onSolved(taken);
      return;
    }
    await widget.callbacks.onWrong(taken);
    if (!mounted) return;
    setState(() {
      _phrase = _engine.next(widget.level, _phrase);
      _controller.clear();
      _shownAt = DateTime.now();
      _message = 'Not an exact match. Here is a new phrase.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return ListView(
      children: [
        Text('Type this phrase exactly',
            style: TextStyle(fontSize: 14, color: c.mutedForeground)),
        const SizedBox(height: 8),
        _card(
          c,
          Text(
            _phrase,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: c.foreground,
            ),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _controller,
          autofocus: true,
          autocorrect: false,
          enableSuggestions: false,
          textCapitalization: TextCapitalization.none,
          minLines: 1,
          maxLines: 3,
          onChanged: (_) => widget.callbacks.onInput(),
          decoration: _fieldDecoration(c, 'Type here', error: _message),
        ),
        const SizedBox(height: 12),
        _submitButton('Submit', _submit),
      ],
    );
  }
}

// Shake --------------------------------------------------------------------

class ShakeChallengeBody extends StatefulWidget {
  const ShakeChallengeBody({
    super.key,
    required this.level,
    required this.callbacks,
    required this.onUnavailable,
  });

  final int level;
  final ChallengeCallbacks callbacks;

  /// Called when the device has no usable motion sensor.
  final VoidCallback onUnavailable;

  @override
  State<ShakeChallengeBody> createState() => _ShakeChallengeBodyState();
}

class _ShakeChallengeBodyState extends State<ShakeChallengeBody> {
  final _counter = ShakeCounter();
  StreamSubscription<AccelerometerEvent>? _subscription;
  Timer? _sensorCheck;
  bool _receivedSample = false;
  bool _done = false;
  final DateTime _startedAt = DateTime.now();

  int get _required => shakesRequired(widget.level);

  @override
  void initState() {
    super.initState();
    _subscription = accelerometerEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).listen(_onSample, onError: (Object _) => widget.onUnavailable());
    // No samples at all within a few seconds means there is no sensor.
    _sensorCheck = Timer(const Duration(seconds: 4), () {
      if (!_receivedSample && mounted) widget.onUnavailable();
    });
  }

  void _onSample(AccelerometerEvent event) {
    _receivedSample = true;
    if (_done) return;
    if (_counter.add(event.x, event.y, event.z, DateTime.now())) {
      widget.callbacks.onInput();
      HapticFeedback.lightImpact();
      setState(() {});
      if (_counter.count >= _required) {
        _done = true;
        widget.callbacks.onSolved(DateTime.now().difference(_startedAt));
      }
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _sensorCheck?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final count = math.min(_counter.count, _required);
    final progress = count / _required;

    return Column(
      children: [
        const SizedBox(height: 24),
        SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 10,
                  color: c.primary,
                  backgroundColor: c.secondary,
                ),
              ),
              Semantics(
                liveRegion: true,
                label: '$count of $_required shakes',
                child: ExcludeSemantics(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$count',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 56,
                          fontWeight: FontWeight.w600,
                          color: c.foreground,
                        ),
                      ),
                      Text('of $_required shakes',
                          style: TextStyle(color: c.mutedForeground)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Shake your phone',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: c.foreground,
          ),
        ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            color: c.primary,
            backgroundColor: c.secondary,
          ),
        ),
      ],
    );
  }
}
