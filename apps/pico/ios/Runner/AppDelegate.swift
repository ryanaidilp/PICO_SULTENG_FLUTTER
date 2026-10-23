import Flutter
import UIKit

// archipelago:launch_tracker:import:start
#if canImport(app_launch_tracker_impl)
import app_launch_tracker_impl
#endif
// archipelago:launch_tracker:import:end

/// Root application delegate.
///
/// The app uses the UIScene lifecycle (`UIApplicationSceneManifest` in
/// `Info.plist`, `SceneDelegate`), which iOS 27 requires: an app without it
/// stops at launch. The Flutter engine is created with the first scene, after
/// `didFinishLaunching`, so plugins and the deeplink channels are registered
/// in `didInitializeImplicitFlutterEngine`.
@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Launch trace: app init starts here. Compiles to nothing without the
    // launch tracker plugin.
    // archipelago:launch_tracker:app_init:start
    #if canImport(app_launch_tracker_impl)
    LaunchTimeTrackerPlugin.markAppInitStart()
    #endif
    // archipelago:launch_tracker:app_init:end

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "DeepLinkBridge") {
      DeepLinkBridge.register(with: registrar)
    }
  }
}

/// Exposes deeplinks to Flutter via two platform channels:
///
/// | Channel | Type | Purpose |
/// |---|---|---|
/// | `archipelago/deeplink/initial` | FlutterMethodChannel | Returns the cold-start URI once, then nil |
/// | `archipelago/deeplink/events`  | FlutterEventChannel  | Streams subsequent deeplinks |
///
/// Receives both custom URL schemes (`myapp://path`) and Universal Links
/// (`https://domain/path`) as a scene delegate: at scene connection (cold
/// start), through `openURLContexts` and through `continue userActivity`.
/// Every callback returns `false`, so other plugins still see the link.
final class DeepLinkBridge: NSObject, FlutterPlugin, FlutterSceneLifeCycleDelegate,
  FlutterStreamHandler
{
  private var pendingLink: String?
  private var eventSink: FlutterEventSink?

  static func register(with registrar: FlutterPluginRegistrar) {
    let bridge = DeepLinkBridge()
    FlutterMethodChannel(name: "archipelago/deeplink/initial", binaryMessenger: registrar.messenger())
      .setMethodCallHandler { call, result in
        guard call.method == "getInitialLink" else {
          result(FlutterMethodNotImplemented)
          return
        }
        result(bridge.pendingLink)
        bridge.pendingLink = nil
      }
    FlutterEventChannel(name: "archipelago/deeplink/events", binaryMessenger: registrar.messenger())
      .setStreamHandler(bridge)
    registrar.addSceneDelegate(bridge)
  }

  // MARK: - Scene callbacks

  func scene(
    _ scene: UIScene, willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions?
  ) -> Bool {
    guard let options = connectionOptions else { return false }
    if let url = options.urlContexts.first?.url {
      receive(url)
    } else if let url = Self.webURL(options.userActivities.first) {
      receive(url)
    }
    return false
  }

  // Custom URL scheme (myapp://…)
  func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) -> Bool {
    if let url = URLContexts.first?.url { receive(url) }
    return false
  }

  // Universal Links (https://…)
  func scene(_ scene: UIScene, continue userActivity: NSUserActivity) -> Bool {
    if let url = Self.webURL(userActivity) { receive(url) }
    return false
  }

  // MARK: - FlutterStreamHandler

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
    eventSink = events
    // Flush a buffered cold-start link when the EventChannel listener
    // attaches before getInitialLink() is called.
    if let link = pendingLink {
      events(link)
      pendingLink = nil
    }
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }

  // MARK: - Helpers

  private static func webURL(_ activity: NSUserActivity?) -> URL? {
    guard let activity, activity.activityType == NSUserActivityTypeBrowsingWeb else { return nil }
    return activity.webpageURL
  }

  /// Sends the URL to the EventChannel sink, or buffers it when the Dart
  /// listener is not yet attached.
  private func receive(_ url: URL) {
    if let sink = eventSink {
      sink(url.absoluteString)
    } else {
      pendingLink = url.absoluteString
    }
  }
}
