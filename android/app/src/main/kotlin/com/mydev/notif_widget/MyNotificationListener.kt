package com.mydev.notif_widget

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.content.Intent
import android.content.SharedPreferences
import org.json.JSONArray
import org.json.JSONObject

class MyNotificationListener : NotificationListenerService() {
    companion object {
        const val PREFS = "notif_prefs"
        const val KEY = "notifs"
        const val MAX = 10
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        if (sbn.isOngoing) return
        
        val extras = sbn.notification.extras
        val title = extras.getString("android.title") ?: ""
        val text = extras.getCharSequence("android.text")?.toString() ?: ""
        if (title.isEmpty() && text.isEmpty()) return

        val prefs: SharedPreferences = getSharedPreferences(PREFS, MODE_PRIVATE)
        val allowedApps = prefs.getStringSet("allowed_apps", emptySet()) ?: emptySet()
        if (allowedApps.isNotEmpty() && !allowedApps.contains(sbn.packageName)) return

        // منع التكرار - تحقق من آخر إشعار
        val existing = prefs.getString(KEY, "[]")
        val array = JSONArray(existing)
        if (array.length() > 0) {
            val last = array.getJSONObject(0)
            if (last.getString("title") == title && 
                last.getString("text") == text &&
                last.getString("pkg") == sbn.packageName) return
        }

        val appName = try {
            packageManager.getApplicationLabel(
                packageManager.getApplicationInfo(sbn.packageName, 0)
            ).toString()
        } catch (e: Exception) { sbn.packageName }

        val newItem = JSONObject().apply {
            put("app", appName)
            put("pkg", sbn.packageName)
            put("title", title)
            put("text", text)
            put("time", System.currentTimeMillis())
        }

        val newArray = JSONArray()
        newArray.put(newItem)
        for (i in 0 until minOf(array.length(), MAX - 1)) newArray.put(array.get(i))
        prefs.edit().putString(KEY, newArray.toString()).apply()

        sendBroadcast(Intent(this, NotifWidgetProvider::class.java).apply {
            action = "UPDATE_WIDGET"
        })
    }
}
