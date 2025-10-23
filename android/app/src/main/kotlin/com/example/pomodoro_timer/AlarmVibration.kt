package com.example.pomodoro_timer

import android.content.Context
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator

/**
 * バイブレーションの開始／停止を行うユーティリティ。
 */
object AlarmVibration {
    @Volatile
    private var vibrator: Vibrator? = null

    @Synchronized
    /**
     * バイブレーションを開始する。
     * - pattern: 波形（オン／オフのミリ秒配列）
     * - repeat: 繰り返しの有無（true なら 0 からループ）
     */
    fun start(context: Context, pattern: LongArray = longArrayOf(0, 600, 250, 600), repeat: Boolean = true) {
        stop()
        try {
            val v = context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
            vibrator = v
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val effect = VibrationEffect.createWaveform(pattern, if (repeat) 0 else -1)
                v.vibrate(effect)
            } else {
                @Suppress("DEPRECATION")
                v.vibrate(pattern, if (repeat) 0 else -1)
            }
        } catch (_: Throwable) { }
    }

    @Synchronized
    /**
     * バイブレーションを停止する。
     */
    fun stop() {
        try {
            vibrator?.cancel()
        } catch (_: Throwable) { } finally {
            vibrator = null
        }
    }
}
