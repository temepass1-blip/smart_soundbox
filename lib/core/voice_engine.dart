import 'dart:collection';
import 'package:flutter_tts/flutter_tts.dart';
import 'payment_parser.dart';

class VoiceEngine {
  static final VoiceEngine _instance = VoiceEngine._internal();
  factory VoiceEngine() => _instance;
  VoiceEngine._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;
  final Queue<Transaction> _queue = Queue<Transaction>();

  Future<void> init() async {
    await _flutterTts.setLanguage("hi-IN");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
      _processQueue();
    });
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
