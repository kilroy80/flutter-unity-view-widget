import Foundation
import UIKit

class STUnityViewController: UIViewController {
    
//    let fullView: UIView
    
    var button: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        let window = UIApplication.shared.keyWindow!
//        let fullView = UIView(frame: CGRect(x: window.frame.origin.x, y: window.frame.origin.y, width: window.frame.width, height: window.frame.height))
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleMassage(_:)),
                                               name: .publishToFlutter,
                                               object: nil)
        
        button = UIButton(frame: CGRect(x: 0, y: 24.0, width: 100, height: 50))
        button.backgroundColor = .green
        button.setTitle("Exit Button", for: .normal)
        button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        button.isHidden = true

        self.view.insertSubview(button, at: 1)
        
//        reattachView()
        
        GetUnityPlayerUtils().createPlayer(completed: { [self] (view: UIView?) in
            if (view != nil) {
                self.view.insertSubview(view!, at: 0)
            }
            self.button.isHidden = false
        })
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
    
    func dismiss(viewController: UIViewController) {
        if presentedViewController == viewController {
            dismiss(animated: true)
        }
    }
    
    func reattachView() {
        let unityView = GetUnityPlayerUtils().ufw?.appController()?.rootView
        if (unityView == nil) {
            print("aaaa")
            GetUnityPlayerUtils().createPlayer(completed: { [self] (view: UIView?) in
                if (view != nil) {
                    self.view.insertSubview(view!, at: 0)
                }
                self.button.isHidden = false
            })
        } else {
            print("bbbb")
            self.view.insertSubview(unityView!, at: 0)
            self.button.isHidden = false
        }

//        GetUnityPlayerUtils().resume()
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
}
