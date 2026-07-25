import Flutter
import GoogleMaps
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Google Maps API key for iOS.
    // Replace YOUR_GOOGLE_MAPS_API_KEY_HERE with your actual key.
    // Restrict this key in Google Cloud Console to:
    // Application restrictions → iOS apps → com.boda24.customerApp
    GMSServices.provideAPIKey("AIzaSyBuM_jWsVdsVGkdiyzeZS3es3Qb2PCj9ck")

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
