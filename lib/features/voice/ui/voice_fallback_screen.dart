import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/clock.dart';
import '../../../shared/widgets/form_screen_scaffold.dart';
import '../application/voice_providers.dart';
import '../domain/voice_intent.dart';
import 'voice_confirm_screen.dart';
import 'voice_widgets.dart';

/// Shown when the type or details were unclear: the text can be corrected
/// and sent to the confirmation screen as a task, alarm or event.
class VoiceFallbackScreen extends ConsumerStatefulWidget {
  const VoiceFallbackScreen({super.key, this.heard = ''});

  final String heard;

  @override
  ConsumerState<VoiceFallbackScreen> createState() =>
      _VoiceFallbackScreenState();
}

class _VoiceFallbackScreenState extends ConsumerState<VoiceFallbackScreen> {
  late final _text = TextEditingController(text: widget.heard);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _continueAs(VoiceIntentType type) {
    final intent = ref.read(intentParserProvider).parse(
          _text.text,
          ref.read(clockProvider)(),
          forceType: type,
        );
    // The whole text becomes the title when nothing else is left of it.
    final withTitle = intent.title.isEmpty && type != VoiceIntentType.alarm
        ? intent.copyWith(title: _text.text.trim())
        : intent;
    context.pushReplacement(
      AppRoutes.voiceConfirm,
      extra: VoiceConfirmArgs(intent: withTitle, understood: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final heardSomething = widget.heard.trim().isNotEmpty;

    return FormScreenScaffold(
      title: heardSomething ? 'Could not understand' : 'Type instead',
      onClose: () => context.pop(),
      bottom: [
        VoicePrimaryButton(
          label: 'Try speaking again',
          onPressed: () => context.pushReplacement(AppRoutes.voice),
        ),
      ],
      children: [
        Text(
          heardSomething
              ? 'The type or details were unclear. Edit the text, then choose '
                  'where it goes.'
              : 'Type what you want to add, then choose where it goes.',
          style: TextStyle(fontSize: 13, color: c.mutedForeground),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: c.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                heardSomething ? 'Heard (editable)' : 'Your text',
                style: TextStyle(fontSize: 12, color: c.mutedForeground),
              ),
              TextField(
                controller: _text,
                minLines: 3,
                maxLines: 6,
                autofocus: !heardSomething,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(fontSize: 15, color: c.foreground),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  hintText: 'e.g. Dentist on Friday at 10',
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        for (final (type, label) in const [
          (VoiceIntentType.task, 'Save as task'),
          (VoiceIntentType.alarm, 'Save as alarm'),
          (VoiceIntentType.event, 'Save as event'),
        ]) ...[
          VoiceOutlinedButton(
            label: label,
            onPressed: _text.text.trim().isEmpty && type != VoiceIntentType.alarm
                ? null
                : () => _continueAs(type),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}
