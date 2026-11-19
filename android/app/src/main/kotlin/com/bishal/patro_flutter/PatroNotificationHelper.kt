package com.bishal.patro_flutter

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import es.antonborri.home_widget.HomeWidgetPlugin

object PatroNotificationHelper {
    const val CHANNEL_ID = "patro_lockscreen_banner_channel_v3"
    const val NOTIFICATION_ID = 1001

    fun updateOngoingNotification(context: Context) {
        try {
            val widgetData = HomeWidgetPlugin.getData(context)
            val showBanner = widgetData.getBoolean("show_lockscreen_banner", true)
            if (!showBanner) {
                cancelNotification(context)
                return
            }

            val isEnglish = widgetData.getBoolean("is_english", false)
            val isLatinNumerals = widgetData.getBoolean("is_latin_numerals", false)
            val statusBarNumeral = widgetData.getString(
                "status_bar_numeral",
                if (isLatinNumerals) "Latin" else "Devanagari"
            ) ?: "Latin"

            // Compute current date using native Kotlin Bikram engine
            val today = BikramCalendarHelper.getTodayData(isEnglish, isLatinNumerals)
            val bsDay = today.bsDayInt

            val iconName = if (statusBarNumeral == "Devanagari") "day_dev_$bsDay" else "day_$bsDay"
            var iconResId = context.resources.getIdentifier(iconName, "drawable", context.packageName)
            if (iconResId == 0) {
                iconResId = R.mipmap.ic_launcher
            }

            val title = "${today.bsDay} ${today.bsMonth} ${today.bsYear}, ${today.weekday}"
            val body = "${today.gregorianDay} ${today.gregorianMonth} ${today.gregorianYear} AD"

            val notificationManager =
                context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager ?: return

            // Clean up legacy channels if present
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                try {
                    notificationManager.deleteNotificationChannel("patro_lockscreen_banner_channel")
                    notificationManager.deleteNotificationChannel("patro_lockscreen_banner_channel_v2")
                } catch (_: Exception) {
                }

                val channelName = "दैनिक क्यालेन्डर ब्यानर (Lock Screen Banner)"
                val channelDesc = "लक-स्क्रिन र नोटिफिकेसन बारमा आजको मिति देखाउँछ"
                val channel = NotificationChannel(
                    CHANNEL_ID,
                    channelName,
                    NotificationManager.IMPORTANCE_DEFAULT
                ).apply {
                    description = channelDesc
                    setSound(null, null)
                    enableVibration(false)
                    lockscreenVisibility = NotificationCompat.VISIBILITY_PUBLIC
                    setShowBadge(false)
                }
                notificationManager.createNotificationChannel(channel)
            }

            // Tap intent to open MainActivity
            val launchIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val largeIconBitmap = try {
                BitmapFactory.decodeResource(context.resources, iconResId)
            } catch (_: Exception) {
                null
            }

            val builder = NotificationCompat.Builder(context, CHANNEL_ID)
                .setSmallIcon(iconResId)
                .apply {
                    if (largeIconBitmap != null) {
                        setLargeIcon(largeIconBitmap)
                    }
                }
                .setContentTitle(title)
                .setContentText(body)
                .setStyle(NotificationCompat.BigTextStyle().bigText(body))
                .setOngoing(true)
                .setAutoCancel(false)
                .setOnlyAlertOnce(true)
                .setSound(null)
                .setVibrate(null)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .setPriority(NotificationCompat.PRIORITY_DEFAULT)
                .setContentIntent(pendingIntent)
                .setShowWhen(false)

            NotificationManagerCompat.from(context).notify(NOTIFICATION_ID, builder.build())
        } catch (_: SecurityException) {
            // POST_NOTIFICATIONS permission not granted
        } catch (_: Exception) {
            // General defensive catch
        }
    }

    fun cancelNotification(context: Context) {
        try {
            val notificationManager =
                context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            notificationManager?.cancel(NOTIFICATION_ID)
        } catch (_: Exception) {
        }
    }
}
