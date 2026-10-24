package com.banuacoders.pico.app

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Bundle

/**
 * Transparent activity that receives push notification tap intents and
 * routes them to MainActivity via deeplink, then finishes immediately.
 *
 * Prevents ANR by avoiding heavy work on MainActivity.onCreate when the
 * app is cold-starting from a notification tap.
 */
class NotificationActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val payloadUri = intent?.data?.toString()
            ?: intent?.getStringExtra("route")
            ?: intent?.getStringExtra("link")

        val mainIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            if (payloadUri != null) {
                // MainActivity's onNewIntent picks this up via the existing
                // deeplink EventChannel (see archipelago/deeplink/events).
                action = Intent.ACTION_VIEW
                data = Uri.parse(payloadUri)
            }
            // Forward all extras for any custom payload the host wants
            intent?.extras?.let { putExtras(it) }
        }

        startActivity(mainIntent)
        finish()
        overridePendingTransition(0, 0) // No animation — feel like instant launch
    }
}
