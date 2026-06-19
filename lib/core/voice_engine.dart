import 'dart:collection';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'payment_parser.dart';

class VoiceEngine {
  static final VoiceEngine _instance = VoiceEngine._internal();
  factory VoiceEngine() => _instance;
  VoiceEngine._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;
  final Queue<Transaction> _queue = Queue<Transaction>();

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedVoiceName = prefs.getString('voice_name');
    String? savedVoiceLocale = prefs.getString('voice_locale');

    if (savedVoiceName != null && savedVoiceLocale != null) {
      await _flutterTts.setVoice({"name": savedVoiceName, "locale": savedVoiceLocale});
    } else {
      await _flutterTts.setLanguage("hi-IN");
    }

    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
      _processQueue();
    });
  }

  Future<List<Map<String, String>>> getVoices() async {
    final voices = await _flutterTts.getVoices;
    List<Map<String, String>> voiceList = [];
    
    if (voices != null) {
      int hiCount = 1;
      int enCount = 1;

      for (var voice in voices) {
        Map<String, String> v = Map<String, String>.from(voice);
        String locale = v['locale'] ?? '';
        
        if (locale.toLowerCase().startsWith('hi')) {
          v['displayName'] = 'Hindi Voice $hiCount';
          hiCount++;
          voiceList.add(v);
        } else if (locale.toLowerCase().startsWith('en')) {
          v['displayName'] = 'English Voice $enCount';
          enCount++;
          voiceList.add(v);
        }
      }
    }
    return voiceList;
  }

  Future<void> setVoice(Map<String, String> voice) async {
    await _flutterTts.setVoice({"name": voice["name"]!, "locale": voice["locale"]!});
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('voice_name', voice["name"]!);
    await prefs.setString('voice_locale', voice["locale"]!);
  }

  void speak(Transaction transaction) {
    _queue.add(transaction);
    _processQueue();
  }

  void _processQueue() async {
    if (_isSpeaking || _queue.isEmpty) return;

    _isSpeaking = true;
    final transaction = _queue.removeFirst();
    
    // Format: "Rahul se 100 rupaye prapt hue"
    String text = "";
    if (transaction.sender != 'Customer') {
      text = "${transaction.sender} se ${transaction.amount.toInt()} rupaye prapt hue";
    } else {
      text = "${transaction.amount.toInt()} rupaye prapt hue";
    }

    await _flutterTts.speak(text);
  }
}
