import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  // Default settings values
  bool flagVibration = true;
  int focusTime = 25;
  int shortBreakTime = 5;
  int longBreakTime = 15;
  int longBreakInterval = 4;
  String soundFilePath = 'assets/silence.mp3';

  Future<void> loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    flagVibration = prefs.getBool('flagVibration') ?? flagVibration;
    focusTime = prefs.getInt('focusTime') ?? focusTime;
    shortBreakTime = prefs.getInt('shortBreakTime') ?? shortBreakTime;
    longBreakTime = prefs.getInt('longBreakTime') ?? longBreakTime;
    longBreakInterval = prefs.getInt('longBreakInterval') ?? longBreakInterval;
    soundFilePath = prefs.getString('soundFilePath') ?? soundFilePath;
  }

  Future<void> saveSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setBool('flagVibration', flagVibration);
    await prefs.setInt('focusTime', focusTime);
    await prefs.setInt('shortBreakTime', shortBreakTime);
    await prefs.setInt('longBreakTime', longBreakTime);
    await prefs.setInt('longBreakInterval', longBreakInterval);
    await prefs.setString('soundFilePath', soundFilePath);
  }
}

// Create a single instance of AppSettings that can be shared across the app
AppSettings appSettings = AppSettings();
