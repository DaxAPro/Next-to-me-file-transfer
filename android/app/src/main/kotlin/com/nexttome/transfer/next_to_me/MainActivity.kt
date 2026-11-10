package com.nexttome.transfer.next_to_me

import android.content.Context
import android.content.Intent
import android.bluetooth.BluetoothAdapter
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "nexttome/wifi_direct"
    private var hotspotReservation: WifiManager.LocalOnlyHotspotReservation? = null
    private var hotspotGeneration = 0

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startLocalOnlyHotspot" -> startLocalOnlyHotspot(result)
                    "getAndroidSdkVersion" -> result.success(Build.VERSION.SDK_INT)
                    "getHardwareStatus" -> getHardwareStatus(result)
                    "openWifiSettings" -> openSystemSettings(Settings.ACTION_WIFI_SETTINGS, result)
                    "openBluetoothSettings" -> openSystemSettings(Settings.ACTION_BLUETOOTH_SETTINGS, result)
                    "stopLocalOnlyHotspot" -> {
                        stopLocalOnlyHotspot()
                        result.success(null)
                    }
                    "regenerateLocalOnlyHotspot" -> {
                        stopLocalOnlyHotspot()
                        Handler(Looper.getMainLooper()).postDelayed({
                            startLocalOnlyHotspot(result)
                        }, 500)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    @Suppress("DEPRECATION")
    private fun getHardwareStatus(result: MethodChannel.Result) {
        try {
            val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
            val bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
            result.success(
                mapOf(
                    "wifiEnabled" to wifiManager.isWifiEnabled,
                    "bluetoothEnabled" to (bluetoothAdapter?.isEnabled == true),
                    "sdkVersion" to Build.VERSION.SDK_INT,
                ),
            )
        } catch (error: SecurityException) {
            result.error("HARDWARE_PERMISSION_DENIED", error.message, null)
        }
    }

    private fun openSystemSettings(action: String, result: MethodChannel.Result) {
        try {
            startActivity(Intent(action).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
            result.success(null)
        } catch (error: Exception) {
            result.error("SETTINGS_UNAVAILABLE", error.message, null)
        }
    }

    private fun startLocalOnlyHotspot(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            result.error("UNSUPPORTED", "Local-only hotspot requires Android 8.0 or later.", null)
            return
        }

        hotspotReservation?.let {
            result.success(readCredentials(it))
            return
        }

        val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
        val generation = ++hotspotGeneration
        try {
            wifiManager.startLocalOnlyHotspot(
                object : WifiManager.LocalOnlyHotspotCallback() {
                    override fun onStarted(reservation: WifiManager.LocalOnlyHotspotReservation) {
                        if (generation != hotspotGeneration) {
                            reservation.close()
                            return
                        }
                        hotspotReservation = reservation
                        try {
                            result.success(readCredentials(reservation))
                        } catch (error: Exception) {
                            reservation.close()
                            hotspotReservation = null
                            result.error("CREDENTIALS_UNAVAILABLE", error.message, null)
                        }
                    }

                    override fun onStopped() {
                        if (generation == hotspotGeneration) {
                            hotspotReservation = null
                        }
                    }

                    override fun onFailed(reason: Int) {
                        result.error(
                            "HOTSPOT_START_FAILED",
                            "Android could not start a local hotspot (reason $reason).",
                            reason,
                        )
                    }
                },
                Handler(Looper.getMainLooper()),
            )
        } catch (error: SecurityException) {
            result.error("HOTSPOT_PERMISSION_DENIED", error.message, null)
        } catch (error: IllegalStateException) {
            result.error("HOTSPOT_UNAVAILABLE", error.message, null)
        }
    }

    @Suppress("DEPRECATION")
    private fun readCredentials(
        reservation: WifiManager.LocalOnlyHotspotReservation,
    ): Map<String, String> {
        val (ssid, password) = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val config = reservation.softApConfiguration
                ?: throw IllegalStateException("Android did not provide hotspot configuration.")
            config.ssid to config.passphrase
        } else {
            @Suppress("DEPRECATION")
            val config = reservation.wifiConfiguration
                ?: throw IllegalStateException("Android did not provide hotspot configuration.")
            config.SSID?.trim('"') to config.preSharedKey
        }
        val resolvedSsid = ssid?.trim('"')
            ?: throw IllegalStateException("Android did not provide a hotspot name.")
        val resolvedPassword = password
            ?: throw IllegalStateException("Android did not provide a hotspot password.")
        return mapOf("ssid" to resolvedSsid, "password" to resolvedPassword)
    }

    private fun stopLocalOnlyHotspot() {
        hotspotGeneration++
        hotspotReservation?.close()
        hotspotReservation = null
    }

    override fun onDestroy() {
        stopLocalOnlyHotspot()
        super.onDestroy()
    }
}
