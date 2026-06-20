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
    String language = prefs.getString('language') ?? 'hi-IN';

    await _flutterTts.setLanguage(language);
    await _flutterTts.setSpeechRate(0.45); // Slower for clear announcement
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(0.95); // Slightly lower pitch for professional sound

    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
      _processQueue();
    });
  }

  Future<void> setAppLanguage(String langCode) async {
    await _flutterTts.setLanguage(langCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', langCode);
  }

  void speak(Transaction transaction) {
    _queue.add(transaction);
    _processQueue();
  }

  void _processQueue() async {
    if (_isSpeaking || _queue.isEmpty) return;

    _isSpeaking = true;
    final transaction = _queue.removeFirst();
    
    final prefs = await SharedPreferences.getInstance();
    String language = prefs.getString('language') ?? 'hi-IN';

    String text = "";
    if (language == 'hi-IN') {
      if (transaction.sender != 'Customer') {
        text = "${transaction.sender} se ${transaction.amount.toInt()} rupaye prapt hue";
      } else {
        text = "${transaction.amount.toInt()} rupaye prapt hue";
      }
    } else {
      if (transaction.sender != 'Customer') {
        text = "Received ${transaction.amount.toInt()} rupees from ${transaction.sender}";
      } else {
        text = "Received ${transaction.amount.toInt()} rupees";
      }
    }

    await _flutterTts.speak(text);
  }
}
