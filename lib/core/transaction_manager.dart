import 'package:flutter/foundation.dart';
import 'payment_parser.dart';
import 'voice_engine.dart';

class TransactionManager {
  static final TransactionManager _instance = TransactionManager._internal();
  factory TransactionManager() => _instance;
  TransactionManager._internal();

  // Cache stores recent transactions to prevent duplicates
  final List<Transaction> _cache = [];

  void processNewTransaction(Transaction transaction) {
    _cleanOldCache();

    if (_isDuplicate(transaction)) {
      debugPrint("Duplicate transaction detected, ignoring.");
      return;
    }

    _cache.add(transaction);
    VoiceEngine().speak(transaction);
  }

  bool _isDuplicate(Transaction transaction) {
    for (var cached in _cache) {
      // If same amount, same sender, and within 5 minutes, consider it a duplicate
      // OR if the upiRef matches (if we actually extracted it).
      bool sameRef = (cached.upiRef == transaction.upiRef && transaction.upiRef.isNotEmpty);
      bool sameAmountSender = (cached.amount == transaction.amount && cached.sender == transaction.sender);
      bool withinTimeFrame = transaction.timestamp.difference(cached.timestamp).inMinutes < 5;

      if (sameRef || (sameAmountSender && withinTimeFrame)) {
        return true;
      }
    }
    return false;
  }

  void _cleanOldCache() {
    final now = DateTime.now();
    _cache.removeWhere((t) => now.difference(t.timestamp).inMinutes >= 5);
  }
}
