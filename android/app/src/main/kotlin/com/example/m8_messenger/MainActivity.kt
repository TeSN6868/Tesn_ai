package com.example.m8_messenger

import android.content.Context
import android.media.AudioManager
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

                "startCallAudio" -> {
                    val video = call.argument<Boolean>("video") ?: false

                    val audioManager =
                        getSystemService(Context.AUDIO_SERVICE) as AudioManager

                    audioManager.mode =
                        AudioManager.MODE_IN_COMMUNICATION

                    audioManager.isSpeakerphoneOn = video

                    result.success(true)
                }

                "stopCallAudio" -> {
                    val audioManager =
                        getSystemService(Context.AUDIO_SERVICE) as AudioManager

                    audioManager.isSpeakerphoneOn = false
                    audioManager.mode = AudioManager.MODE_NORMAL

                    result.success(true)
                }

                else -> result.notImplemented()
            }
        }
    }
}
