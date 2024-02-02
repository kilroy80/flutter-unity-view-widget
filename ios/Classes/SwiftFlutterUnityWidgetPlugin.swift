import Flutter
import UIKit

public class SwiftFlutterUnityWidgetPlugin: NSObject, FlutterPlugin {
    private static var methodChannel: FlutterMethodChannel?
    private static var unityEventHandler: HandleEventSink?
    private static var unityEventChannel: FlutterEventChannel?

    private static var customMethodChannel: FlutterMethodChannel?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        methodChannel = FlutterMethodChannel(name: "plugin.xraph.com/base_channel", binaryMessenger: registrar.messenger())
        unityEventChannel = FlutterEventChannel.init(name: "plugin.xraph.com/stream_channel", binaryMessenger: registrar.messenger())
        unityEventHandler = HandleEventSink()
        
        methodChannel?.setMethodCallHandler(methodHandler)
        unityEventChannel?.setStreamHandler(unityEventHandler)

        customMethodChannel = FlutterMethodChannel(name: "plugin.xraph.com/custom_channel", binaryMessenger: registrar.messenger())
        customMethodChannel?.setMethodCallHandler(customMethodHandler)
        
        let fuwFactory = FLTUnityWidgetFactory(registrar: registrar)
        registrar.register(fuwFactory, withId: "plugin.xraph.com/unity_view", gestureRecognizersBlockingPolicy: FlutterPlatformViewGestureRecognizersBlockingPolicyWaitUntilTouchesEnded)
    }

    private static func customMethodHandler(_ call: FlutterMethodCall, result: FlutterResult) {
        let arguments = call.arguments as? NSDictionary
        let data = arguments?["data"] as? String ?? ""

        if call.method == "unity#vc#create" {
            guard let presentingVC = UIApplication.shared.topViewController else {
                print("presentingVC nil")
                return
            }
            
            let nextVc = NativeUnityViewController()
            nextVc.modalPresentationStyle = UIModalPresentationStyle.fullScreen

            weak var delegate: ViewControllerDataDelegate?
            delegate = nextVc
            delegate?.sendInitData(data: "flutter -> native(ios) message \(data)")

            presentingVC.present(nextVc, animated: false)
        }
    }
    
    private static func methodHandler(_ call: FlutterMethodCall, result: FlutterResult) {
        
        let arguments = call.arguments as? NSDictionary
        let id = arguments?["unityId"] as? Int ?? 0
        let unityId = "unity-id-\(id)"

        if call.method == "unity#dispose" {
            GetUnityPlayerUtils().activeController?.dispose()
            result(nil)
        } else {
            GetUnityPlayerUtils().activeController?.reattachView()
            if call.method == "unity#isReady" {
                result(GetUnityPlayerUtils().unityIsInitiallized())
            } else if call.method == "unity#isLoaded" {
                let _isUnloaded = GetUnityPlayerUtils().isUnityLoaded()
                result(_isUnloaded)
            } else if call.method == "unity#createPlayer" {
                GetUnityPlayerUtils().activeController?.startUnityIfNeeded()
                result(nil)
            } else if call.method == "unity#isPaused" {
                let _isPaused = GetUnityPlayerUtils().isUnityPaused()
                result(_isPaused)
            } else if call.method == "unity#pausePlayer" {
                GetUnityPlayerUtils().pause()
                result(nil)
            } else if call.method == "unity#postMessage" {
                postMessage(call: call, result: result)
                result(nil)
            } else if call.method == "unity#resumePlayer" {
                GetUnityPlayerUtils().resume()
                result(nil)
            } else if call.method == "unity#unloadPlayer" {
                GetUnityPlayerUtils().unload()
                result(nil)
            } else if call.method == "unity#quitPlayer" {
                GetUnityPlayerUtils().quit()
                result(nil)
            } else if call.method == "unity#waitForUnity" {
                result(nil)
            } else {
                result(FlutterMethodNotImplemented)
            }
        }
    }
    
    /// Post messages to unity from flutter
    private static func postMessage(call: FlutterMethodCall, result: FlutterResult) {
        guard let args = call.arguments else {
            result("iOS could not recognize flutter arguments in method: (postMessage)")
            return
        }
        
        if let myArgs = args as? [String: Any],
           let gObj = myArgs["gameObject"] as? String,
           let method = myArgs["methodName"] as? String,
           let message = myArgs["message"] as? String {
            GetUnityPlayerUtils().postMessageToUnity(gameObject: gObj, unityMethodName: method, unityMessage: message)
            result(nil)
        } else {
            result(FlutterError(code: "-1", message: "iOS could not extract " +
                                "flutter arguments in method: (postMessage)", details: nil))
        }
    }
}

extension UIApplication {
    var topViewController: UIViewController? {
        var topViewController: UIViewController? = nil
        if #available(iOS 13, *) {
            topViewController = connectedScenes.compactMap {
                return ($0 as? UIWindowScene)?.windows.filter { $0.isKeyWindow  }.first?.rootViewController
            }.first
        } else {
            topViewController = keyWindow?.rootViewController
        }
        if let presented = topViewController?.presentedViewController {
            topViewController = presented
        } else if let navController = topViewController as? UINavigationController {
            topViewController = navController.topViewController
        } else if let tabBarController = topViewController as? UITabBarController {
            topViewController = tabBarController.selectedViewController
        }
        return topViewController
    }

    class func topNavigationController(_ viewController: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UINavigationController? {

            if let nav = viewController as? UINavigationController {
                return nav
            }
            if let tab = viewController as? UITabBarController {
                if let selected = tab.selectedViewController {
                    return selected.navigationController
                }
            }
            return viewController?.navigationController
        }
}
