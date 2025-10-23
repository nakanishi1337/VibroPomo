import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../viewmodel/settings.dart';

// 設定画面のウィジェット
class SettingPage extends StatefulWidget {
  const SettingPage({Key? key}) : super(key: key);

  @override
  SettingPageState createState() => SettingPageState();
}

// 設定画面の状態クラス
class SettingPageState extends State<SettingPage> {
  late bool flagVibration;
  TextEditingController focusTimeController = TextEditingController();
  TextEditingController shortBreakTimeController = TextEditingController();
  TextEditingController longBreakTimeController = TextEditingController();
  TextEditingController longBreakIntervalController = TextEditingController();
  late String selectedSound;

  final List<String> soundOptions = [
    'assets/silence.mp3',
    'assets/digital-buzzer.mp3',
  ];

  @override
  void initState() {
    super.initState();
    focusTimeController.text = appSettings.focusTime.toString();
    shortBreakTimeController.text = appSettings.shortBreakTime.toString();
    longBreakTimeController.text = appSettings.longBreakTime.toString();
    longBreakIntervalController.text = appSettings.longBreakInterval.toString();
    flagVibration = appSettings.flagVibration;
    selectedSound = appSettings.soundFilePath;
  }

  void _saveSettings() {
    setState(() {
      appSettings.focusTime = int.parse(focusTimeController.text);
      appSettings.shortBreakTime = int.parse(shortBreakTimeController.text);
      appSettings.longBreakTime = int.parse(longBreakTimeController.text);
      final parsedInterval = int.tryParse(longBreakIntervalController.text);
      appSettings.longBreakInterval = (parsedInterval == null || parsedInterval < 1)
          ? 1
          : parsedInterval;
      appSettings.flagVibration = flagVibration;
      appSettings.soundFilePath = selectedSound;

      appSettings.saveSettings();

      FocusScope.of(context).unfocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Focus Time [mins]'),
            TextField(
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              controller: focusTimeController,
              onEditingComplete: _saveSettings,
            ),
            const SizedBox(height: 16.0),
            const Text('Short Break Time [mins]'),
            TextField(
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              controller: shortBreakTimeController,
              onEditingComplete: _saveSettings,
            ),
            const SizedBox(height: 16.0),
            const Text('Long Break Time [mins]'),
            TextField(
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              controller: longBreakTimeController,
              onEditingComplete: _saveSettings,
            ),
            const SizedBox(height: 16.0),
            const Text('Long Break Interval [sessions]'),
            TextField(
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              controller: longBreakIntervalController,
              onEditingComplete: _saveSettings,
            ),
            const SizedBox(height: 16.0),
            const Text('Use Vibration'),
            Switch(
              value: flagVibration,
              onChanged: (newValue) {
                setState(() {
                  flagVibration = newValue;
                  _saveSettings();
                });
              },
            ),
            const SizedBox(height: 16.0),
            const Text('Select Alarm Sound'),
            DropdownButton<String>(
              value: selectedSound,
              onChanged: (String? newValue) {
                setState(() {
                  selectedSound = newValue!;
                  _saveSettings();
                });
              },
              items: soundOptions.map<DropdownMenuItem<String>>((String sound) {
                return DropdownMenuItem<String>(
                  value: sound,
                  child: Text(sound.split('/').last),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
