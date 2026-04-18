package com.mydev.notif_widget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import android.content.ComponentName
import android.view.View
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
        views.setTextViewText(R.id.widget_title, "Notifications (${array.length()})")

        val notifIds = listOf(R.id.notif1, R.id.notif2, R.id.notif3, R.id.notif4, R.id.notif5)
        val divIds = listOf(R.id.div1, R.id.div2, R.id.div3, R.id.div4)

        notifIds.forEachIndexed { i, resId ->
            if (i < array.length()) {
                val n = array.getJSONObject(i)
                val time = sdf.format(Date(n.getLong("time")))
                val app = n.getString("app")
                val title = n.getString("title")
                val text = n.getString("text")
                val display = "$app  $time\n$title\n$text"
                views.setTextViewText(resId, display)
                views.setViewVisibility(resId, View.VISIBLE)
                if (i < divIds.size && i < array.length() - 1) {
                    views.setViewVisibility(divIds[i], View.VISIBLE)
                }
            } else {
                views.setViewVisibility(resId, View.GONE)
                if (i < divIds.size) views.setViewVisibility(divIds[i], View.GONE)
            }
        }
        mgr.updateAppWidget(id, views)
    }
}
