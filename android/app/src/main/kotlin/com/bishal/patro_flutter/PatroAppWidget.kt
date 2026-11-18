package com.bishal.patro_flutter

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import java.util.Calendar
import java.util.TimeZone

class PatroAppWidget : AppWidgetProvider() {

    companion object {
        const val ACTION_MIDNIGHT_UPDATE = "com.bishal.patro_flutter.ACTION_MIDNIGHT_UPDATE"
        private const val ALARM_REQUEST_CODE = 8801

        fun updateAllWidgets(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val thisWidget = ComponentName(context, PatroAppWidget::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(thisWidget)
            if (appWidgetIds != null && appWidgetIds.isNotEmpty()) {
                updateWidgetViews(context, appWidgetManager, appWidgetIds)
            } else {
                scheduleMidnightAlarm(context)
            }
            PatroNotificationHelper.updateOngoingNotification(context)
        }

        fun updateWidgetViews(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetIds: IntArray
        ) {
            val widgetData = HomeWidgetPlugin.getData(context)
            val isEnglish = widgetData.getBoolean("is_english", false)
            val isLatinNumerals = widgetData.getBoolean("is_latin_numerals", false)

            // Compute current date using native Kotlin Bikram engine
            val today = BikramCalendarHelper.getTodayData(isEnglish, isLatinNumerals)

            // Click intent to open app when tapping the widget
            val launchIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            for (appWidgetId in appWidgetIds) {
                val views = RemoteViews(context.packageName, R.layout.patro_widget_layout).apply {
                    setTextViewText(R.id.widget_day, today.bsDay)
                    setTextViewText(R.id.widget_month_year, "${today.bsMonth} ${today.bsYear}")
                    setTextViewText(R.id.widget_weekday, today.weekday)
                    setTextViewText(
                        R.id.widget_gregorian,
                        "${today.gregorianDay} ${today.gregorianMonth} ${today.gregorianYear} AD"
                    )
                    setOnClickPendingIntent(R.id.widget_root, pendingIntent)
                }
                appWidgetManager.updateAppWidget(appWidgetId, views)
            }

            // Schedule the next midnight update alarm
            scheduleMidnightAlarm(context)
            PatroNotificationHelper.updateOngoingNotification(context)
        }

        fun scheduleMidnightAlarm(context: Context) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return

            // Calculate next midnight in Nepal Time (Asia/Kathmandu)
            val tz = TimeZone.getTimeZone("Asia/Kathmandu")
            val nextMidnight = Calendar.getInstance(tz).apply {
                add(Calendar.DAY_OF_YEAR, 1)
                set(Calendar.HOUR_OF_DAY, 0)
                set(Calendar.MINUTE, 0)
                set(Calendar.SECOND, 2) // 2 seconds past midnight to ensure date change
                set(Calendar.MILLISECOND, 0)
            }

            val intent = Intent(context, PatroAppWidget::class.java).apply {
                action = ACTION_MIDNIGHT_UPDATE
            }
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                ALARM_REQUEST_CODE,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val triggerTime = nextMidnight.timeInMillis

            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    if (alarmManager.canScheduleExactAlarms()) {
                        alarmManager.setExactAndAllowWhileIdle(
                            AlarmManager.RTC_WAKEUP,
                            triggerTime,
                            pendingIntent
                        )
                    } else {
                        alarmManager.setAndAllowWhileIdle(
                            AlarmManager.RTC_WAKEUP,
                            triggerTime,
                            pendingIntent
                        )
                    }
                } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    alarmManager.setExactAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        triggerTime,
                        pendingIntent
                    )
                } else {
                    alarmManager.setExact(
                        AlarmManager.RTC_WAKEUP,
                        triggerTime,
                        pendingIntent
                    )
                }
            } catch (e: SecurityException) {
                // In case exact alarm permission is restricted
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    alarmManager.setAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        triggerTime,
                        pendingIntent
                    )
                }
            }
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        updateWidgetViews(context, appWidgetManager, appWidgetIds)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        when (intent.action) {
            ACTION_MIDNIGHT_UPDATE,
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED,
            Intent.ACTION_DATE_CHANGED -> {
                updateAllWidgets(context)
            }
        }
    }
}
