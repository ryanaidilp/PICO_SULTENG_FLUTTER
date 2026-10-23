package com.archipelago.app_launch_tracker

import android.app.Activity
import android.app.ActivityManager
import android.app.Application
import android.content.ContentProvider
import android.content.ContentValues
import android.database.Cursor
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.Process
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.embedding.engine.renderer.FlutterRenderer
import io.flutter.embedding.engine.renderer.FlutterUiDisplayListener
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * Process-wide launch state. Every time is monotonic ms on the
 * `SystemClock.uptimeMillis` base: `System.nanoTime` and `uptimeMillis` both
 * read CLOCK_MONOTONIC on Android, as do the `Process.getStart*` APIs.
 */
internal object LaunchMilestones {
    fun now(): Double = System.nanoTime() / 1_000_000.0

    @Volatile var appInitStart: Double? = null
    @Volatile var appInitEnd: Double? = null

    /** False when the process started for a broadcast, service or push. */
    @Volatile var startedForActivity = true
    @Volatile var restoredState = false
    @Volatile var flutterActivitySeen = false
    @Volatile var engines = 0
}

/**
 * Merged into the app manifest, so the host needs no code. Providers run
 * after `Application.attachBaseContext` and before `Application.onCreate`;
 * the high `initOrder` puts this one first.
 */
class LaunchTimeTrackerInitProvider : ContentProvider() {
    override fun onCreate(): Boolean {
        LaunchMilestones.appInitStart = LaunchMilestones.now()
        val info = ActivityManager.RunningAppProcessInfo()
        ActivityManager.getMyMemoryState(info)
        LaunchMilestones.startedForActivity =
            info.importance == ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND
        // Runs as soon as bindApplication returns, which is after
        // Application.onCreate and before the first activity is created.
        Handler(Looper.getMainLooper()).postAtFrontOfQueue {
            LaunchMilestones.appInitEnd = LaunchMilestones.now()
        }
        (context?.applicationContext as? Application)
            ?.registerActivityLifecycleCallbacks(FirstFlutterActivityCallbacks)
        return true
    }

    override fun query(
        uri: Uri,
        projection: Array<out String>?,
        selection: String?,
        selectionArgs: Array<out String>?,
        sortOrder: String?,
    ): Cursor? = null

    override fun getType(uri: Uri): String? = null

    override fun insert(uri: Uri, values: ContentValues?): Uri? = null

    override fun delete(uri: Uri, selection: String?, selectionArgs: Array<out String>?) = 0

    override fun update(
        uri: Uri,
        values: ContentValues?,
        selection: String?,
        selectionArgs: Array<out String>?,
    ) = 0
}

/** Notes whether the first Flutter activity restored saved state (warm). */
private object FirstFlutterActivityCallbacks : Application.ActivityLifecycleCallbacks {
    override fun onActivityCreated(activity: Activity, savedInstanceState: Bundle?) {
        if (LaunchMilestones.flutterActivitySeen) return
        if (activity !is FlutterActivity && activity !is FlutterFragmentActivity) return
        LaunchMilestones.flutterActivitySeen = true
        LaunchMilestones.restoredState = savedInstanceState != null
    }

    override fun onActivityStarted(activity: Activity) {}
    override fun onActivityResumed(activity: Activity) {}
    override fun onActivityPaused(activity: Activity) {}
    override fun onActivityStopped(activity: Activity) {}
    override fun onActivitySaveInstanceState(activity: Activity, outState: Bundle) {}
    override fun onActivityDestroyed(activity: Activity) {}
}

/**
 * Reports native launch milestones to Dart.
 *
 * Channel: com.archipelago/launch_time_tracker
 * - `getStartupTimestamps`: the milestones known so far.
 * - `reportInteractive`: calls `Activity.reportFullyDrawn()` (TTFD), then
 *   returns the same map.
 *
 * Map: `monoNowMs` and `epochNowMs` (one paired sample, for Dart to place
 * the monotonic times), `launchType` (`cold` or `warm`), and `markers`
 * (marker name to monotonic ms).
 */
class LaunchTimeTrackerPlugin : FlutterPlugin, ActivityAware, MethodCallHandler {

    private lateinit var channel: MethodChannel
    private var engineAttach = 0.0
    private var firstEngine = false
    private var firstFrame: Double? = null
    private var renderer: FlutterRenderer? = null
    private var activity: Activity? = null

    private val uiListener = object : FlutterUiDisplayListener {
        override fun onFlutterUiDisplayed() {
            if (firstFrame == null) firstFrame = LaunchMilestones.now()
        }

        override fun onFlutterUiNoLongerDisplayed() {}
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        // Runs inside the FlutterEngine constructor (plugin registration).
        engineAttach = LaunchMilestones.now()
        firstEngine = ++LaunchMilestones.engines == 1
        @Suppress("DEPRECATION")
        renderer = binding.flutterEngine.renderer.also {
            it.addIsDisplayingFlutterUiListener(uiListener)
        }
        channel = MethodChannel(binding.binaryMessenger, "com.archipelago/launch_time_tracker")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        renderer?.removeIsDisplayingFlutterUiListener(uiListener)
        renderer = null
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getStartupTimestamps" -> result.success(snapshot())
            "reportInteractive" -> {
                // Same API floor as FlutterActivity's own call (flutter#46172).
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    try {
                        activity?.reportFullyDrawn()
                    } catch (e: SecurityException) {
                        // Some OEM builds require UPDATE_DEVICE_STATS; skip.
                    }
                }
                result.success(snapshot())
            }
            else -> result.notImplemented()
        }
    }

    private fun snapshot(): Map<String, Any> {
        val markers = HashMap<String, Double>()
        // A later engine, or a process started in the background, did not
        // start for this launch: its process milestones belong to another.
        val ownsProcess = firstEngine && LaunchMilestones.startedForActivity
        if (ownsProcess) {
            val processStart = Process.getStartUptimeMillis().toDouble()
            markers["process_start"] = processStart
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                markers["launch_requested"] = Process.getStartRequestedUptimeMillis().toDouble()
            }
            LaunchMilestones.appInitStart?.let { markers["native_app_init_start"] = it }
            LaunchMilestones.appInitEnd?.let { markers["native_app_init_end"] = it }
            // The system adds the splash (starting window) when the launch is
            // requested; the app gets no callback for it.
            markers["native_splash_shown"] = markers["launch_requested"] ?: processStart
        }
        markers["engine_attach"] = engineAttach
        firstFrame?.let {
            markers["native_first_frame"] = it
            // Flutter holds the activity's first draw until its first frame
            // (delayFirstAndroidViewDraw); that draw removes the splash.
            markers["native_splash_exit_start"] = it
        }
        val warm = !ownsProcess || LaunchMilestones.restoredState
        return mapOf(
            "monoNowMs" to LaunchMilestones.now(),
            "epochNowMs" to System.currentTimeMillis().toDouble(),
            "launchType" to if (warm) "warm" else "cold",
            "markers" to markers,
        )
    }
}
