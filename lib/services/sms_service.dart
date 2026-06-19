import 'package:telephony/telephony.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/payment_parser.dart';
import '../core/transaction_manager.dart';

// Top-level function for background execution if needed
void backgroundMessageHandler(SmsMessage message) async {
  await SmsService.processSmsMessage(message);
}

class SmsService {
  static final Telephony telephony = Telephony.instance;

  static Future<void> initialize() async {
    bool? permissionsGranted = await telephony.requestPhoneAndSmsPermissions;
    if (permissionsGranted != null && permissionsGranted) {
      telephony.listenIncomingSms(
        onNewMessage: (SmsMessage message) {
          processSmsMessage(message);
        },
        onBackgroundMessage: backgroundMessageHandler,
      );
    }
  }

  static Future<void> processSmsMessage(SmsMessage message) async {
    if (message.body == null || message.address == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    final smsEnabled = prefs.getBool('sms') ?? true;
    
    if (!smsEnabled) return;

    // A bank SMS usually comes from a sender like 'VK-SBIUPI', 'AD-HDFCBK', etc.
    String senderAddress = message.address!.toUpperCase();
    
    // Quick filter: typical bank short codes have letters or hyphen (e.g. AX-HDFC)
    // Adjust according to actual Indian bank sender IDs
    bool isBankSms = senderAddress.contains(RegExp(r'[A-Z]')); 
    
    if (!isBankSms) return;

    // Use the existing parser since bank SMS text also contains 'credited', 'amount', etc.
    Transaction? t = PaymentParser.parseNotification(senderAddress, message.body!, 'SMS');
    
    if (t != null) {
      TransactionManager().processNewTransaction(t);
    }
  }
}
