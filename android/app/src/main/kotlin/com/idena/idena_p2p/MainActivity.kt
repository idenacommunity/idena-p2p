package com.idena.idena_p2p

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val SCREEN_SECURITY_CHANNEL = "com.idena.idena_p2p/screen_security"
    private var securityEnabled = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SCREEN_SECURITY_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "enableScreenSecurity" -> {
                        enableScreenSecurity()
                        result.success(null)
                    }
                    "disableScreenSecurity" -> {
                        disableScreenSecurity()
                        result.success(null)
                    }
                    "isSupported" -> {
                        result.success(true)
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }
    }

    private fun enableScreenSecurity() {
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )
        securityEnabled = true
    }

    private fun disableScreenSecurity() {
        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
        securityEnabled = false
    }
}
