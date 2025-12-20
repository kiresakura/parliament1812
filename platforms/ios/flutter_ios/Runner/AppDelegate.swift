import Flutter
import UIKit
import CoreNFC

@main
@objc class AppDelegate: FlutterAppDelegate {

    // MARK: - Properties

    private var deepLinkChannel: FlutterMethodChannel?

    // MARK: - Application Lifecycle

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Register Flutter plugins
        GeneratedPluginRegistrant.register(with: self)

        // Setup method channel for deep links
        setupDeepLinkChannel()

        // Handle launch URL if present
        if let url = launchOptions?[.url] as? URL {
            handleDeepLink(url)
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // MARK: - Deep Link Handling

    /// Setup Flutter method channel for deep link communication
    private func setupDeepLinkChannel() {
        guard let controller = window?.rootViewController as? FlutterViewController else {
            return
        }

        deepLinkChannel = FlutterMethodChannel(
            name: "com.parliament1812.app/deeplink",
            binaryMessenger: controller.binaryMessenger
        )
    }

    /// Handle incoming deep links
    override func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        handleDeepLink(url)
        return true
    }

    /// Process deep link URL
    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "parliament1812" else { return }

        // Extract parameters from URL
        let urlString = url.absoluteString

        // Send to Flutter via method channel
        deepLinkChannel?.invokeMethod("onDeepLink", arguments: urlString)

        #if DEBUG
        print("📱 Deep Link received: \(urlString)")
        #endif
    }

    // MARK: - Universal Links

    override func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
    ) -> Bool {
        // Handle Universal Links
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
           let url = userActivity.webpageURL {
            handleUniversalLink(url)
            return true
        }
        return false
    }

    /// Process Universal Link URL
    private func handleUniversalLink(_ url: URL) {
        let urlString = url.absoluteString
        deepLinkChannel?.invokeMethod("onUniversalLink", arguments: urlString)

        #if DEBUG
        print("🔗 Universal Link received: \(urlString)")
        #endif
    }

    // MARK: - NFC Support

    /// Check if device supports NFC
    static var isNFCSupported: Bool {
        if #available(iOS 13.0, *) {
            return NFCNDEFReaderSession.readingAvailable
        }
        return false
    }

    // MARK: - Push Notifications

    override func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()

        #if DEBUG
        print("📲 Push notification token: \(tokenString)")
        #endif

        super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }

    override func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        #if DEBUG
        print("❌ Failed to register for push notifications: \(error.localizedDescription)")
        #endif

        super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
    }

    // MARK: - Background Fetch

    override func application(
        _ application: UIApplication,
        performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        // Handle background fetch
        completionHandler(.noData)
    }

    // MARK: - State Restoration

    override func application(
        _ application: UIApplication,
        shouldSaveSecureApplicationState coder: NSCoder
    ) -> Bool {
        return true
    }

    override func application(
        _ application: UIApplication,
        shouldRestoreSecureApplicationState coder: NSCoder
    ) -> Bool {
        return true
    }
}
