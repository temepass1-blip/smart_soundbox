import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:notification_listener_service/notification_listener_service.dart';

void main() {
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
      home: const SettingsScreen(),
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
  bool isSmsEnabled = true;

  final FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _initTTS();
    _requestPermissions();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isPhonePeEnabled = prefs.getBool('phonepe') ?? true;
      isGPayEnabled = prefs.getBool('gpay') ?? true;
      isPaytmEnabled = prefs.getBool('paytm') ?? true;
      isSmsEnabled = prefs.getBool('sms') ?? true;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  void _initTTS() async {
    await flutterTts.setLanguage("hi-IN");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
  }

  void _requestPermissions() async {
    bool status = await NotificationListenerService.isPermissionGranted();
    if (!status) {
      await NotificationListenerService.requestPermission();
    }
  }

  void _testVoice() async {
    await flutterTts.speak("100 rupaye prapt hue");
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
          SwitchListTile(
            title: const Text('Bank SMS'),
            value: isSmsEnabled,
            onChanged: (val) {
              setState(() => isSmsEnabled = val);
              _saveSetting('sms', val);
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
