package com.example.pomodoro_timer

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * AlarmManager により発火されるブロードキャストを受け取り、
 * 実際の鳴動（音／バイブ）と通知を担う Foreground Service を起動する。
 * 通知の生成は AlarmService 側で行うため、ここでは起動のみを担当。
 */
class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val title = intent.getStringExtra("title") ?: "Pomodoro"
        val vibrate = intent.getBooleanExtra("vibrate", false)
        val sound = intent.getStringExtra("sound") ?: "default"

        // バックグラウンドでも鳴らし続けるために Foreground Service を開始
        AlarmService.start(context, title, vibrate, sound)
    }
}
