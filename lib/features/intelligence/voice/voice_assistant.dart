import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Device speech engines. A spoken question becomes text and still requires
/// the existing confirmation screen before any transaction is saved.
class VoiceAssistant {
  VoiceAssistant() : _speech = SpeechToText(), _tts = FlutterTts();

  final SpeechToText _speech;
  final FlutterTts _tts;
  bool _ready = false;

  Future<bool> prepare() async {
    try {
      _ready = await _speech.initialize();
      return _ready;
    } catch (_) {
      _ready = false;
      return false;
    }
  }

  Future<void> listen({
    required String languageCode,
    required void Function(String text) onText,
  }) async {
    if (!_ready && !await prepare()) {
      throw StateError('speech-unavailable');
    }
    await _speech.listen(
      onResult: (result) => onText(result.recognizedWords),
      listenOptions: SpeechListenOptions(localeId: _locale(languageCode)),
    );
  }

  Future<void> stop() => _speech.stop();

  Future<void> speak(String text, String languageCode) async {
    try {
      await _tts.setLanguage(_locale(languageCode));
      await _tts.speak(text);
    } catch (_) {
      // The device has no matching voice. The written answer remains.
    }
  }

  String _locale(String languageCode) {
    if (languageCode.startsWith('fr')) return 'fr-FR';
    if (languageCode.startsWith('ar')) return 'ar-SA';
    return 'en-US';
  }
}

class VoiceButton extends StatefulWidget {
  const VoiceButton({super.key, required this.languageCode, required this.onText, required this.unavailableLabel});

  final String languageCode;
  final ValueChanged<String> onText;
  final String unavailableLabel;

  @override
  State<VoiceButton> createState() => _VoiceButtonState();
}

class _VoiceButtonState extends State<VoiceButton> {
  final _voice = VoiceAssistant();
  bool _listening = false;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: _listening ? widget.unavailableLabel : null,
      onPressed: () async {
        final messenger = ScaffoldMessenger.of(context);
        try {
          if (_listening) {
            await _voice.stop();
            if (mounted) setState(() => _listening = false);
            return;
          }
          setState(() => _listening = true);
          await _voice.listen(languageCode: widget.languageCode, onText: widget.onText);
        } catch (_) {
          if (!mounted) return;
          setState(() => _listening = false);
          messenger.showSnackBar(SnackBar(content: Text(widget.unavailableLabel)));
        }
      },
      icon: Icon(_listening ? Icons.stop : Icons.mic_none),
    );
  }
}
