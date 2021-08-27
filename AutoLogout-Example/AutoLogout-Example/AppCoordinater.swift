//
//  AppCoordinater.swift
//  AutoLogout-Example
//
//  Created by Adnan Yousaf on 27/08/2021.
//

import UIKit
import AutoLogout

class AppCoordinator {
    
    let window: Window
    private let rootViewController: RootViewController
    
    private var inactivityAlertTimer: WatchTimer?
    private var sessionTimeoutTimer: WatchTimer?
    private weak var inactivityAlertController: InactivityAlertController?
    
    private var inactivityEndDate: Date?
    private var sessionTimeoutEndDate: Date?
    
    private var inactivityAlertShowAfterMinutes = 1.0 /// Time after which pop up will appear for remaining time
    private var sessionTimeoutAfterMinutes = 2.0 /// Total Session Time Out Time
    
    init() {
        self.window = Window(frame: UIScreen.main.bounds)
        self.rootViewController = RootViewController()
        window.delegate = self
        window.tintColor = UIColor.white
        window.rootViewController = rootViewController
        showSplashView()
        setupInactivityTimers()
    }
    
    private func showSplashView() {
        let viewController = ViewController()
        viewController.view.backgroundColor = UIColor.white
        
        let message = UILabel()
        message.text = "Wait, the session will Expire Soon."
        message.translatesAutoresizingMaskIntoConstraints = false
        message.lineBreakMode = .byWordWrapping
        message.numberOfLines = 0
        message.textAlignment = .center
        
        viewController.view.addSubview(message)
        
        message.widthAnchor.constraint(equalTo: viewController.view.widthAnchor).isActive = true
        message.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor).isActive = true
        message.centerYAnchor.constraint(equalTo: viewController.view.centerYAnchor).isActive = true
        rootViewController.setContent(viewController, animated: false)
    }
    
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
    
    func resetInactivityTimer() {
        inactivityAlertTimer = nil
        sessionTimeoutTimer = nil
        setupInactivityTimers()
    }
    
    func pauseTimerOnbackground() {
        let inactivityRemainingSeconds = inactivityAlertTimer?.remainingTime?.in(.seconds) ?? 0
        inactivityEndDate = Calendar.current.date(byAdding: .second, value: Int(inactivityRemainingSeconds), to: Date())
        
        let sessionTimoutRemainingSeconds = sessionTimeoutTimer?.remainingTime?.in(.seconds) ?? 0
        sessionTimeoutEndDate = Calendar.current.date(byAdding: .second, value: Int(sessionTimoutRemainingSeconds), to: Date())
        
        inactivityAlertTimer?.stop()
        sessionTimeoutTimer?.stop()
    }
    
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
    
    // MARK: - Logout
    func logout() {
        
        /// Handle here to move on required screen
        print("Logout")
        inactivityAlertTimer = nil
        sessionTimeoutTimer = nil
        self.inactivityAlertController?.dismiss(animated: true, completion: nil)
    }
    
    func applicationDidEnterBackground() {
        pauseTimerOnbackground()
    }
    
    func applicationWillEnterForeground() {
        resumeTimerOnForeground()
    }
    
}

// MARK: - Inactivity Alert delegate
extension AppCoordinator: InactivityAlertControllerDelegate {
    func inactivityAlertControllerDidSelectLogout(_ inactivityAlertController: InactivityAlertController) {
        logout()
    }
    
    func inactivityAlertControllerDidSelectContinue(_ inactivityAlertController: InactivityAlertController) {
        setupInactivityTimers()
        inactivityAlertController.presentingViewController?.dismiss(animated: true)
    }
}

// MARK: - Window delegate
extension AppCoordinator: WindowDelegate {
    func window(_ window: Window, touchDetectedIn event: UIEvent) {
        //authenticationCoordinator?.resetInactivityTimer()
        resetInactivityTimer()
    }
}


