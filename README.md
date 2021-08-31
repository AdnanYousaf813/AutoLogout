# AutoLogout

AutoLogout is a swift library for managing user's session on inactivity. 

# What it does

On user inactivity, it will show an alert box to continue session or Logout as shown in screen shot, according to time set.

# ScreenShot
![alt text](https://github.com/AdnanYousaf813/AutoLogout/blob/main/Simulator%20Screen%20Shot%20-%20iPhone%208%20-%202021-08-26%20at%2016.34.58.png)

## Installation
AutoLogout is only available via CocoaPods: 
```bash
pod 'AutoLogout'
```

## Usage

* To reset timer on touch event, override sendEvent function.
* To get notify on touch event create protocol.

```swift
import UIKit

public protocol WindowDelegate: AnyObject {
    func window(_ window: Window, touchDetectedIn event: UIEvent)
}

public class Window: UIWindow {
    
    public weak var delegate: WindowDelegate?
    
    public override func sendEvent(_ event: UIEvent) {
        super.sendEvent(event)
        
        let touches = event.allTouches?
            .filter( { $0.phase == .began || $0.phase == .ended } ) ?? []
        if touches.count > 0 {
            delegate?.window(self, touchDetectedIn: event)
        }
        
    }
}
```

* Setup inactivity Timer as below

```swift
    private func setupInactivityTimers() {
        guard inactivityAlertTimer == nil else { return }
        inactivityAlertTimer = WatchTimer(duration: .minutes(inactivityAlertShowAfterMinutes)) { [weak self] in
            self?.showInactivityAlert()
            self?.inactivityAlertTimer = nil
        }
        sessionTimeoutTimer = WatchTimer(duration: .minutes(sessionTimeoutAfterMinutes)) { [weak self] in
            self?.logout()
        }
    }
```

* ShowInactivityALert func is for showing alert box.

```swift
    private func showInactivityAlert(animated: Bool = true) {
        
        guard let sessionTimeoutTimer = sessionTimeoutTimer else { return }
        
        let inactivityAlertController = InactivityAlertController(timer: sessionTimeoutTimer)
        inactivityAlertController.delegate = self

        /// Handle your logic here regarding current view controller
//        var topViewController: UIViewController = rootViewController
//        while let presentedViewController = topViewController.presentedViewController {
//            topViewController = presentedViewController
//        }
//        topViewController.present(inactivityAlertController, animated: animated)
        
        inactivityAlertController.modalPresentationStyle = .custom
        rootViewController.present(inactivityAlertController, animated: animated)
    
        self.inactivityAlertController = inactivityAlertController
        
    }
 ```
 
 * To reset timers on touch event, call this function
 ```swift
    func resetInactivityTimer() {
        inactivityAlertTimer = nil
        sessionTimeoutTimer = nil
        setupInactivityTimers()
    }
 ```
 
 * To pause and resume timers while swtiching from background to forground vise versa
 
```swift
    func pauseTimerOnbackground() {
        let inactivityRemainingSeconds = inactivityAlertTimer?.remainingTime?.in(.seconds) ?? 0
        inactivityEndDate = Calendar.current.date(byAdding: .second, value: Int(inactivityRemainingSeconds), to: Date())
        
        let sessionTimoutRemainingSeconds = sessionTimeoutTimer?.remainingTime?.in(.seconds) ?? 0
        sessionTimeoutEndDate = Calendar.current.date(byAdding: .second, value: Int(sessionTimoutRemainingSeconds), to: Date())
        
        inactivityAlertTimer?.stop()
        sessionTimeoutTimer?.stop()
    }
    
    /// if the time is remaining it will resume timer on foreground other wise user will logout automaticaly.
    func resumeTimerOnForeground() {
        
        if let sessionTimeOutDate = sessionTimeoutEndDate{
            if Date() > sessionTimeOutDate{
                self.logout()
            }else{
                let differenceInSeconds = sessionTimeOutDate.timeIntervalSince(Date())
                sessionTimeoutTimer = WatchTimer(duration: .seconds(differenceInSeconds)) { [weak self] in
                    self?.logout()
                }
            }
        }
        
        if let inactivityDate = inactivityEndDate{
            if Date() > inactivityDate{
                if inactivityAlertController != nil{
                    inactivityAlertController?.dismiss(animated: false, completion: {
                        self.showInactivityAlert(animated: false)
                        self.inactivityAlertTimer = nil
                    })
                }else{
                    self.showInactivityAlert(animated: true)
                    self.inactivityAlertTimer = nil
                }
            }else{
                let differenceInSeconds = inactivityDate.timeIntervalSince(Date())
                inactivityAlertTimer = WatchTimer(duration: .seconds(differenceInSeconds)) { [weak self] in
                    self?.showInactivityAlert()
                    self?.inactivityAlertTimer = nil
                }
            }
        }
    }
```

* Logout func where you add necessary code 
```swift
    func logout() {
        
        /// Handle here to move on required screen
        inactivityAlertTimer = nil
        sessionTimeoutTimer = nil
        self.inactivityAlertController?.dismiss(animated: true, completion: nil)
    }
```
* delegate function of InactivityAlertController for Continue and Logout Button actions

```swift
extension AppCoordinator: InactivityAlertControllerDelegate {
    func inactivityAlertControllerDidSelectLogout(_ inactivityAlertController: InactivityAlertController) {
        logout()
    }
    
    func inactivityAlertControllerDidSelectContinue(_ inactivityAlertController: InactivityAlertController) {
        setupInactivityTimers()
        inactivityAlertController.presentingViewController?.dismiss(animated: true)
    }
}
```

* To reset Timers when user touch on screen, this delegate function will get call.
```swift
extension AppCoordinator: WindowDelegate {
    func window(_ window: Window, touchDetectedIn event: UIEvent) {
        resetInactivityTimer()
    }
}
```

* You can call this function from AppDelegate class in life cycle functions
```swift
    func applicationDidEnterBackground() {
        pauseTimerOnbackground()
    }
    
    func applicationWillEnterForeground() {
        resumeTimerOnForeground()
    }
```

For more Detail See Example project.

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License
MKProgress is released under the [MIT](https://choosealicense.com/licenses/mit/) license.
