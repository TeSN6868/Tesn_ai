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

                "isUsbDebuggingEnabled" -> {
                    val enabled = Settings.Global.getInt(
                        contentResolver,
                        Settings.Global.ADB_ENABLED,
                        0
                    ) == 1

                    result.success(enabled)
                }

                "isDeveloperOptionsEnabled" -> {
                    val enabled = Settings.Global.getInt(
                        contentResolver,
                        Settings.Global.DEVELOPMENT_SETTINGS_ENABLED,
                        0
                    ) == 1

                    result.success(enabled)
                }

                "getVerifiedBootState" -> {
                    result.success(
                        getSystemProperty("ro.boot.verifiedbootstate")
                    )
                }

                "getBootloaderLockState" -> {
                    result.success(
                        getSystemProperty("ro.boot.flash.locked")
                    )
                }

                "isDebuggableBuild" -> {
                    result.success(
                        (applicationInfo.flags and
                            android.content.pm.ApplicationInfo.FLAG_DEBUGGABLE) != 0
                    )
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun getSystemProperty(name: String): String {
        return try {
            val systemProperties =
                Class.forName("android.os.SystemProperties")

            val getMethod =
                systemProperties.getMethod(
                    "get",
                    String::class.java,
                    String::class.java
                )

            getMethod.invoke(
                null,
                name,
                "unknown"
            ) as String
        } catch (_: Exception) {
            "unknown"
        }
    }
}
