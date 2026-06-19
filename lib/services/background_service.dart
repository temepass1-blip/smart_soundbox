import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:notification_listener_service/notification_event.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/payment_parser.dart';
import '../core/transaction_manager.dart';
import '../core/voice_engine.dart';

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  // Android notification channel
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'smart_soundbox_bg', // id
    'Smart Soundbox Running', // title
    description: 'This channel is used for important notifications.', // description
    importance: Importance.low, // importance must be at low or higher level
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'smart_soundbox_bg',
      initialNotificationTitle: 'Smart Soundbox Active',
      initialNotificationContent: 'Listening for incoming payments...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize TTS Engine in the background isolate
  await VoiceEngine().init();

  // Listen to Notification Service
  NotificationListenerService.notificationsStream.listen((ServiceNotificationEvent event) async {
    final prefs = await SharedPreferences.getInstance();
    final phonePeEnabled = prefs.getBool('phonepe') ?? true;
    final gPayEnabled = prefs.getBool('gpay') ?? true;
    final paytmEnabled = prefs.getBool('paytm') ?? true;
    final customPackages = prefs.getStringList('custom_packages') ?? [];

    String pkg = (event.packageName ?? '').toLowerCase();
    bool isAllowed = false;

    if (pkg.contains('phonepe') && phonePeEnabled) isAllowed = true;
    if (pkg.contains('apps.nbu.paisa.user') && gPayEnabled) isAllowed = true; // GPay package
    if (pkg.contains('paytm') && paytmEnabled) isAllowed = true;

    for (String customPkg in customPackages) {
      if (pkg.contains(customPkg.toLowerCase())) {
        isAllowed = true;
        break;
      }
    }

    if (!isAllowed) return;

    Transaction? t = PaymentParser.parseNotification(event.title ?? '', event.content ?? '', event.packageName ?? '');
    if (t != null) {
      TransactionManager().processNewTransaction(t);
    }
  });
}
