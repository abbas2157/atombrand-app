package pk.atomshop.atombrand_app

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// A fragment activity: local_auth shows the fingerprint and face prompt
// (v2 quick unlock, board 2.5) as a fragment.
class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        // "atombrand/secure": while a screen with documents or payment proofs
        // is open (and Block screenshots is on) the window can't be captured
        // or shown in recent apps (lib/v2/core/lock/screen_guard.dart).
        MethodChannel(messenger, "atombrand/secure")
            .setMethodCallHandler { call, result ->
                if (call.method != "set") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                if (call.arguments == true) {
                    window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                } else {
                    window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                }
                result.success(null)
            }

        // "atombrand/settings": Permissions (18.7) and notification settings
        // (15.4) open this app's page in the phone's settings; No internet
        // and Offline limit (3.4, 10.9) open the phone's Wi-Fi settings.
        MethodChannel(messenger, "atombrand/settings")
            .setMethodCallHandler { call, result ->
                if (call.method == "cameraAllowed") {
                    result.success(
                        checkSelfPermission(Manifest.permission.CAMERA) ==
                            PackageManager.PERMISSION_GRANTED,
                    )
                    return@setMethodCallHandler
                }
                val intent = when (call.method) {
                    "openAppSettings" -> Intent(
                        Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                        Uri.fromParts("package", packageName, null),
                    )
                    "openWifiSettings" -> Intent(Settings.ACTION_WIFI_SETTINGS)
                    "openNotificationSettings" ->
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                                .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                        } else {
                            Intent(
                                Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                                Uri.fromParts("package", packageName, null),
                            )
                        }
                    else -> null
                }
                if (intent == null) {
                    result.notImplemented()
                } else {
                    try {
                        startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("unavailable", e.message, null)
                    }
                }
            }
    }
}
