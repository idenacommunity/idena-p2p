import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let SCREEN_SECURITY_CHANNEL = "com.idena.idena_p2p/screen_security"
  private var blurView: UIVisualEffectView?
  private var securityEnabled = false

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: SCREEN_SECURITY_CHANNEL,
                                       binaryMessenger: controller.binaryMessenger)

    channel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      switch call.method {
      case "enableScreenSecurity":
        self.enableScreenSecurity()
        result(nil)
      case "disableScreenSecurity":
        self.disableScreenSecurity()
        result(nil)
      case "isSupported":
        result(true)
      default:
        result(FlutterMethodNotImplemented)
      }
    })

    // Setup app lifecycle observers for blur effect
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(willResignActive),
      name: UIApplication.willResignActiveNotification,
      object: nil
    )

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(didBecomeActive),
      name: UIApplication.didBecomeActiveNotification,
      object: nil
    )

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func enableScreenSecurity() {
    securityEnabled = true
  }

  private func disableScreenSecurity() {
    securityEnabled = false
    removeBlur()
  }

  @objc private func willResignActive() {
    // Only add blur if security is enabled
    if securityEnabled {
      addBlur()
    }
  }

  @objc private func didBecomeActive() {
    removeBlur()
  }

  private func addBlur() {
    guard let window = window, blurView == nil else { return }

    let blurEffect = UIBlurEffect(style: .light)
    let blurView = UIVisualEffectView(effect: blurEffect)
    blurView.frame = window.bounds
    blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

    window.addSubview(blurView)
    self.blurView = blurView
  }

  private func removeBlur() {
    blurView?.removeFromSuperview()
    blurView = nil
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }
}
