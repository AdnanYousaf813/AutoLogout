//
//  RootViewController.swift
//  AutoLogout-Example
//
//  Created by Adnan Yousaf on 27/08/2021.
//

import UIKit

class RootViewController: UIViewController {
    
    private(set) var contentViewController: UIViewController?
    
    override var childForStatusBarStyle: UIViewController? {
        return contentViewController
    }
    override var childForStatusBarHidden: UIViewController? {
        return contentViewController
    }
    
    override var childForHomeIndicatorAutoHidden: UIViewController? {
        return contentViewController
    }
    
    func setContent(_ newViewController: UIViewController, animated: Bool) {
        
        guard self.contentViewController != newViewController else { return }
        
        let oldViewController = self.contentViewController
        self.contentViewController = newViewController
        
        oldViewController?.willMove(toParent: nil)
        let oldView = oldViewController?.view
        
        addChild(newViewController)
        let newView = newViewController.view!
        newView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(newView)
        
        NSLayoutConstraint.activate([
            newView.topAnchor.constraint(equalTo: view.topAnchor),
            newView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            newView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            newView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        guard animated else {
            oldView?.removeFromSuperview()
            oldViewController?.removeFromParent()
            newViewController.didMove(toParent: self)
            setNeedsStatusBarAppearanceUpdate()
            return
        }
        
        newView.alpha = 0
        
        UIView.animate(
            withDuration: 0.3,
            delay: 0,
            usingSpringWithDamping: 1,
            initialSpringVelocity: 1,
            options: [],
            animations: { [weak self] in
                newView.alpha = 1
                oldView?.alpha = 0
                self?.setNeedsStatusBarAppearanceUpdate()
            },
            completion: { [weak self] completed in
                oldView?.removeFromSuperview()
                oldViewController?.removeFromParent()
                newViewController.didMove(toParent: self)
        })
        
    }
}

