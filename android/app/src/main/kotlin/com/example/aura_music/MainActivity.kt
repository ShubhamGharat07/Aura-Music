package com.example.aura_music

import android.content.Intent
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.StatFs
import android.provider.Settings
import android.view.WindowManager
import androidx.core.content.FileProvider
import com.ryanheise.audioservice.AudioServiceFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import kotlin.concurrent.thread

// AudioServiceFragmentActivity extends FlutterFragmentActivity: local_auth
// (biometric prompt) keeps working while audio_service owns the media session.
// The `aura/screen` channel toggles FLAG_SECURE for screenshot blocking.
// The `aura/installer` channel handles in-app OTA APK installation.
class MainActivity : AudioServiceFragmentActivity() {
    private val screenChannelName = "aura/screen"
    private val installerChannelName = "aura/installer"

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

        // Screen protection channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, screenChannelName)
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

        // OTA APK installer channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, installerChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "canInstallUnknownSources" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            result.success(packageManager.canRequestPackageInstalls())
                        } else {
                            result.success(true)
                        }
                    }
                    "openInstallPermissionSettings" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            val intent = Intent(
                                Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                                Uri.parse("package:$packageName")
                            )
                            startActivity(intent)
                            result.success(true)
                        } else {
                            result.success(true)
                        }
                    }
                    "availableUpdateBytes" -> {
                        result.success(StatFs(filesDir.path).availableBytes)
                    }
                    "installApk" -> {
                        val path = call.argument<String>("filePath")
                        val version = call.argument<Number>("versionCode")?.toLong()
                        if (path == null || version == null) {
                            result.error("INVALID_UPDATE", "Missing update file or build number", null)
                        } else {
                            installUpdate(path, version, result)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    @Suppress("DEPRECATION")
    private fun installUpdate(path: String, version: Long, result: MethodChannel.Result) {
        thread(name = "aura-ota-validation") {
            try {
                val directory = File(filesDir, "ota").canonicalFile
                val file = File(path).canonicalFile
                require(file.parentFile == directory && file.isFile && file.extension == "apk") {
                    "Update file is missing or outside private update storage."
                }
                val signingFlag = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                    PackageManager.GET_SIGNING_CERTIFICATES
                } else {
                    PackageManager.GET_SIGNATURES
                }
                val apk = packageManager.getPackageArchiveInfo(file.path, signingFlag)
                    ?: error("The downloaded file is not a valid APK.")
                val installed = packageManager.getPackageInfo(packageName, signingFlag)
                require(apk.packageName == packageName) { "APK belongs to a different application." }
                require(buildCode(apk) == version && version > buildCode(installed)) {
                    "APK build number does not match the offered update."
                }
                val installedSigners = signers(installed)
                require(installedSigners.isNotEmpty() && signers(apk) == installedSigners) {
                    "APK signing key does not match the installed app."
                }
                val uri = FileProvider.getUriForFile(this, "${packageName}.fileprovider", file)
                runOnUiThread {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
                            !packageManager.canRequestPackageInstalls()) {
                            result.error("INSTALL_PERMISSION", "Allow Aura Music to install updates first.", null)
                            return@runOnUiThread
                        }
                        val intent = Intent(Intent.ACTION_VIEW).apply {
                            setDataAndType(uri, "application/vnd.android.package-archive")
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (error: Exception) {
                        result.error("INSTALL_ERROR", "Could not open the Android installer.", null)
                    }
                }
            } catch (error: Exception) {
                runOnUiThread {
                    result.error("INVALID_UPDATE", error.message, null)
                }
            }
        }
    }

    @Suppress("DEPRECATION")
    private fun buildCode(info: PackageInfo): Long =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) info.longVersionCode
        else info.versionCode.toLong()

    @Suppress("DEPRECATION")
    private fun signers(info: PackageInfo) =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            info.signingInfo?.apkContentsSigners?.toSet().orEmpty()
        } else {
            info.signatures?.toSet().orEmpty()
        }
}
