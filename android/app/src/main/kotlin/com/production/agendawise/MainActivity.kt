package com.production.agendawise

import android.text.format.DateFormat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Lets Dart read the live 12/24-hour setting, which Flutter only
        // receives at start-up.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "agendawise/device_settings")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "is24HourFormat" -> result.success(DateFormat.is24HourFormat(this))
                    else -> result.notImplemented()
                }
            }
    }
}
