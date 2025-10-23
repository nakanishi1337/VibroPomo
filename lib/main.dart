import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:flutter/services.dart';
import 'page/timer_page.dart';
import 'viewmodel/settings.dart';
import 'services/native_alarm.dart';

// アプリのエントリーポイント
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Flutterの初期化
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]); // 縦画面固定
  await appSettings.loadSettings(); // 設定のロード
  runApp(const MainApp()); // アプリ起動
}

// アプリ全体の状態を管理するウィジェット
class MainApp extends StatefulWidget {
  const MainApp({Key? key}) : super(key: key);

  @override
  State<MainApp> createState() => _MainAppState();
}

// アプリ全体の状態を管理するウィジェットの状態クラス
class _MainAppState extends State<MainApp> {
  @override
  void initState() {
    super.initState();

    // Androidで通知権限をアプリ起動時にリクエスト
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!Platform.isAndroid) return;
      final enabled = await NativeAlarm.areNotificationsEnabled();
      if (!enabled) {
        await NativeAlarm.requestPostNotifications();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // アプリ全体のテーマ設定
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.orange,
        ).copyWith(
          primary: Colors.orange,
          secondary: Colors.orangeAccent,
        ),
      ),
      home: const PomodoroScreen(), // メイン画面
    );
  }
}
