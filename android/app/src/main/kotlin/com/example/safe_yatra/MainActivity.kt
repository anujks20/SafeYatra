package com.example.safe_yatra

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import android.os.Bundle

import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        createSOSNotificationChannel()
    }

    private fun createSOSNotificationChannel() {

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {

            // New channel ID because Android does not allow
            // changing the sound of an existing channel.
            val channelId = "sos_alerts_v3"

            val channelName = "SOS Emergency Siren"

            val channelDescription =
                "Critical TravelBuddy SOS alerts with custom siren and vibration"

            val importance = NotificationManager.IMPORTANCE_HIGH

            val channel = NotificationChannel(
                channelId,
                channelName,
                importance
            )

            channel.description = channelDescription

            // Enable vibration
            channel.enableVibration(true)

            channel.vibrationPattern = longArrayOf(
                0,
                500,
                250,
                500,
                250,
                800
            )

            // Custom SOS siren
            val soundUri = Uri.parse(
                "android.resource://$packageName/${R.raw.sos_siren}"
            )

            val audioAttributes = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                .setContentType(
                    AudioAttributes.CONTENT_TYPE_SONIFICATION
                )
                .build()

            channel.setSound(
                soundUri,
                audioAttributes
            )

            val notificationManager =
                getSystemService(
                    Context.NOTIFICATION_SERVICE
                ) as NotificationManager

            notificationManager.createNotificationChannel(
                channel
            )
        }
    }
}