package com.example.aura_music

import android.os.Bundle
import android.view.WindowManager
import com.ryanheise.audioservice.AudioServiceFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// AudioServiceFragmentActivity extends FlutterFragmentActivity: local_auth
// (biometric prompt) keeps working while audio_service owns the media session.
// The `aura/screen` channel toggles FLAG_SECURE for screenshot blocking.
class MainActivity : AudioServiceFragmentActivity() {
    private val channelName = "aura/screen"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.attributes = window.attributes.apply {
            // The OEM seamless animation briefly scales the window, which
            // looks like the UI shrinking on one side. Cut straight over.
            rotationAnimation = WindowManager.LayoutParams.ROTATION_ANIMATION_JUMPCUT
            // Home scrolling should follow the panel's 120 Hz mode.
            preferredRefreshRate = 120f
        }
    }


    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setSecure" -> {
                        val enabled = call.arguments as? Boolean ?: true
                        if (enabled) {
                            window.setFlags(
                                WindowManager.LayoutParams.FLAG_SECURE,
                                WindowManager.LayoutParams.FLAG_SECURE,
                            )
                        } else {
                            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
