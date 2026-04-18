package com.mydev.notif_widget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import android.content.ComponentName
import android.view.View
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
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

    companion object {
        fun drawableToBitmap(drawable: Drawable): Bitmap {
            if (drawable is BitmapDrawable && drawable.bitmap != null) return drawable.bitmap
            val w = if (drawable.intrinsicWidth > 0) drawable.intrinsicWidth else 96
            val h = if (drawable.intrinsicHeight > 0) drawable.intrinsicHeight else 96
            val bmp = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bmp)
            drawable.setBounds(0, 0, w, h)
            drawable.draw(canvas)
            return bmp
        }
    }

    private fun updateWidget(context: Context, mgr: AppWidgetManager, id: Int) {
        val prefs = context.getSharedPreferences("notif_prefs", Context.MODE_PRIVATE)
        val alpha = prefs.getInt("bg_alpha", 204)
        val json = prefs.getString("notifs", "[]")
        val array = JSONArray(json)
        val sdf = SimpleDateFormat("HH:mm", Locale.getDefault())
        val views = RemoteViews(context.packageName, R.layout.notif_widget_layout)
        val pm = context.packageManager

        val bgColor = (alpha shl 24) or 0x1E1E2E
        views.setInt(R.id.widget_root, "setBackgroundColor", bgColor)
        views.setTextViewText(R.id.widget_title, "Notifications (${array.length()})")

        val rowIds = listOf(R.id.row1, R.id.row2, R.id.row3, R.id.row4, R.id.row5)
        val notifIds = listOf(R.id.notif1, R.id.notif2, R.id.notif3, R.id.notif4, R.id.notif5)
        val iconIds = listOf(R.id.icon1, R.id.icon2, R.id.icon3, R.id.icon4, R.id.icon5)
        val divIds = listOf(R.id.div1, R.id.div2, R.id.div3, R.id.div4)

        for (i in 0..4) {
            if (i < array.length()) {
                val n = array.getJSONObject(i)
                val time = sdf.format(Date(n.getLong("time")))
                val app = n.getString("app")
                val title = n.getString("title")
                val text = n.getString("text")
                val pkg = n.optString("pkg", "")

                views.setViewVisibility(rowIds[i], View.VISIBLE)
                views.setTextViewText(notifIds[i], "$app  $time\n$title\n$text")

                try {
                    val icon = pm.getApplicationIcon(pkg)
                    val bmp = drawableToBitmap(icon)
                    views.setImageViewBitmap(iconIds[i], bmp)
                } catch (e: Exception) {
                    views.setImageViewResource(iconIds[i], android.R.drawable.sym_def_app_icon)
                }

                if (i < divIds.size && i < array.length() - 1) {
                    views.setViewVisibility(divIds[i], View.VISIBLE)
                }
            } else {
                views.setViewVisibility(rowIds[i], View.GONE)
                if (i < divIds.size) views.setViewVisibility(divIds[i], View.GONE)
            }
        }
        mgr.updateAppWidget(id, views)
    }
}
