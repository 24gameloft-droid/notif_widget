package com.mydev.notif_widget

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.os.Bundle
import android.content.Intent
import android.content.SharedPreferences
import android.provider.Settings
import android.content.ComponentName
import android.content.pm.PackageManager
import android.content.pm.ApplicationInfo
import org.json.JSONArray
import org.json.JSONObject

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.mydev.notif_widget/prefs"
    private val PREFS = "notif_prefs"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (!isNotificationListenerEnabled()) {
            startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val prefs: SharedPreferences = getSharedPreferences(PREFS, MODE_PRIVATE)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getData" -> {
                    val notifs = prefs.getString("notifs", "[]")
                    val allowed = prefs.getStringSet("allowed_apps", emptySet()) ?: emptySet()
                    val alpha = prefs.getInt("bg_alpha", 204)
                    val firstLaunch = prefs.getBoolean("first_launch", true)
                    val pm = packageManager
                    val appsArray = JSONArray()
                    val appList = mutableListOf<Pair<String, String>>()

                    val intent = Intent(Intent.ACTION_MAIN, null)
                    intent.addCategory(Intent.CATEGORY_LAUNCHER)
                    val resolvedApps = pm.queryIntentActivities(intent, 0)
                    for (ri in resolvedApps) {
                        try {
                            val appInfo = ri.activityInfo.applicationInfo
                            val name = pm.getApplicationLabel(appInfo).toString()
                            appList.add(Pair(name, appInfo.packageName))
                        } catch (e: Exception) {}
                    }

                    appList.sortBy { it.first }
                    for ((name, pkg) in appList) {
                        val obj = JSONObject()
                        obj.put("name", name)
                        obj.put("package", pkg)
                        appsArray.put(obj)
                    }

                    val data = JSONObject()
                    data.put("notifs", JSONArray(notifs))
                    data.put("apps", appsArray)
                    data.put("allowed", JSONArray(allowed.toList()))
                    data.put("alpha", alpha)
                    data.put("firstLaunch", firstLaunch)
                    result.success(data.toString())
                }
                "saveSettings" -> {
                    val allowed = call.argument<List<String>>("allowed") ?: emptyList()
                    val alpha = call.argument<Int>("alpha") ?: 204
                    val firstLaunch = call.argument<Boolean>("firstLaunch") ?: false
                    prefs.edit()
                        .putStringSet("allowed_apps", allowed.toSet())
                        .putInt("bg_alpha", alpha)
                        .putBoolean("first_launch", firstLaunch)
                        .apply()
                    sendBroadcast(Intent(this, NotifWidgetProvider::class.java).apply {
                        action = "UPDATE_WIDGET"
                    })
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun isNotificationListenerEnabled(): Boolean {
        val flat = Settings.Secure.getString(contentResolver, "enabled_notification_listeners")
        return flat?.contains(packageName) == true
    }
}
