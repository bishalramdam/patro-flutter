package com.bishal.patro_flutter

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Rect
import android.graphics.RectF
import android.graphics.drawable.BitmapDrawable
import android.os.Build
import android.util.DisplayMetrics
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.graphics.drawable.IconCompat
import es.antonborri.home_widget.HomeWidgetPlugin

object PatroNotificationHelper {
    const val CHANNEL_ID = "patro_lockscreen_banner_channel_v5"
    const val ALERT_CHANNEL_ID = "patro_alert_channel"
    const val NOTIFICATION_ID = 1001
    const val ALERT_NOTIFICATION_ID = 1002

    private fun resolveScalePercent(widgetData: android.content.SharedPreferences): Int {
        if (widgetData.contains("status_bar_icon_scale")) {
            return widgetData.getInt("status_bar_icon_scale", 90).coerceIn(40, 100)
        }
        return when (widgetData.getString("status_bar_icon_size", "Large")) {
            "Small" -> 55
            "Medium" -> 75
            else -> 90
        }
    }

    private fun createScaledStatusIcon(
        context: Context,
        baseResId: Int,
        scalePercent: Int
    ): Pair<IconCompat?, Bitmap?> {
        val drawable = try {
            context.resources.getDrawableForDensity(
                baseResId,
                DisplayMetrics.DENSITY_XXXHIGH,
                null
            )
        } catch (_: Exception) {
            null
        }

        val src = (drawable as? BitmapDrawable)?.bitmap
            ?: BitmapFactory.decodeResource(
                context.resources,
                baseResId,
                BitmapFactory.Options().apply { inScaled = false }
            )
            ?: return Pair(null, null)

        val w = src.width
        val h = src.height
        if (w <= 0 || h <= 0) return Pair(null, src)

        val pixels = IntArray(w * h)
        src.getPixels(pixels, 0, w, 0, 0, w, h)

        var minX = w
        var minY = h
        var maxX = -1
        var maxY = -1
        for (y in 0 until h) {
            val rowOffset = y * w
            for (x in 0 until w) {
                val alpha = (pixels[rowOffset + x] ushr 24) and 0xFF
                if (alpha > 8) {
                    if (x < minX) minX = x
                    if (x > maxX) maxX = x
                    if (y < minY) minY = y
                    if (y > maxY) maxY = y
                }
            }
        }

        if (maxX < minX || maxY < minY) {
            val iconCompat = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                IconCompat.createWithBitmap(src)
            } else {
                null
            }
            return Pair(iconCompat, src)
        }

        val inkW = maxX - minX + 1
        val inkH = maxY - minY + 1

        val canvasSize = 96
        val clampedScale = scalePercent.coerceIn(40, 100) / 100f
        val targetMaxDim = canvasSize * clampedScale
        val aspect = inkW.toFloat() / inkH.toFloat()

        val dstW: Float
        val dstH: Float
        if (inkH >= inkW) {
            dstH = targetMaxDim
            dstW = targetMaxDim * aspect
        } else {
            dstW = targetMaxDim
            dstH = targetMaxDim / aspect
        }

        val left = (canvasSize - dstW) / 2f
        val top = (canvasSize - dstH) / 2f

