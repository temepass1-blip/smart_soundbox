import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:notification_listener_service/notification_event.dart';
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
  bool _hasPermission = false;
  List<Map<String, String>> _voices = [];
  Map<String, String>? _selectedVoice;
  final TextEditingController _customPkgController = TextEditingController();
  List<String> _customPackages = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkPermission();
    _loadVoices();
  }

  Future<void> _checkPermission() async {
    bool status = await NotificationListenerService.isPermissionGranted();
    setState(() {
      _hasPermission = status;
    });
  }

  Future<void> _loadVoices() async {
    final voices = await VoiceEngine().getVoices();
    setState(() {
      _voices = voices;
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isPhonePeEnabled = prefs.getBool('phonepe') ?? true;
      isGPayEnabled = prefs.getBool('gpay') ?? true;
      isPaytmEnabled = prefs.getBool('paytm') ?? true;
      _customPackages = prefs.getStringList('custom_packages') ?? [];
      
      String? savedVoiceName = prefs.getString('voice_name');
      String? savedVoiceLocale = prefs.getString('voice_locale');
      if (savedVoiceName != null && savedVoiceLocale != null) {
        _selectedVoice = {"name": savedVoiceName, "locale": savedVoiceLocale};
      }
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
      _checkPermission();
    }
  }

  void _addCustomPackage() {
    if (_customPkgController.text.isNotEmpty) {
      setState(() {
        _customPackages.add(_customPkgController.text.trim());
        _customPkgController.clear();
      });
      _saveCustomPackages();
    }
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
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Custom App Sources (Package Names)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customPkgController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. com.sbi.upi.app',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addCustomPackage,
                  child: const Text('Add'),
                ),
              ],
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
              'Voice Selection',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          if (_voices.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: DropdownButton<Map<String, String>>(
                isExpanded: true,
                value: _voices.any((v) => v['name'] == _selectedVoice?['name']) ? _selectedVoice : null,
                hint: const Text("Select a Voice"),
                items: _voices.map((voice) {
                  return DropdownMenuItem<Map<String, String>>(
                    value: voice,
                    child: Text("${voice['locale']} - ${voice['name']}"),
                  );
                }).toList(),
                onChanged: (Map<String, String>? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedVoice = newValue;
                    });
                    VoiceEngine().setVoice(newValue);
                  }
                },
              ),
            ),
          const Divider(),
          ListTile(
            title: const Text('Test Voice Announcement'),
            trailing: const Icon(Icons.volume_up),
            onTap: _testVoice,
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
        ],
      ),
    );
  }
}
