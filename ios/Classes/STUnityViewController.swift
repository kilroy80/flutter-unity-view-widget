import Foundation
import UIKit

protocol ViewControllerDataDelegate: AnyObject {
    func sendData(data: String)
}

@objc
class STUnityViewController: UIViewController, ViewControllerDataDelegate {
    
    var fullView: UIView!
    var button: UIButton!
    
    var statusBarHidden: Bool = true
    
    func sendData(data: String) {
        print(data)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setStatusBarVisible(isHidden: true)
        
        let window = UIApplication.shared.keyWindow!
        fullView = UIView(frame: CGRect(x: window.frame.origin.x, y: window.frame.origin.y, width: window.frame.width, height: window.frame.height))
        fullView.backgroundColor = .blue
        self.view.insertSubview(fullView, at: 2)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleMassage(_:)),
                                               name: .publishToFlutter,
                                               object: nil)
        
        button = UIButton(frame: CGRect(x: 0, y: statusBarHeight(), width: 100, height: 50))
        button.backgroundColor = .green
        button.setTitle("Exit Button", for: .normal)
        button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        button.isHidden = true
        self.view.insertSubview(button, at: 1)
        
        reattachUnityView()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc func handleMassage(_ notification: NSNotification) {
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
    
    @objc func buttonAction(sender: UIButton!) {
      print("Button tapped")
//      dismiss(viewController: self)
//        self.view.removeFromSuperview()
//        GetUnityPlayerUtils().unityDidUnload(nil)
//        GetUnityPlayerUtils().unload()
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
    
    override var prefersStatusBarHidden: Bool {
        return statusBarHidden
    }
    
    func showUnityView(view: UIView?) {
        self.view.insertSubview(view!, at: 0)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.setStatusBarVisible(isHidden: false)
            
            self.button.isHidden = false
            self.fullView.isHidden = true
        }
    }
    
    func setStatusBarVisible(isHidden: Bool) {
        DispatchQueue.main.async {
            self.modalPresentationCapturesStatusBarAppearance = true
            self.statusBarHidden = isHidden
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    // like flutter message
    func sendMessage(message: String?) {
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

extension String {
    public func getViewController() -> UIViewController? {
        if let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String {
            if let viewControllerType = NSClassFromString("\(appName).\(self)") as? UIViewController.Type {
                return viewControllerType.init()
            }
        }
        return nil
    }
}