        val outBitmap = Bitmap.createBitmap(canvasSize, canvasSize, Bitmap.Config.ARGB_8888).apply {
            density = DisplayMetrics.DENSITY_XXXHIGH
        }
        val canvas = Canvas(outBitmap)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG or Paint.FILTER_BITMAP_FLAG)
        val srcRect = Rect(minX, minY, maxX + 1, maxY + 1)
        val dstRect = RectF(left, top, left + dstW, top + dstH)
        canvas.drawBitmap(src, srcRect, dstRect, paint)

        val iconCompat = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            IconCompat.createWithBitmap(outBitmap)
        } else {
            null
        }
        return Pair(iconCompat, outBitmap)
    }

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
            val scalePercent = resolveScalePercent(widgetData)

            // Compute current date using native Kotlin Bikram engine
            val today = BikramCalendarHelper.getTodayData(isEnglish, isLatinNumerals)
            val bsDay = today.bsDayInt

            val baseIconName = if (statusBarNumeral == "Devanagari") "day_dev_$bsDay" else "day_$bsDay"
            var baseIconResId = context.resources.getIdentifier(baseIconName, "drawable", context.packageName)
            if (baseIconResId == 0) {
                baseIconResId = R.mipmap.ic_launcher
            }

            val (scaledIconCompat, scaledBitmap) = createScaledStatusIcon(context, baseIconResId, scalePercent)
            val observance = widgetData.getString("observance", "") ?: ""

            val title = "${today.bsDay} ${today.bsMonth} ${today.bsYear}, ${today.weekday}"
            val body = "${today.gregorianDay} ${today.gregorianMonth} ${today.gregorianYear} AD"

            val expandedText = StringBuilder().apply {
                append(body)
                if (observance.isNotEmpty()) {
                    append("\n• $observance")
                }
            }.toString()

            val contentText = if (observance.isNotEmpty()) "$body • $observance" else body

            val notificationManager =
                context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager ?: return

            // Clean up legacy channels if present
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                try {
                    notificationManager.deleteNotificationChannel("patro_lockscreen_banner_channel")
                    notificationManager.deleteNotificationChannel("patro_lockscreen_banner_channel_v2")
                    notificationManager.deleteNotificationChannel("patro_lockscreen_banner_channel_v3")
                    notificationManager.deleteNotificationChannel("patro_lockscreen_banner_channel_v4")
                } catch (_: Exception) {
                }

                val channelName = "दैनिक क्यालेन्डर ब्यानर (Lock Screen Banner)"
                val channelDesc = "लक-स्क्रिन र नोटिफिकेसन बारमा आजको मिति देखाउँछ"
                val channel = NotificationChannel(
                    CHANNEL_ID,
                    channelName,
                    NotificationManager.IMPORTANCE_LOW
                ).apply {
                    description = channelDesc
                    setSound(null, null)
                    enableVibration(false)
                    lockscreenVisibility = Notification.VISIBILITY_PUBLIC
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

            val largeIconBitmap = scaledBitmap ?: try {
                BitmapFactory.decodeResource(context.resources, baseIconResId)
            } catch (_: Exception) {
                null
            }

            val publicVersionBuilder = NotificationCompat.Builder(context, CHANNEL_ID)
            if (scaledIconCompat != null) {
                publicVersionBuilder.setSmallIcon(scaledIconCompat)
            } else {
                publicVersionBuilder.setSmallIcon(baseIconResId)
            }
            if (largeIconBitmap != null) {
                publicVersionBuilder.setLargeIcon(largeIconBitmap)
            }
            val publicVersionNotification = publicVersionBuilder
                .setContentTitle(title)
                .setContentText(contentText)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .setSilent(true)
                .setSound(null)
                .setVibrate(null)
                .setContentIntent(pendingIntent)
                .setShowWhen(false)
                .build()

            val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            if (scaledIconCompat != null) {
                builder.setSmallIcon(scaledIconCompat)
            } else {
                builder.setSmallIcon(baseIconResId)
            }
            if (largeIconBitmap != null) {
                builder.setLargeIcon(largeIconBitmap)
            }
            builder
                .setContentTitle(title)
                .setContentText(contentText)
                .setStyle(
                    NotificationCompat.BigTextStyle()
                        .setBigContentTitle(title)
                        .bigText(expandedText)
                )
                .setPublicVersion(publicVersionNotification)
                .setOngoing(true)
                .setAutoCancel(false)
                .setOnlyAlertOnce(true)
                .setSilent(true)
                .setSound(null)
                .setVibrate(null)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .setContentIntent(pendingIntent)
                .setShowWhen(false)

            NotificationManagerCompat.from(context).notify(NOTIFICATION_ID, builder.build())
        } catch (_: SecurityException) {
            // POST_NOTIFICATIONS permission not granted
        } catch (_: Exception) {
            // General defensive catch
        }
    }

    fun showNormalAlert(context: Context) {
        try {
            val widgetData = HomeWidgetPlugin.getData(context)
            val isEnglish = widgetData.getBoolean("is_english", false)
            val isLatinNumerals = widgetData.getBoolean("is_latin_numerals", false)
            val statusBarNumeral = widgetData.getString(
                "status_bar_numeral",
                if (isLatinNumerals) "Latin" else "Devanagari"
            ) ?: "Latin"
            val scalePercent = resolveScalePercent(widgetData)

            val today = BikramCalendarHelper.getTodayData(isEnglish, isLatinNumerals)
            val bsDay = today.bsDayInt

            val baseIconName = if (statusBarNumeral == "Devanagari") "day_dev_$bsDay" else "day_$bsDay"
            var baseIconResId = context.resources.getIdentifier(baseIconName, "drawable", context.packageName)
            if (baseIconResId == 0) {
                baseIconResId = R.mipmap.ic_launcher
            }

            val (scaledIconCompat, scaledBitmap) = createScaledStatusIcon(context, baseIconResId, scalePercent)
            val title = if (isEnglish) {
                "Today: ${today.bsDay} ${today.bsMonth} ${today.bsYear}"
            } else {
                "आज: ${today.bsDay} ${today.bsMonth} ${today.bsYear}"
            }
            val body = "${today.bsYear} (${today.weekday}) · ${today.gregorianDay} ${today.gregorianMonth} ${today.gregorianYear} AD"

            val notificationManager =
                context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager ?: return

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val channel = NotificationChannel(
                    ALERT_CHANNEL_ID,
                    "दैनिक मिति सूचना (Daily Date Alerts)",
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "दैनिक बिहानको मिति सूचना"
                    lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                }
                notificationManager.createNotificationChannel(channel)
            }

            val launchIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                1,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val builder = NotificationCompat.Builder(context, ALERT_CHANNEL_ID)
            if (scaledIconCompat != null) {
                builder.setSmallIcon(scaledIconCompat)
            } else {
                builder.setSmallIcon(baseIconResId)
            }
            if (scaledBitmap != null) {
                builder.setLargeIcon(scaledBitmap)
            }
            builder
                .setContentTitle(title)
                .setContentText(body)
                .setStyle(
                    NotificationCompat.BigTextStyle()
                        .setBigContentTitle(title)
                        .bigText(body)
                )
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setAutoCancel(true)
                .setContentIntent(pendingIntent)

            NotificationManagerCompat.from(context).notify(ALERT_NOTIFICATION_ID, builder.build())
        } catch (_: SecurityException) {
        } catch (_: Exception) {
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
