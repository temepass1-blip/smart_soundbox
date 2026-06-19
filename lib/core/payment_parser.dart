class Transaction {
  final String sender;
  final double amount;
  final String upiRef;
  final String source;
  final DateTime timestamp;

  Transaction({
    required this.sender,
    required this.amount,
    required this.upiRef,
    required this.source,
    required this.timestamp,
  });
}

class PaymentParser {
  static Transaction? parseNotification(String title, String body, String sourceApp) {
    String textToSearch = "$title $body".toLowerCase();

    // 1. Check for basic payment keywords
    if (!textToSearch.contains('received') && 
        !textToSearch.contains('credited') && 
        !textToSearch.contains('paid')) {
      return null;
    }

    // 2. Filter out promotional content
    if (textToSearch.contains('cashback') || 
        textToSearch.contains('reward') || 
        textToSearch.contains('offer') ||
        textToSearch.contains('loan') ||
        textToSearch.contains('discount')) {
      return null;
    }

    // 3. Extract amount
    final amountRegex = RegExp(r'(?:rs|inr|₹|amount|rs\.|inr\.)\s*?(\d+(?:\.\d{1,2})?)', caseSensitive: false);
    final match = amountRegex.firstMatch(textToSearch);
    
    if (match == null) return null;
    
    double amount = double.tryParse(match.group(1) ?? '0') ?? 0;
    
    if (amount <= 0) return null;

    // 4. Extract sender
    String sender = 'Customer'; // default
    if (sourceApp.toLowerCase().contains('phonepe')) {
      final senderMatch = RegExp(r'from (.*?)(?=\s|$)').firstMatch(textToSearch);
      if (senderMatch != null) {
        sender = senderMatch.group(1) ?? 'Customer';
      }
    } else if (sourceApp.toLowerCase().contains('paytm')) {
      final senderMatch = RegExp(r'received (?:.*?) from (.*?)(?=\s|$)').firstMatch(textToSearch);
      if (senderMatch != null) {
        sender = senderMatch.group(1) ?? 'Customer';
      }
    }

    // 5. Generate a dummy or actual UPI Ref (in a real app, parse it if available)
    String upiRef = DateTime.now().millisecondsSinceEpoch.toString();

    return Transaction(
      sender: sender,
      amount: amount,
      upiRef: upiRef,
      source: sourceApp,
      timestamp: DateTime.now(),
    );
  }
}
