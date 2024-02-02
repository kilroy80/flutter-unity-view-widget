import Foundation
import UIKit

public protocol ViewControllerDataDelegate: AnyObject {
    func sendInitData(data: String)
}

public protocol AddContents: AnyObject {
    func addContentsView()
}

@objc
open class NativeUnityViewController: UIViewController, ViewControllerDataDelegate {
    
    public var placeHolerView: UIView!
    public var contentsView: PassthroughView!
//    var button: UIButton!
    
    var statusBarHidden: Bool = true
    
    open func sendInitData(data: String) {
        print(data)
    }
    
    open func addContentsView() {
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        setStatusBarVisible(isHidden: true)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleMassage(_:)),
                                               name: .publishToFlutter,
                                               object: nil)
        
        let window = UIApplication.shared.keyWindow!
        contentsView = PassthroughView(frame: CGRect(x: window.frame.origin.x, y: window.frame.origin.y, width: window.frame.width, height: window.frame.height))
        self.view.insertSubview(contentsView, at: 1)
        
        placeHolerView = UIView(frame: CGRect(x: window.frame.origin.x, y: window.frame.origin.y, width: window.frame.width, height: window.frame.height))
        placeHolerView.backgroundColor = .blue
        self.view.insertSubview(placeHolerView, at: 2)
        
        reattachUnityView()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc open func handleMassage(_ notification: NSNotification) {
        if let dict = notification.userInfo as? Dictionary<String, Any> {
            if let payload = dict["payload"] {
                if let unityMessage = payload as? Dictionary<String, Any> {
                    print(unityMessage["data"] ?? "")
                }
            }
        } else {
            print("notification userInfo type error")
        }
    }
    
    public func close() {
        NotificationCenter.default.removeObserver(self)
        GetUnityPlayerUtils().unload()
        self.dismiss(animated: false)
    }
    
//     func dismiss(viewController: UIViewController) {
//         if presentedViewController == viewController {
//             dismiss(animated: true)
//         }
//     }
    
    func reattachUnityView() {
        let unityView = GetUnityPlayerUtils().ufw?.appController()?.rootView
        if (unityView == nil) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                GetUnityPlayerUtils().createPlayer(completed: { [self] (view: UIView?) in
                    if (view != nil) {
                        showUnityView(view: view!)
                    }
                })
            }
        } else {
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
            self.setStatusBarVisible(isHidden: false)
            
            self.contentsView.isHidden = false
            self.placeHolerView.isHidden = true
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
    open func sendMessage(message: String?) {
        UnityPlayerUtils().postMessageToUnity(
            gameObject: "UnityMessageManager", unityMethodName: "onFlutterMessage", unityMessage: message
        )
    }
}

extension UIViewController {
    func back() {
        if presentingViewController != nil {
            dismiss(animated: true, completion: nil) // present
        } else {
            navigationController?.popViewController(animated: true) // push
        }
    }
    
    func statusBarHeight() -> CGFloat {
        let statusBarSize = UIApplication.shared.statusBarFrame.size
        return Swift.min(statusBarSize.width, statusBarSize.height)
    }
}

extension Bundle {
    /// Application name shown under the application icon.
    var applicationName: String? {
        object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ??
            object(forInfoDictionaryKey: "CFBundleName") as? String
    }
}

public class PassthroughView: UIView {
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        return view == self ? nil : view
    }
}
