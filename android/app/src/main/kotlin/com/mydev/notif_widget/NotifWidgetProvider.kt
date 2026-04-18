package com.mydev.notif_widget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import android.content.ComponentName
import org.json.JSONArray
import java.text.SimpleDateFormat
import java.util.*

class NotifWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, mgr: AppWidgetManager, ids: IntArray) {
        ids.forEach { updateWidget(context, mgr, it) }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == "UPDATE_WIDGET") {
            val mgr = AppWidgetManager.getInstance(context)
            val ids = mgr.getAppWidgetIds(ComponentName(context, NotifWidgetProvider::class.java))
            ids.forEach { updateWidget(context, mgr, it) }
        }
    }

    private fun updateWidget(context: Context, mgr: AppWidgetManager, id: Int) {
        val prefs = context.getSharedPreferences("notif_prefs", Context.MODE_PRIVATE)
        val alpha = prefs.getInt("bg_alpha", 204)
        val json = prefs.getString("notifs", "[]")
        val array = JSONArray(json)
        val sdf = SimpleDateFormat("HH:mm", Locale.getDefault())
        val views = RemoteViews(context.packageName, R.layout.notif_widget_layout)

        val bgColor = (alpha shl 24) or 0x1E1E2E
        views.setInt(R.id.widget_root, "setBackgroundColor", bgColor)
        views.setTextViewText(R.id.widget_title, "🔔 إشعاراتي (${array.length()})")

        val resIds = listOf(R.id.notif1, R.id.notif2, R.id.notif3, R.id.notif4, R.id.notif5)
        resIds.forEachIndexed { i, resId ->
            if (i < array.length()) {
                val n = array.getJSONObject(i)
                val time = sdf.format(Date(n.getLong("time")))
                val app = n.getString("app")
                val title = n.getString("title")
                val text = n.getString("text")
                views.setTextViewText(resId, "[$time] $app\n$title: $text")
            } else {
                views.setTextViewText(resId, "")
            }
        }
        mgr.updateAppWidget(id, views)
    }
}
