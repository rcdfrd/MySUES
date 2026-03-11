package com.hsxmark.mysues

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
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
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                val title = widgetData.getString("title", "今日无课")
                val week = widgetData.getString("week", "")
                
                setTextViewText(R.id.widget_title, title)
                setTextViewText(R.id.widget_week, week)

                var hasVisibleCourse = false

                for (i in 1..6) {
                    val courseName = widgetData.getString("course_${i}_name", "")
                    val courseTime = widgetData.getString("course_${i}_time", "")
                    val courseEnd = widgetData.getString("course_${i}_endtime", "")
                    val courseLoc = widgetData.getString("course_${i}_loc", "")
                    
                    val rowId = context.resources.getIdentifier("course_row_$i", "id", context.packageName)
                    val nameId = context.resources.getIdentifier("course_${i}_name", "id", context.packageName)
                    val timeId = context.resources.getIdentifier("course_${i}_time", "id", context.packageName)
                    val endtimeId = context.resources.getIdentifier("course_${i}_endtime", "id", context.packageName)
                    val locId = context.resources.getIdentifier("course_${i}_loc", "id", context.packageName)

                    if (courseName.isNullOrEmpty()) {
                        setViewVisibility(rowId, View.GONE)
                    } else {
                        hasVisibleCourse = true
                        setViewVisibility(rowId, View.VISIBLE)
                        setTextViewText(nameId, courseName)
                        setTextViewText(timeId, courseTime)
                        setTextViewText(endtimeId, courseEnd)
                        setTextViewText(locId, courseLoc)
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
}
