package com.production.agendawise

import android.app.NotificationManager
import android.media.AudioManager
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.text.format.DateFormat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        // Lets Dart read the live 12/24-hour setting, which Flutter only
        // receives at start-up.
        MethodChannel(messenger, "agendawise/device_settings")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "is24HourFormat" -> result.success(DateFormat.is24HourFormat(this))
                    else -> result.notImplemented()
                }
            }

        // How a ringing alarm is brought on screen.
        MethodChannel(messenger, "agendawise/alarm_display")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "canUseFullScreenIntent" -> result.success(canUseFullScreenIntent())
                    "openFullScreenIntentSettings" -> {
                        openFullScreenIntentSettings()
                        result.success(null)
                    }
                    "scheduleLaunch" -> {
                        val id = call.argument<Int>("id")
                        val at = call.argument<Number>("at")?.toLong()
                        if (id == null || at == null) {
                            result.error("bad_args", "id and at are required", null)
                        } else {
                            AlarmLauncher.schedule(applicationContext, id, at)
                            result.success(null)
                        }
                    }
                    "getAlarmVolume" -> {
                        val audio = getSystemService(AudioManager::class.java)
                        if (audio == null) {
                            result.success(null)
                        } else {
                            result.success(
                                mapOf(
                                    "level" to audio.getStreamVolume(AudioManager.STREAM_ALARM),
                                    "max" to audio.getStreamMaxVolume(AudioManager.STREAM_ALARM),
                                ),
                            )
                        }
                    }
                    "setAlarmVolume" -> {
                        val level = call.argument<Int>("level")
                        val audio = getSystemService(AudioManager::class.java)
                        if (level != null && audio != null) {
                            try {
                                audio.setStreamVolume(AudioManager.STREAM_ALARM, level, 0)
                            } catch (error: SecurityException) {
                                // Do Not Disturb can refuse volume changes.
                            }
                        }
                        result.success(null)
                    }
                    "cancelLaunch" -> {
                        val id = call.argument<Int>("id")
                        if (id != null) AlarmLauncher.cancel(applicationContext, id)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun canUseFullScreenIntent(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) return true
        val manager = getSystemService(NotificationManager::class.java) ?: return true
        return manager.canUseFullScreenIntent()
    }

    private fun openFullScreenIntentSettings() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) return
        val intent = Intent(
            Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT,
            Uri.parse("package:$packageName"),
        )
        try {
            startActivity(intent)
        } catch (error: Exception) {
            startActivity(
                Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$packageName")),
            )
        }
    }
}
