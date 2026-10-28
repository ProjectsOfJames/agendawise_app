import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/domain/challenge_type.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/screen_header.dart';
import '../../alarms/application/ringing_controller.dart';
import '../../alarms/domain/alarm_rules.dart';
import '../application/challenge_controller.dart';
import '../application/challenge_volume.dart';
import 'challenge_bodies.dart';

/// Hosts the challenge that must be solved to stop a ringing alarm.
///
/// There is no close control and the back action is blocked. The sound is
/// lowered while the user works and returns to full volume after 30 seconds
/// without input; any input lowers it again. A wrong answer is logged and
/// replaced by a new question.
class ChallengeScreen extends ConsumerStatefulWidget {
  const ChallengeScreen({super.key, required this.alarmId});

  final String alarmId;

  @override
  ConsumerState<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends ConsumerState<ChallengeScreen> {
  Alarm? _alarm;
  ChallengeType? _type;
  int _level = 2;
  bool _loading = true;
  bool _finishing = false;

  late final ChallengeVolume _volume;
  Timer? _idleTimer;
  DateTime _lastInput = DateTime.now();
  bool _atFullVolume = false;

  @override
  void initState() {
    super.initState();
    _volume = ref.read(challengeVolumeProvider);
    _load();
  }

  Future<void> _load() async {
    final saved =
        await ref.read(challengeControllerProvider).load(widget.alarmId);
    if (!mounted) return;
    final alarm = saved?.alarm;
    final challenge = saved?.challenge;
    if (alarm == null || challenge == null) {
      // Nothing to solve: stop the alarm as a plain dismiss would.
      final ringing = ref.read(ringingControllerProvider);
      if (alarm == null) {
        await ringing.stopOrphan(widget.alarmId);
      } else {
        await ringing.dismiss(alarm);
      }
      if (mounted) _leave();
      return;
    }
    setState(() {
      _alarm = alarm;
      _type = challenge.challengeType;
      _level = challenge.difficulty;
      _loading = false;
    });
    await _volume.start();
    _lastInput = DateTime.now();
    _idleTimer = Timer.periodic(const Duration(seconds: 1), (_) => _checkIdle());
  }

  void _checkIdle() {
    if (_atFullVolume) return;
    if (DateTime.now().difference(_lastInput) >= challengeIdleLimit) {
      _atFullVolume = true;
      _volume.full();
      if (mounted) setState(() {});
    }
  }

  void _onInput() {
    _lastInput = DateTime.now();
    if (_atFullVolume) {
      _atFullVolume = false;
      _volume.quiet();
      if (mounted) setState(() {});
    }
  }

  Future<void> _onWrong(Duration taken) async {
    final alarm = _alarm, type = _type;
    if (alarm == null || type == null) return;
    await ref.read(challengeControllerProvider).recordFailure(
          alarm: alarm,
          type: type,
          level: _level,
          duration: taken,
        );
  }

  Future<void> _onSolved(Duration taken) async {
    final alarm = _alarm, type = _type;
    if (alarm == null || type == null || _finishing) return;
    setState(() => _finishing = true);
    _idleTimer?.cancel();
    await _volume.finish();
    await ref.read(challengeControllerProvider).complete(
          alarm: alarm,
          type: type,
          level: _level,
          duration: taken,
        );
    if (mounted) _leave();
  }

  /// Without a motion sensor the shake challenge cannot be solved, so a
  /// maths challenge at the same level is used instead.
  void _onShakeUnavailable() {
    if (_type != ChallengeType.shake) return;
    setState(() => _type = ChallengeType.maths);
  }

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.alarms);
    }
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final type = _type;

    Widget body;
    if (_loading || type == null) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_finishing) {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, size: 64, color: c.success),
            const SizedBox(height: 12),
            Text('Solved. Good morning!',
                style: TextStyle(fontSize: 18, color: c.foreground)),
          ],
        ),
      );
    } else {
      final callbacks = ChallengeCallbacks(
        onInput: _onInput,
        onWrong: _onWrong,
        onSolved: _onSolved,
      );
      body = switch (type) {
        ChallengeType.maths =>
          MathsChallengeBody(level: _level, callbacks: callbacks),
        ChallengeType.memory =>
          MemoryChallengeBody(level: _level, callbacks: callbacks),
        ChallengeType.phrase =>
          PhraseChallengeBody(level: _level, callbacks: callbacks),
        ChallengeType.shake => ShakeChallengeBody(
            level: _level,
            callbacks: callbacks,
            onUnavailable: _onShakeUnavailable,
          ),
      };
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionLabel('Challenge · ${challengeName(type)}'),
                const SizedBox(height: 16),
                Expanded(child: body),
                if (!_loading && !_finishing) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoPill('Difficulty $_level of 5'),
                      _InfoPill(_atFullVolume
                          ? 'Sound at full volume'
                          : 'Sound at ${(challengeVolumeShare * 100).round()}%'),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: c.primary.withValues(alpha: 0.45)),
      ),
      child: Text(text, style: TextStyle(fontSize: 13, color: c.foreground)),
    );
  }
}
