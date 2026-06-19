import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:notification_listener_service/notification_event.dart';
import 'core/payment_parser.dart';
import 'core/transaction_manager.dart';
import 'core/voice_engine.dart';

import 'ui/history_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await VoiceEngine().init();
  runApp(const SmartSoundBoxApp());
}

class SmartSoundBoxApp extends StatelessWidget {
  const SmartSoundBoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart SoundBox',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const SettingsScreen(),
    const HistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isPhonePeEnabled = true;
  bool isGPayEnabled = true;
  bool isPaytmEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _requestPermissions();
    _startListening();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isPhonePeEnabled = prefs.getBool('phonepe') ?? true;
      isGPayEnabled = prefs.getBool('gpay') ?? true;
      isPaytmEnabled = prefs.getBool('paytm') ?? true;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  void _requestPermissions() async {
    bool status = await NotificationListenerService.isPermissionGranted();
    if (!status) {
      await NotificationListenerService.requestPermission();
    }
  }

  void _startListening() {
    NotificationListenerService.notificationsStream.listen((ServiceNotificationEvent event) async {
      final prefs = await SharedPreferences.getInstance();
      final phonePeEnabled = prefs.getBool('phonepe') ?? true;
      final gPayEnabled = prefs.getBool('gpay') ?? true;
      final paytmEnabled = prefs.getBool('paytm') ?? true;

      String pkg = (event.packageName ?? '').toLowerCase();
      bool isAllowed = false;

      if (pkg.contains('phonepe') && phonePeEnabled) isAllowed = true;
      if (pkg.contains('apps.nbu.paisa.user') && gPayEnabled) isAllowed = true; // GPay package
      if (pkg.contains('paytm') && paytmEnabled) isAllowed = true;

      if (!isAllowed) return;

      Transaction? t = PaymentParser.parseNotification(event.title ?? '', event.content ?? '', event.packageName ?? '');
      if (t != null) {
        TransactionManager().processNewTransaction(t);
      }
    });
  }

  void _testVoice() {
    Transaction t = Transaction(
      sender: "Rahul", 
      amount: 100, 
      upiRef: "test_ref_123", 
      source: "test", 
      timestamp: DateTime.now()
    );
    TransactionManager().processNewTransaction(t);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart SoundBox Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Select Sources',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          SwitchListTile(
            title: const Text('PhonePe'),
            value: isPhonePeEnabled,
            onChanged: (val) {
              setState(() => isPhonePeEnabled = val);
              _saveSetting('phonepe', val);
            },
          ),
          SwitchListTile(
            title: const Text('Google Pay'),
            value: isGPayEnabled,
            onChanged: (val) {
              setState(() => isGPayEnabled = val);
              _saveSetting('gpay', val);
            },
          ),
          SwitchListTile(
            title: const Text('Paytm'),
            value: isPaytmEnabled,
            onChanged: (val) {
              setState(() => isPaytmEnabled = val);
              _saveSetting('paytm', val);
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Test Voice Announcement'),
            trailing: const Icon(Icons.volume_up),
            onTap: _testVoice,
          ),
          ListTile(
            title: const Text('Grant Notification Permission'),
            trailing: const Icon(Icons.settings),
            onTap: _requestPermissions,
          ),
        ],
      ),
    );
  }
}
