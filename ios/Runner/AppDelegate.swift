import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "JoyShare") else { return }
    let channel = FlutterMethodChannel(name: "joy/share", binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "text" else { result(FlutterMethodNotImplemented); return }
      guard let args = call.arguments as? [String: Any],
            let text = args["text"] as? String,
            let root = self?.window?.rootViewController else {
        result(FlutterError(code: "share_failed", message: "Share text unavailable", details: nil)); return
      }
      var presenter = root
      while let presented = presenter.presentedViewController { presenter = presented }
      let sheet = UIActivityViewController(activityItems: [text], applicationActivities: nil)
      sheet.popoverPresentationController?.sourceView = presenter.view
      sheet.popoverPresentationController?.sourceRect = CGRect(x: presenter.view.bounds.midX, y: presenter.view.bounds.midY, width: 1, height: 1)
      presenter.present(sheet, animated: true)
      result(nil)
    }
  }
}
