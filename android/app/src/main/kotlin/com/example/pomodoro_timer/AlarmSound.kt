package com.example.pomodoro_timer

import android.content.Context
import android.media.MediaPlayer
import android.media.AudioAttributes
import android.media.Ringtone
import android.media.RingtoneManager
import android.net.Uri

/**
 * アラーム音の再生を管理するユーティリティ。
 * - アセットの mp3 等（flutter_assets 配下）を MediaPlayer で再生
 * - 指定がなければ Ringtone（端末デフォルトのアラーム or 通知音）で再生
 */
object AlarmSound {
    @Volatile
    private var ringtone: Ringtone? = null
    @Volatile
    private var mediaPlayer: MediaPlayer? = null

    @Synchronized
    /**
     * 音を再生する。`assetPath` が指定されていればアセット音源、
     * なければ `uri` または端末のデフォルト音を使用。既存の再生は停止してから開始。
     */
    fun play(context: Context, assetPath: String? = null, uri: Uri? = null, loop: Boolean = true) {
        stop()
        try {
            if (!assetPath.isNullOrBlank()) {
                val afd = context.assets.openFd("flutter_assets/$assetPath")
                val mp = MediaPlayer()
                mp.setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
                mediaPlayer = mp
                mp.setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
                mp.isLooping = loop
                mp.setOnPreparedListener { it.start() }
                mp.prepareAsync()
                return
            }
        } catch (_: Throwable) {
            // fall back to ringtone
        }

        val soundUri = uri
            ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
        val rt = RingtoneManager.getRingtone(context.applicationContext, soundUri)
        ringtone = rt
        try {
            rt?.play()
        } catch (_: Throwable) {
            // Ignore playback errors
        }
    }

    @Synchronized
    /**
     * 再生を停止し、リソースを開放する。
     */
    fun stop() {
        try {
            mediaPlayer?.let {
                it.stop()
                it.reset()
                it.release()
            }
        } catch (_: Throwable) {
        } finally {
            mediaPlayer = null
        }

        try {
            ringtone?.stop()
        } catch (_: Throwable) {
        } finally {
            ringtone = null
        }
    }
}
