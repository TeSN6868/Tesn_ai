package com.example.m8_messenger

import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "bjo/device"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->

            when (call.method) {
                "getBootCount" -> {
                    val bootCount =
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                            Settings.Global.getInt(
                                contentResolver,
                                Settings.Global.BOOT_COUNT,
                                0
                            )
                        } else {
                            0
                        }

                    result.success(bootCount)
                }

                else -> result.notImplemented()
            }
        }
    }
}
