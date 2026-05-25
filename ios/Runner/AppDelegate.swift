import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let channelName = "teleprompter/export_native_ffmpeg"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as? FlutterViewController
    if let messenger = controller?.binaryMessenger {
      let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
      channel.setMethodCallHandler { call, result in
        switch call.method {
        case "render":
          guard let args = call.arguments as? [String: Any],
                let renderPlan = args["renderPlan"] as? [String: Any],
                let commandArgs = renderPlan["ffmpegCommand"] as? String,
                !commandArgs.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            result(["success": false, "renderMode": "native_ffmpeg_no_command"])
            return
          }

          let task = Process()
          task.executableURL = URL(fileURLWithPath: "/bin/sh")
          task.arguments = ["-c", "ffmpeg \(commandArgs)"]
          do {
            try task.run()
            task.waitUntilExit()
            let ok = task.terminationStatus == 0
            result([
              "success": ok,
              "renderMode": ok ? "native_ffmpeg_render" : "native_ffmpeg_failed"
            ])
          } catch {
            result(["success": false, "renderMode": "native_ffmpeg_unavailable"])
          }
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
