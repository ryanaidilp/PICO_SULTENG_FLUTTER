package com.banuacoders.pico.app

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * Host activity for the Flutter engine.
 *
 * Extends [FlutterFragmentActivity] (rather than [FlutterActivity]) so that
 * downstream features that require fragment support (e.g. in-app purchase
 * overlays, biometric fragments) work without additional setup.
 *
 * ## Deeplink channels
 *
 * Two platform channels expose deeplink data to Dart:
 *
 * | Channel | Type | Purpose |
 * |---|---|---|
 * | `archipelago/deeplink/initial` | MethodChannel | Returns the cold-start URI once, then null |
 * | `archipelago/deeplink/events` | EventChannel | Streams subsequent deeplinks via [onNewIntent] |
 *
 * ### Cold-start race
 * If Dart calls `getInitialLink` *before* the EventChannel listener is
 * attached, the link is returned via the MethodChannel. If the EventChannel
 * listener attaches first (unlikely but possible on fast devices),
 * [startDeepLink] is forwarded to the sink in [onListen] to avoid losing it.
 */
class MainActivity : FlutterFragmentActivity() {

    private val initialChannelName = "archipelago/deeplink/initial"
    private val eventsChannelName = "archipelago/deeplink/events"

    /** Buffers the cold-start deeplink until either the MethodChannel or
     *  the EventChannel sink consumes it. */
    private var startDeepLink: String? = null

    /** Non-null while Dart is listening on the EventChannel. */
    private var eventSink: EventChannel.EventSink? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        captureStartDeeplink(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val data = intent.data?.toString() ?: return
        val sink = eventSink
        if (sink != null) {
            sink.success(data)
        } else {
            // EventChannel not yet subscribed — buffer for the next attach.
            startDeepLink = data
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            initialChannelName,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialLink" -> {
                    val link = startDeepLink
                    startDeepLink = null
                    result.success(link)
                }
                else -> result.notImplemented()
            }
        }

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            eventsChannelName,
        ).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    eventSink = events
                    // Flush buffered cold-start link when the EventChannel
                    // listener attaches before getInitialLink() is called.
                    val buffered = startDeepLink
                    if (buffered != null) {
                        events.success(buffered)
                        startDeepLink = null
                    }
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            },
        )
    }

    private fun captureStartDeeplink(intent: Intent) {
        startDeepLink = intent.data?.toString()
    }
}
