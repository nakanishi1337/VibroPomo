package com.example.pomodoro_timer

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat

/**
 * アラーム鳴動を担当する Foreground Service。
 * - 通知チャンネルの作成とフォアグラウンド化
 * - アセット音源 or 端末デフォルト音の再生
 * - バイブレーションの開始／停止
 */
class AlarmService : Service() {
    companion object {
        const val ACTION_START = "com.example.pomodoro_timer.action.START"
        const val ACTION_STOP = "com.example.pomodoro_timer.action.STOP"
        const val EXTRA_TITLE = "title"
        const val EXTRA_VIBRATE = "vibrate"
        const val EXTRA_SOUND = "sound"
        const val CHANNEL_ID = "pomodoro_alarm_service"
        const val NOTI_ID = 424242

        /**
         * 鳴動開始。BroadcastReceiver から呼ばれる想定。
         */
        fun start(context: Context, title: String, vibrate: Boolean, sound: String) {
            val intent = Intent(context, AlarmService::class.java).apply {
                action = ACTION_START
                putExtra(EXTRA_TITLE, title)
                putExtra(EXTRA_VIBRATE, vibrate)
                putExtra(EXTRA_SOUND, sound)
            }
            ContextCompat.startForegroundService(context, intent)
        }

        /**
         * 鳴動停止。
         */
        fun stop(context: Context) {
            val intent = Intent(context, AlarmService::class.java).apply { action = ACTION_STOP }
            ContextCompat.startForegroundService(context, intent)
        }
    }

    override fun onBind(intent: Intent?) = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                val title = intent.getStringExtra(EXTRA_TITLE) ?: "Pomodoro"
                val vibrate = intent.getBooleanExtra(EXTRA_VIBRATE, false)
                val sound = intent.getStringExtra(EXTRA_SOUND) ?: "default"
                createChannel()
                val notification = buildNotification(title)
                startForeground(NOTI_ID, notification)

                if (!(sound.contains("silence", ignoreCase = true))) {
                    val assetPath = if (sound.startsWith("assets/")) sound else null
                    AlarmSound.play(applicationContext, assetPath = assetPath)
                }
                if (vibrate) {
                    AlarmVibration.start(applicationContext)
                }
            }
            ACTION_STOP -> {
                stopAlarm()
                stopSelf()
            }
            else -> {
                stopSelf()
            }
        }
        return START_NOT_STICKY
    }

    private fun stopAlarm() {
        try { AlarmSound.stop() } catch (_: Throwable) {}
        try { AlarmVibration.stop() } catch (_: Throwable) {}
        try { NotificationManagerCompat.from(applicationContext).cancel(NOTI_ID) } catch (_: Throwable) {}
    }

    private fun createChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Pomodoro Alarm",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Foreground alarm service"
            }
            manager.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(title: String): Notification {
        val tapIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val tapPending = PendingIntent.getActivity(
            this, 0, tapIntent,
            (PendingIntent.FLAG_UPDATE_CURRENT or if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentTitle(title)
            .setContentText("Time's up")
            .setContentIntent(tapPending)
            .setAutoCancel(false)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .build()
    }
}
