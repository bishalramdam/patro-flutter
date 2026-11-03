package com.bishal.patro_flutter

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import com.bishal.patro_flutter.R
import es.antonborri.home_widget.HomeWidgetPlugin

class PatroAppWidget : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val widgetData = HomeWidgetPlugin.getData(context)
            val views = RemoteViews(context.packageName, R.layout.patro_widget_layout).apply {
                val day = widgetData.getString("bs_day", "१७")
                val month = widgetData.getString("bs_month", "कात्तिक")
                val year = widgetData.getString("bs_year", "२०८३")
                val weekday = widgetData.getString("weekday", "मङ्गलबार")
                val gregDay = widgetData.getString("gregorian_day", "3")
                val gregMonth = widgetData.getString("gregorian_month", "Nov")

                setTextViewText(R.id.widget_day, day)
                setTextViewText(R.id.widget_month_year, "$month $year")
                setTextViewText(R.id.widget_weekday, weekday)
                setTextViewText(R.id.widget_gregorian, "$gregDay $gregMonth 2026 AD")
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
