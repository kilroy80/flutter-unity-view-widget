import Foundation
import UIKit

public protocol ViewControllerDataDelegate: AnyObject {
    func initMessage(message: String)
    func onUnityViewCreated(message: String)
    func onUnitySceneLoaded(message: String)
    func onUnityMessage(message: String)
}

@objc
open class NativeUnityViewController: UIViewController, ViewControllerDataDelegate {
    
    public var placeHolderView: UIView!
    public var contentsView: PassThroughView!

    public var isFullScreen: Bool = false
    var statusBarHidden: Bool = true
    
    open func initMessage(message: String) {
        print(message)
    }
    
    open func onUnityViewCreated(message: String) {
//        print(message)
    }
    
    open func onUnitySceneLoaded(message: String) {
//        print(message)
    }
    
    open func onUnityMessage(message: String) {
//        print(message)
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        setStatusBarVisible(isHidden: true)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleMassage(_:)),
                                               name: .publishToFlutter,
                                               object: nil)
        
        let window = UIApplication.shared.keyWindow!
        contentsView = PassThroughView(frame: CGRect(x: window.frame.origin.x, y: window.frame.origin.y, width: window.frame.width, height: window.frame.height))
        self.view.insertSubview(contentsView, at: 1)
        
        placeHolderView = UIView(frame: CGRect(x: window.frame.origin.x, y: window.frame.origin.y, width: window.frame.width, height: window.frame.height))
        placeHolderView.backgroundColor = isDarkMode ? UIColor(hexCode: "#d3d3d3") : .white
        self.view.insertSubview(placeHolderView, at: 2)
        
        reattachUnityView()
    }
    
    deinit {
       NotificationCenter.default.removeObserver(self)
    }

    @objc open func handleMassage(_ notification: NSNotification) {
        if let dict = notification.userInfo as? Dictionary<String, Any> {
            if let payload = dict["payload"] {
                if let unityMessage = payload as? Dictionary<String, Any> {
//                    print(unityMessage["data"] ?? "")
//                    handleUnityMessage(message: unityMessage["data"] as? String ?? "")

                    let eventType = unityMessage["eventType"] as? String ?? ""
                    switch (eventType) {
                        case "OnUnityViewCreated":
                            onUnityViewCreated(message: unityMessage["data"] as? String ?? "")
                            break
                        case "OnUnitySceneLoaded":
                            onUnitySceneLoaded(message: unityMessage["data"] as? String ?? "")
                            break
                        case "OnUnityMessage":
                            onUnityMessage(message: unityMessage["data"] as? String ?? "")
                            break
                        default:
                            break
                    }
                    
                }
            }
        } else {
            print("notification userInfo type error")
        }
    }
    
    public func closeViewController() {
        /// TODO : Check memory leak.
//        GetUnityPlayerUtils().unload()
        GetUnityPlayerUtils().pause()
        
        NotificationCenter.default.removeObserver(self)
        self.dismiss(animated: false)
    }
    
    func reattachUnityView() {
        let unityView = GetUnityPlayerUtils().ufw?.appController()?.rootView
        if (unityView == nil) {
//            print("new Unity")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                GetUnityPlayerUtils().createPlayer(completed: { [self] (view: UIView?) in
                    if (view != nil) {
                        showUnityView(view: view!)
                    }
                })
            }
        } else {
//            print("re Unity")
            showUnityView(view: unityView!)
        }

        GetUnityPlayerUtils().resume()
    }
    
    open override var prefersStatusBarHidden: Bool {
        return statusBarHidden
    }
    
    func showUnityView(view: UIView?) {
        self.view.insertSubview(view!, at: 0)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if (!self.isFullScreen) {
                self.setStatusBarVisible(isHidden: false)
            }
            
            self.contentsView.isHidden = false
            self.placeHolderView.isHidden = true
        }
    }
    
    open func addContentsView(view: UIView!) {
        self.view.insertSubview(view, at: 1)
    }
    
    func setStatusBarVisible(isHidden: Bool) {
        DispatchQueue.main.async {
            self.modalPresentationCapturesStatusBarAppearance = true
            self.statusBarHidden = isHidden
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    // like flutter message
    open func sendMessage(unityMessage: String?) {
        UnityPlayerUtils().postMessageToUnity(
            gameObject: "UnityMessageManager", unityMethodName: "onFlutterMessage", unityMessage: unityMessage
        )
    }
    
    open func sendMessage(gameObject: String?, unityMethodName: String?, unityMessage: String?) {
        UnityPlayerUtils().postMessageToUnity(
            gameObject: gameObject, unityMethodName: unityMethodName, unityMessage: unityMessage
        )
    }
}

extension UIViewController {
    var isDarkMode: Bool {
        if #available(iOS 13.0, *) {
            return self.traitCollection.userInterfaceStyle == .dark
        }
        else {
            return false
        }
    }
    
    func statusBarHeight() -> CGFloat {
        let statusBarSize = UIApplication.shared.statusBarFrame.size
        return Swift.min(statusBarSize.width, statusBarSize.height)
    }
}

extension UIColor {
    
    convenience init(hexCode: String, alpha: CGFloat = 1.0) {
        var hexFormatted: String = hexCode.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).uppercased()
        
        if hexFormatted.hasPrefix("#") {
            hexFormatted = String(hexFormatted.dropFirst())
        }
        
        assert(hexFormatted.count == 6, "Invalid hex code used.")
        
        var rgbValue: UInt64 = 0
        Scanner(string: hexFormatted).scanHexInt64(&rgbValue)
        
        self.init(red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
                  green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
                  blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
                  alpha: alpha)
    }
}

extension Bundle {
    /// Application name shown under the application icon.
    var applicationName: String? {
        object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ??
            object(forInfoDictionaryKey: "CFBundleName") as? String
    }
}

public class PassThroughView: UIView {
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        return view == self ? nil : view
    }
}
