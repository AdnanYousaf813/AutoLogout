//
//  Window.swift
//  AutoLogout-Example
//
//  Created by Adnan Yousaf on 27/08/2021.
//

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
