import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'platform_support.dart';

/// Why listening stopped without a usable result.
enum SpeechFailure {
  /// Nothing was said, or nothing could be matched to words.
  noSpeech,

  /// The on-device recogniser cannot handle the language right now; an
  /// online attempt may still work.
  offlineUnavailable,

  /// No connection for online recognition.
  network,

  /// The microphone permission is missing.
  permission,

  other,
}

/// Speech recognition behind a small interface so screens and tests do
/// not depend on the plugin.
abstract interface class SpeechService {
  /// Prepares the recogniser. False when the device has none.
  Future<bool> initialize();

  /// Starts listening. [onWords] receives the words heard so far, with
  /// `isFinal` set once the user has finished speaking. [onDone] fires when
  /// listening ends without a final result.
  Future<void> listen({
    required bool preferOffline,
    required void Function(String words, bool isFinal) onWords,
    required void Function(SpeechFailure failure) onFailure,
    required VoidCallback onDone,
  });

  Future<void> stop();

  Future<void> cancel();
}

class UnavailableSpeechService implements SpeechService {
  const UnavailableSpeechService();

  @override
  Future<bool> initialize() async => false;

  @override
  Future<void> listen({
    required bool preferOffline,
    required void Function(String words, bool isFinal) onWords,
    required void Function(SpeechFailure failure) onFailure,
    required VoidCallback onDone,
  }) async =>
      onFailure(SpeechFailure.other);

  @override
  Future<void> stop() async {}

  @override
  Future<void> cancel() async {}
}

/// Android's speech recogniser through the speech_to_text plugin. English
/// is used, preferring South African English when the device offers it.
class DeviceSpeechService implements SpeechService {
  final _speech = SpeechToText();
  bool _ready = false;
  String? _localeId;

  // The plugin accepts callbacks only on the first initialise, so they
  // forward to whichever listening session is current.
  void Function(SpeechFailure failure)? _onFailure;
  VoidCallback? _onDone;
  bool _gotFinal = false;

  @override
  Future<bool> initialize() async {
    if (_ready) return true;
    try {
      _ready = await _speech.initialize(
        onStatus: _handleStatus,
        onError: _handleError,
      );
    } on Object catch (error) {
      debugPrint('Speech recognition unavailable: $error');
      _ready = false;
    }
    if (_ready) _localeId ??= await _pickLocale();
    return _ready;
  }

  Future<String?> _pickLocale() async {
    try {
      final ids = (await _speech.locales()).map((l) => l.localeId).toList();
      String? find(String wanted) {
        for (final id in ids) {
          if (id.replaceAll('-', '_').toLowerCase() == wanted) return id;
        }
        return null;
      }

      final system = (await _speech.systemLocale())?.localeId;
      if (system != null && system.toLowerCase().startsWith('en')) {
        return find('en_za') ?? system;
      }
      return find('en_za') ?? find('en_gb') ?? find('en_us');
    } on Object {
      return null;
    }
  }

  void _handleStatus(String status) {
    if (status == SpeechToText.doneStatus && !_gotFinal) {
      final done = _onDone;
      _onDone = null;
      done?.call();
    }
  }

  void _handleError(SpeechRecognitionError error) {
    final failure = switch (error.errorMsg) {
      'error_no_match' || 'error_speech_timeout' => SpeechFailure.noSpeech,
      'error_language_unavailable' ||
      'error_language_not_supported' ||
      'error_server' ||
      'error_server_disconnected' =>
        SpeechFailure.offlineUnavailable,
      'error_network' || 'error_network_timeout' => SpeechFailure.network,
      'error_permission' ||
      'error_insufficient_permissions' =>
        SpeechFailure.permission,
      _ => SpeechFailure.other,
    };
    debugPrint('Speech error: ${error.errorMsg}');
    final onFailure = _onFailure;
    _onFailure = null;
    _onDone = null;
    onFailure?.call(failure);
  }

  @override
  Future<void> listen({
    required bool preferOffline,
    required void Function(String words, bool isFinal) onWords,
    required void Function(SpeechFailure failure) onFailure,
    required VoidCallback onDone,
  }) async {
    if (!await initialize()) {
      onFailure(SpeechFailure.other);
      return;
    }
    _onFailure = onFailure;
    _onDone = onDone;
    _gotFinal = false;
    await _speech.listen(
      onResult: (SpeechRecognitionResult result) {
        if (result.finalResult) {
          _gotFinal = true;
          _onFailure = null;
          _onDone = null;
        }
        onWords(result.recognizedWords, result.finalResult);
      },
      listenOptions: SpeechListenOptions(
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 4),
        localeId: _localeId,
        partialResults: true,
        onDevice: preferOffline,
        cancelOnError: true,
        listenMode: ListenMode.dictation,
      ),
    );
  }

  @override
  Future<void> stop() => _speech.stop();

  @override
  Future<void> cancel() async {
    _onFailure = null;
    _onDone = null;
    await _speech.cancel();
  }
}

final speechServiceProvider = Provider<SpeechService>(
  (ref) =>
      isAndroidDevice ? DeviceSpeechService() : const UnavailableSpeechService(),
);
