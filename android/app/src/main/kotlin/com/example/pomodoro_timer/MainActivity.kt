package com.example.pomodoro_timer

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Flutter(Dart) 側の MethodChannel 呼び出しを受け取り、
 * アラームのスケジュール／キャンセル、権限ダイアログや設定画面の起動を行うエントリポイント。
 */
class MainActivity : FlutterActivity() {
    private val channelName = "com.example.pomodoro/timer"
    private val reqPostNotifications = 5001
    private var pendingPostNotificationsResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "startPomodoro" -> {
                    val endAt = call.argument<Long>("endAt")
                    val title = call.argument<String>("title") ?: "Pomodoro"
                    val vibrate = call.argument<Boolean>("vibrate") ?: false
                    val sound = call.argument<String>("sound") ?: "default"
                    if (endAt == null) {
                        result.error("ARG_ERROR", "endAt is required", null)
                    } else {
                        AlarmScheduler.schedule(applicationContext, endAt, title, vibrate, sound)
                        result.success(true)
                    }
                }
                "cancelPomodoro" -> {
                    AlarmScheduler.cancel(applicationContext)
                    result.success(true)
                }
                "openExactAlarmSettings" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        try {
                            val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM)
                            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("OPEN_SETTINGS_FAILED", e.message, null)
                        }
                    } else {
                        result.success(false)
                    }
                }
                "openNotificationSettings" -> {
                    try {
                        val intent = Intent()
                        intent.action = Settings.ACTION_APP_NOTIFICATION_SETTINGS
                        intent.putExtra("android.provider.extra.APP_PACKAGE", applicationContext.packageName)
                        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("OPEN_SETTINGS_FAILED", e.message, null)
                    }
                }
                "areNotificationsEnabled" -> {
                    val enabled = NotificationManagerCompat.from(applicationContext).areNotificationsEnabled()
                    result.success(enabled)
                }
                "requestPostNotifications" -> {
                    if (Build.VERSION.SDK_INT >= 33) {
                        val granted = ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
                        if (granted) {
                            result.success(true)
                        } else {
                            // Avoid multiple pending results
                            pendingPostNotificationsResult?.let {
                                it.success(false)
                            }
                            pendingPostNotificationsResult = result
                            ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.POST_NOTIFICATIONS), reqPostNotifications)
                        }
                    } else {
                        // No runtime permission required before 33
                        result.success(true)
                    }
                }
                "stopRingtone" -> {
                    try {
                        stopService(Intent(applicationContext, AlarmService::class.java))
                    } catch (_: Exception) {}
                    AlarmSound.stop()
                    AlarmVibration.stop()
                    // Also dismiss the active alarm notification
                    try {
                        NotificationManagerCompat.from(applicationContext).cancel(AlarmService.NOTI_ID)
                    } catch (_: Exception) {}
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == reqPostNotifications) {
            val res = pendingPostNotificationsResult
            pendingPostNotificationsResult = null
            val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            res?.success(granted)
        }
    }

    override fun onDestroy() {
        // タスク／アプリ終了時に、アラームや再生中のサウンド・通知を後片付け
        try {
            AlarmScheduler.cancel(applicationContext)
            AlarmSound.stop()
            AlarmVibration.stop()
            NotificationManagerCompat.from(applicationContext).cancel(AlarmService.NOTI_ID)
        } catch (_: Exception) {}
        super.onDestroy()
    }
}
