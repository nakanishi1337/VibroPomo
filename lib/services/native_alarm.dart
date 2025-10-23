import 'dart:io' show Platform;
import 'package:flutter/services.dart';

/// Android ネイティブ側（Kotlin）に対して、
/// アラームのスケジュールや停止、設定画面の起動などを依頼するヘルパー。
/// iOS／デスクトップでは何もしません（ガードして false/true を返す）。
class NativeAlarm {
  // Kotlin 側の MethodChannel 名と合わせること
  static const MethodChannel _channel = MethodChannel('com.example.pomodoro/timer');

  /// 指定のエポックミリ秒 `endAtEpochMs` にアラームを1回鳴らす。
  ///
  /// - `title`: 通知やフォアグラウンド通知に表示するタイトル
  /// - `vibrate`: バイブレーションを有効にするか
  /// - `sound`: サウンド指定。
  ///   - 'default' なら端末のデフォルトアラーム音を利用
  ///   - `assets/...` でアセット（例: 'assets/digital-buzzer.mp3'）を利用
  ///   - 'assets/silence.mp3' のようにサイレントにしたい場合はサイレント音源を指定
  static Future<bool> startAt({
    required int endAtEpochMs,
    String title = 'Pomodoro',
    bool vibrate = false,
    String sound = 'default',
  }) async {
    if (!Platform.isAndroid) return false;
    final res = await _channel.invokeMethod('startPomodoro', {
      'endAt': endAtEpochMs,
      'title': title,
      'vibrate': vibrate,
      'sound': sound,
    });
    return res == true;
  }

  /// 予約済みの（まだ鳴っていない）アラームをキャンセルする。
  static Future<bool> cancel() async {
    if (!Platform.isAndroid) return false;
    final res = await _channel.invokeMethod('cancelPomodoro');
    return res == true;
  }

  /// すでに鳴っているアラーム音／バイブを停止する。
  static Future<void> stopRingtone() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('stopRingtone');
    } catch (_) {
      // 端末や OS バージョン差異で失敗してもアプリが落ちないように握りつぶす
    }
  }

  /// Android 12 (API 31) 以降の「正確なアラーム」権限の設定画面を開く。
  static Future<void> openExactAlarmSettings() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('openExactAlarmSettings');
    } catch (_) {}
  }

  /// アプリの通知設定画面を開く。
  static Future<void> openNotificationSettings() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('openNotificationSettings');
    } catch (_) {}
  }

  /// 通知が有効かどうかを問い合わせる。
  static Future<bool> areNotificationsEnabled() async {
    if (!Platform.isAndroid) return true;
    try {
      final res = await _channel.invokeMethod('areNotificationsEnabled');
      return res == true;
    } catch (_) {
      return false;
    }
  }

  /// Android 13 (API 33) 以降の POST_NOTIFICATIONS 権限をリクエストする。
  /// それ以前では常に true を返す。
  static Future<bool> requestPostNotifications() async {
    if (!Platform.isAndroid) return true;
    try {
      final res = await _channel.invokeMethod('requestPostNotifications');
      return res == true;
    } catch (_) {
      return false;
    }
  }
}
