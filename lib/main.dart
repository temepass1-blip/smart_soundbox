import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:notification_listener_service/notification_event.dart';
import 'package:permission_handler/permission_handler.dart';
import 'core/payment_parser.dart';
import 'core/transaction_manager.dart';
import 'core/voice_engine.dart';

import 'ui/history_screen.dart';
import 'ui/about_screen.dart';

import 'services/background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await VoiceEngine().init();
  await initializeBackgroundService();
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
    const AboutScreen(),
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
          BottomNavigationBarItem(
            icon: Icon(Icons.info),
            label: 'About',
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
  bool isBhimEnabled = true;
  bool isAmazonPayEnabled = true;
  bool isCredEnabled = true;
  bool _hasPermission = false;
  bool _hasSmsPermission = false;
  bool _isBatteryOptimizationIgnored = false;
  String _selectedLanguage = 'hi-IN';
  final TextEditingController _customPkgController = TextEditingController();
  List<String> _customPackages = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    bool notifStatus = await NotificationListenerService.isPermissionGranted();
    bool smsStatus = await Permission.sms.isGranted;
    bool batteryStatus = await Permission.ignoreBatteryOptimizations.isGranted;
    setState(() {
      _hasPermission = notifStatus;
      _hasSmsPermission = smsStatus;
      _isBatteryOptimizationIgnored = batteryStatus;
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isPhonePeEnabled = prefs.getBool('phonepe') ?? true;
      isGPayEnabled = prefs.getBool('gpay') ?? true;
      isPaytmEnabled = prefs.getBool('paytm') ?? true;
      isBhimEnabled = prefs.getBool('bhim') ?? true;
      isAmazonPayEnabled = prefs.getBool('amazonpay') ?? true;
      isCredEnabled = prefs.getBool('cred') ?? true;
      _customPackages = prefs.getStringList('custom_packages') ?? [];
      _selectedLanguage = prefs.getString('language') ?? 'hi-IN';
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
      _checkPermissions();
    }
  }

  void _requestSmsPermission() async {
    await Permission.sms.request();
    _checkPermissions();
  }

  void _requestBatteryBypass() async {
    await Permission.ignoreBatteryOptimizations.request();
    _checkPermissions();
  }

  void _setLanguage(String lang) {
    setState(() {
      _selectedLanguage = lang;
    });
    VoiceEngine().setAppLanguage(lang);
  }

  void _addCustomPackage(String pkg) {
    if (pkg.isNotEmpty && !_customPackages.contains(pkg)) {
      setState(() {
        _customPackages.add(pkg);
      });
      _saveCustomPackages();
    }
  }

  final List<Map<String, String>> _popularBanks = const [
    {'name': 'YONO SBI', 'package': 'com.sbi.lotusintouch'},
    {'name': 'BHIM SBI Pay', 'package': 'com.sbi.UPI20'},
    {'name': 'iMobile Pay (ICICI)', 'package': 'com.csam.icici.bank.imobile'},
    {'name': 'PayZapp (HDFC)', 'package': 'com.hdfcbank.payzapp'},
    {'name': 'Axis Mobile', 'package': 'com.axis.mobile'},
    {'name': 'bob World (Bank of Baroda)', 'package': 'com.bankofbaroda.mconnect'},
    {'name': 'Canara ai1', 'package': 'com.canarabank.mobility'},
    {'name': 'PNB ONE', 'package': 'com.roam.pnb'},
    {'name': 'Kotak Mobile Banking', 'package': 'com.msf.kbank.mobile'},
    {'name': 'Freecharge', 'package': 'com.freecharge.android'},
    {'name': 'MobiKwik', 'package': 'com.mobikwik_new'},
    {'name': 'BharatPe', 'package': 'com.bharatpe.app'},
  ];

  void _showAppPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Select Bank App"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _popularBanks.length,
              itemBuilder: (context, index) {
                final app = _popularBanks[index];
                return ListTile(
                  leading: const Icon(Icons.account_balance, color: Colors.blue),
                  title: Text(app['name']!),
                  subtitle: Text(app['package']!),
                  onTap: () {
                    _addCustomPackage(app['package']!);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _removeCustomPackage(String pkg) {
    setState(() {
      _customPackages.remove(pkg);
    });
    _saveCustomPackages();
  }

  Future<void> _saveCustomPackages() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('custom_packages', _customPackages);
  }



  void _testVoice() {
    Transaction t = Transaction(
      sender: "Rahul", 
      amount: 100, 
      upiRef: "test_ref_123", 
      source: "test", 
      timestamp: DateTime.now()
    );
    VoiceEngine().speak(t);
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
          SwitchListTile(
            title: const Text('BHIM UPI'),
            value: isBhimEnabled,
            onChanged: (val) {
              setState(() => isBhimEnabled = val);
              _saveSetting('bhim', val);
            },
          ),
          SwitchListTile(
            title: const Text('Amazon Pay'),
            value: isAmazonPayEnabled,
            onChanged: (val) {
              setState(() => isAmazonPayEnabled = val);
              _saveSetting('amazonpay', val);
            },
          ),
          SwitchListTile(
            title: const Text('CRED'),
            value: isCredEnabled,
            onChanged: (val) {
              setState(() => isCredEnabled = val);
              _saveSetting('cred', val);
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Custom App Sources',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton.icon(
              onPressed: _showAppPicker,
              icon: const Icon(Icons.add),
              label: const Text('Select App From Device'),
            ),
          ),
          ..._customPackages.map((pkg) => ListTile(
                title: Text(pkg),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeCustomPackage(pkg),
                ),
              )),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Language & Voices',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            title: const Text('Announcement Language'),
            trailing: DropdownButton<String>(
              value: _selectedLanguage,
              items: const [
                DropdownMenuItem(value: 'hi-IN', child: Text('Hindi (Natural)')),
                DropdownMenuItem(value: 'en-IN', child: Text('English (India)')),
              ],
              onChanged: (val) {
                if (val != null) _setLanguage(val);
              },
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text('Test Voice Announcement'),
            trailing: const Icon(Icons.volume_up),
            onTap: _testVoice,
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Required Permissions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          if (!_hasPermission)
            ListTile(
              title: const Text('Grant Notification Permission', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.warning, color: Colors.red),
              onTap: _requestPermissions,
            )
          else
            const ListTile(
              title: Text('Notification Permission Granted', style: TextStyle(color: Colors.green)),
              trailing: Icon(Icons.check_circle, color: Colors.green),
            ),
          if (!_hasSmsPermission)
            ListTile(
              title: const Text('Grant SMS Permission (Required for Offline Alerts)', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.warning, color: Colors.red),
              onTap: _requestSmsPermission,
            )
          else
            const ListTile(
              title: Text('SMS Permission Granted', style: TextStyle(color: Colors.green)),
              trailing: Icon(Icons.check_circle, color: Colors.green),
            ),
          if (!_isBatteryOptimizationIgnored)
            ListTile(
              title: const Text('Disable Battery Optimization (Keeps app running)', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.battery_alert, color: Colors.orange),
              onTap: _requestBatteryBypass,
            )
          else
            const ListTile(
              title: Text('Battery Optimization Disabled', style: TextStyle(color: Colors.green)),
              trailing: Icon(Icons.battery_charging_full, color: Colors.green),
            ),
        ],
      ),
    );
  }
}
