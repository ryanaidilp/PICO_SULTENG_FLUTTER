import Darwin
import Flutter
import QuartzCore
import UIKit
import os.signpost

/// Reports native launch milestones to Dart.
///
/// Channel: com.archipelago/launch_time_tracker
/// - `getStartupTimestamps`: the milestones known so far.
/// - `reportInteractive`: emits an `interactive` os_signpost (Instruments,
///   Points of Interest), then returns the same map.
///
/// Map: `monoNowMs` and `epochNowMs` (one paired sample, for Dart to place
/// the monotonic times), `launchType` (`cold` or `prewarm`), and `markers`
/// (marker name to monotonic ms, `CACurrentMediaTime` base).
public class LaunchTimeTrackerPlugin: NSObject, FlutterPlugin {

  static func now() -> Double { CACurrentMediaTime() * 1000 }

  private static var appInitStart: Double?
  private static var appInitEnd: Double?
  private static var appInitEndObserver: NSObjectProtocol?

  /// Call first in `application(_:didFinishLaunchingWithOptions:)`. The end
  /// is recorded when that method returns.
  @objc public static func markAppInitStart() {
    if appInitStart == nil { appInitStart = now() }
    observeAppInitEnd()
  }

  // Registered from markAppInitStart: under the UIScene lifecycle the plugin
  // is registered after didFinishLaunching, too late to see this.
  private static func observeAppInitEnd() {
    guard appInitEndObserver == nil else { return }
    // queue nil: runs synchronously when UIKit posts it, right after
    // didFinishLaunching returns.
    appInitEndObserver = NotificationCenter.default.addObserver(
      forName: UIApplication.didFinishLaunchingNotification, object: nil, queue: nil
    ) { _ in
      if LaunchTimeTrackerPlugin.appInitEnd == nil {
        LaunchTimeTrackerPlugin.appInitEnd = LaunchTimeTrackerPlugin.now()
      }
    }
  }

  /// Plugin registration runs when the root FlutterViewController creates the
  /// engine: inside `didFinishLaunching` with the app-delegate lifecycle, at
  /// scene connection with the UIScene lifecycle.
  private let engineAttach = LaunchTimeTrackerPlugin.now()
  private var splashExitEnd: Double?
  private var hadSplash = false
  private weak var controller: FlutterViewController?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "com.archipelago/launch_time_tracker",
      binaryMessenger: registrar.messenger()
    )
    let instance = LaunchTimeTrackerPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    observeAppInitEnd()

    if let controller = registrar.viewController as? FlutterViewController {
      instance.observe(controller)
    } else {
      // UIScene lifecycle: the engine registers plugins while its view
      // controller is still being built, so the registrar has none yet. It
      // does one turn of the run loop later, long before the first frame.
      DispatchQueue.main.async { [weak instance] in
        if let controller = registrar.viewController as? FlutterViewController {
          instance?.observe(controller)
        }
      }
    }
  }

  private func observe(_ controller: FlutterViewController) {
    self.controller = controller
    hadSplash = controller.splashScreenView != nil
    controller.addObserver(self, forKeyPath: "displayingFlutterUI", options: [.new], context: nil)
  }

  // FlutterViewController sets displayingFlutterUI after its splash view has
  // faded out, so this is the splash exit end.
  override public func observeValue(
    forKeyPath keyPath: String?,
    of object: Any?,
    change: [NSKeyValueChangeKey: Any]?,
    context: UnsafeMutableRawPointer?
  ) {
    guard keyPath == "displayingFlutterUI", (change?[.newKey] as? Bool) == true else { return }
    if splashExitEnd == nil { splashExitEnd = Self.now() }
    controller?.removeObserver(self, forKeyPath: "displayingFlutterUI")
    controller = nil
    flushInteractive()
  }

  // `interactive` usually lands with the first frame, before the splash has
  // faded (0.2 s), so its reply waits for the splash exit (at most 1.5 s;
  // Dart gives up after 2 s) to carry the native first frame.
  private var pendingInteractive: [FlutterResult] = []

  private func flushInteractive() {
    let waiting = pendingInteractive
    pendingInteractive = []
    waiting.forEach { $0(snapshot()) }
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getStartupTimestamps":
      result(snapshot())
    case "reportInteractive":
      let log = OSLog(
        subsystem: Bundle.main.bundleIdentifier ?? "app_launch_tracker",
        category: .pointsOfInterest
      )
      os_signpost(.event, log: log, name: "interactive")
      if splashExitEnd == nil, controller != nil {
        pendingInteractive.append(result)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
          self?.flushInteractive()
        }
      } else {
        result(snapshot())
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func snapshot() -> [String: Any] {
    let monoNow = Self.now()
    let epochNow = Date().timeIntervalSince1970 * 1000
    var markers: [String: Double] = ["engine_attach": engineAttach]

    // A prewarmed process ran up to UIApplicationMain long before the user
    // launched the app, so its process start says nothing about this launch.
    let prewarm = ProcessInfo.processInfo.environment["ActivePrewarm"] == "1"
    if !prewarm, let startEpochMs = processStartEpochMs() {
      let processStart = monoNow - (epochNow - startEpochMs)
      markers["process_start"] = processStart
      // The system shows the launch storyboard as the process starts.
      markers["native_splash_shown"] = processStart
    }
    if let start = Self.appInitStart { markers["native_app_init_start"] = start }
    if let end = Self.appInitEnd { markers["native_app_init_end"] = end }
    if let end = splashExitEnd {
      // ponytail: the first frame starts Flutter's fixed 0.2 s splash
      // fade (SplashScreenManager.defaultAnimationDuration) and only its end
      // is observable; read the engine's first-frame callback if that
      // constant changes.
      let firstFrame = hadSplash ? end - 200 : end
      markers["native_first_frame"] = firstFrame
      markers["native_splash_exit_start"] = firstFrame
      markers["native_splash_exit_end"] = end
    }
    return [
      "monoNowMs": monoNow,
      "epochNowMs": epochNow,
      "launchType": prewarm ? "prewarm" : "cold",
      "markers": markers,
    ]
  }

  /// Process creation time in ms since the Unix epoch (kinfo_proc
  /// p_starttime, a wall-clock value), or nil when sysctl fails.
  private func processStartEpochMs() -> Double? {
    var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, Int32(getpid())]
    var info = kinfo_proc()
    var size = MemoryLayout<kinfo_proc>.stride
    guard sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0) == 0 else { return nil }
    let start = info.kp_proc.p_starttime
    return Double(start.tv_sec) * 1000 + Double(start.tv_usec) / 1000
  }
}
