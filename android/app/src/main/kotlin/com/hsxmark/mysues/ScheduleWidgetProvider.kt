package com.hsxmark.mysues

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class ScheduleWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val launchIntent = context.packageManager
                .getLaunchIntentForPackage(context.packageName)
                ?.apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }

            val options = appWidgetManager.getAppWidgetOptions(widgetId)
            val minHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 110)
            // 4x2 ≈ 110dp → max 4 courses; 4x4 ≈ 250dp → max 8 courses
            val maxCourses = if (minHeight >= 200) 8 else 4

            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                launchIntent?.let { intent ->
                    val pendingIntent = PendingIntent.getActivity(
                        context,
                        widgetId,
                        intent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )
                    setOnClickPendingIntent(R.id.widget_root, pendingIntent)
                }

                val title = widgetData.getString("title", "今日无课")
                val week = widgetData.getString("week", "")
                
                setTextViewText(R.id.widget_title, title)
                setTextViewText(R.id.widget_week, week)

                var hasVisibleCourse = false

                for (i in 1..8) {
                    val courseName = widgetData.getString("course_${i}_name", "")
                    val courseTime = widgetData.getString("course_${i}_time", "")
                    val courseEnd = widgetData.getString("course_${i}_endtime", "")
                    val courseLoc = widgetData.getString("course_${i}_loc", "")
                    val courseColor = widgetData.getString("course_${i}_color", "")
                    
                    val rowId = context.resources.getIdentifier("course_row_$i", "id", context.packageName)
                    val nameId = context.resources.getIdentifier("course_${i}_name", "id", context.packageName)
                    val timeId = context.resources.getIdentifier("course_${i}_time", "id", context.packageName)
                    val endtimeId = context.resources.getIdentifier("course_${i}_endtime", "id", context.packageName)
                    val locId = context.resources.getIdentifier("course_${i}_loc", "id", context.packageName)
                    val barId = context.resources.getIdentifier("course_${i}_bar", "id", context.packageName)

                    if (courseName.isNullOrEmpty() || i > maxCourses) {
                        setViewVisibility(rowId, View.GONE)
                    } else {
                        hasVisibleCourse = true
                        setViewVisibility(rowId, View.VISIBLE)
                        setTextViewText(nameId, courseName)
                        setTextViewText(timeId, courseTime)
                        setTextViewText(endtimeId, courseEnd)
                        setTextViewText(locId, courseLoc)

                        val resolvedColor = parseCourseColor(courseColor) ?: fallbackColor(i)
                        setInt(barId, "setBackgroundColor", resolvedColor)
                    }
                }

                if (hasVisibleCourse) {
                    setViewVisibility(R.id.empty_message, View.GONE)
                } else {
                    setViewVisibility(R.id.empty_message, View.VISIBLE)
                }
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        // Re-render widget when size changes
        val widgetData = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        onUpdate(context, appWidgetManager, intArrayOf(appWidgetId), widgetData)
    }

    private fun parseCourseColor(rawColor: String?): Int? {
        if (rawColor.isNullOrBlank()) return null
        val trimmed = rawColor.trim()
        val normalized = if (trimmed.startsWith("#")) trimmed else "#$trimmed"
        if (normalized.length != 7 && normalized.length != 9) return null

        return try {
            Color.parseColor(normalized)
        } catch (_: IllegalArgumentException) {
            null
        }
    }

    private fun fallbackColor(index: Int): Int {
        return if (index % 2 == 1) {
            Color.parseColor("#2ECC71")
        } else {
            Color.parseColor("#F39C12")
        }
    }
}
