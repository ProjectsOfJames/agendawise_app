import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/platform/permission_gate.dart';
import '../../../core/platform/speech_service.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/clock.dart';
import '../../../shared/widgets/form_screen_scaffold.dart';
import '../application/voice_providers.dart';
import 'voice_confirm_screen.dart';
import 'voice_widgets.dart';

enum _Stage { starting, listening, failed }

/// Listens while the screen is open and shows the words as they arrive.
/// When the user stops speaking, the result opens the confirmation screen,
/// or the fallback screen if it was not understood.
class VoiceListeningScreen extends ConsumerStatefulWidget {
  const VoiceListeningScreen({super.key});

  @override
  ConsumerState<VoiceListeningScreen> createState() =>
      _VoiceListeningScreenState();
}

class _VoiceListeningScreenState extends ConsumerState<VoiceListeningScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  _Stage _stage = _Stage.starting;
  String _heard = '';
  String? _problem;
  bool _offline = true;
  bool _finished = false;

  late final SpeechService _speech;

  @override
  void initState() {
    super.initState();
    _speech = ref.read(speechServiceProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    _pulse.dispose();
    if (!_finished) _speech.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() {
      _stage = _Stage.starting;
      _heard = '';
      _problem = null;
    });
    final allowed =
        await ref.read(permissionGateProvider).ensureForMicrophone(context);
    if (!mounted) return;
    if (!allowed) {
      _fail('Voice input needs the microphone. You can type instead.');
      return;
    }
    if (!await _speech.initialize()) {
      _fail('Speech recognition is not available on this device. '
          'You can type instead.');
      return;
    }
    if (!mounted) return;
    await _listen();
  }

  Future<void> _listen() async {
    setState(() => _stage = _Stage.listening);
    _pulse.repeat();
    await _speech.listen(
      preferOffline: _offline,
      onWords: (words, isFinal) {
        if (!mounted || _finished) return;
        setState(() => _heard = words);
        if (isFinal) _finish(words);
      },
      onFailure: _onFailure,
      onDone: () {
        if (!mounted || _finished) return;
        if (_heard.trim().isNotEmpty) {
          _finish(_heard);
        } else {
          _fail("I didn't catch that. Try again, or type instead.");
        }
      },
    );
  }

  void _onFailure(SpeechFailure failure) {
    if (!mounted || _finished) return;
    if (failure == SpeechFailure.offlineUnavailable &&
        _offline &&
        _heard.isEmpty) {
      // No offline model for this language: try the online recogniser.
      setState(() => _offline = false);
      _listen();
      return;
    }
    if (_heard.trim().isNotEmpty && failure == SpeechFailure.noSpeech) {
      _finish(_heard);
      return;
    }
    _fail(switch (failure) {
      SpeechFailure.noSpeech =>
        "I didn't catch that. Try again, or type instead.",
      SpeechFailure.network =>
        'Offline recognition is not available and there is no internet '
            'connection. Try again later, or type instead.',
      SpeechFailure.permission =>
        'Voice input needs the microphone. You can type instead.',
      SpeechFailure.offlineUnavailable ||
      SpeechFailure.other =>
        'Voice input stopped unexpectedly. Try again, or type instead.',
    });
  }

  void _fail(String message) {
    _pulse.stop();
    setState(() {
      _stage = _Stage.failed;
      _problem = message;
    });
  }

  void _finish(String words) {
    if (_finished) return;
    _finished = true;
    _pulse.stop();
    _speech.stop();
    final intent = ref.read(intentParserProvider).parse(
          words,
          ref.read(clockProvider)(),
        );
    if (intent.isUnderstood) {
      context.pushReplacement(
        AppRoutes.voiceConfirm,
        extra: VoiceConfirmArgs(intent: intent, understood: true),
      );
    } else {
      context.pushReplacement(AppRoutes.voiceFallback, extra: words);
    }
  }

  void _close() {
    _finished = true;
    _speech.cancel();
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final listening = _stage == _Stage.listening;

    return FormScreenScaffold(
      title: 'Voice input',
      onClose: _close,
      bottom: [
        if (_stage == _Stage.failed) ...[
          VoicePrimaryButton(label: 'Try again', onPressed: _start),
          const SizedBox(height: 10),
          VoiceOutlinedButton(
            label: 'Type instead',
            onPressed: () => context.pushReplacement(
              AppRoutes.voiceFallback,
              extra: _heard,
            ),
          ),
        ] else
          VoiceOutlinedButton(label: 'Cancel', onPressed: _close),
      ],
      children: [
        const SizedBox(height: 24),
        Center(
          child: Semantics(
            button: listening,
            label: listening ? 'Stop listening' : 'Microphone',
            child: GestureDetector(
              onTap: listening && _heard.isNotEmpty ? () => _finish(_heard) : null,
              child: _PulsingMic(animation: _pulse, active: listening),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          switch (_stage) {
            _Stage.starting => 'Getting ready…',
            _Stage.listening => 'Listening...',
            _Stage.failed => 'Not listening',
          },
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: c.foreground,
          ),
        ),
        if (_problem != null) ...[
          const SizedBox(height: 8),
          Text(
            _problem!,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: c.mutedForeground),
          ),
        ],
        const SizedBox(height: 20),
        HeardCard(
          caption: 'Heard so far',
          child: Text(
            _heard.isEmpty ? 'Say something like "remind me to call Sam '
                'tomorrow at 9"' : _heard,
            style: TextStyle(
              fontSize: 15,
              color: _heard.isEmpty ? c.mutedForeground : c.foreground,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: c.primary.withValues(alpha: 0.45)),
            ),
            child: Text(
              _offline
                  ? 'Offline recognition preferred'
                  : 'Using online recognition',
              style: TextStyle(fontSize: 13, color: c.foreground),
            ),
          ),
        ),
        if (listening && _heard.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Tap the microphone when you are done.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: c.mutedForeground),
          ),
        ],
      ],
    );
  }
}

class _PulsingMic extends StatelessWidget {
  const _PulsingMic({required this.animation, required this.active});

  final Animation<double> animation;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return SizedBox(
      width: 150,
      height: 150,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final t = active ? animation.value : 0.0;
          return Stack(
            alignment: Alignment.center,
            children: [
              for (final phase in const [0.0, 0.5])
                Builder(builder: (context) {
                  final p = (t + phase) % 1.0;
                  return Container(
                    width: 80 + 70 * p,
                    height: 80 + 70 * p,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: c.primary
                          .withValues(alpha: active ? 0.22 * (1 - p) : 0.08),
                    ),
                  );
                }),
              child!,
            ],
          );
        },
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? c.primary : c.muted,
          ),
          child: Icon(
            Icons.mic_none_rounded,
            size: 32,
            color: active ? c.primaryForeground : c.mutedForeground,
          ),
        ),
      ),
    );
  }
}
