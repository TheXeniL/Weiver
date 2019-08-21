//
//  UIView+animations.swift
//  Weiver
//
//  Created by Nikita Elizarov on 01.07.2019.
//  Copyright © 2019 Nikita Elizarov. All rights reserved.
//

import UIKit

extension UIView {

    func fadeIn() {
        // Move our fade out code from earlier
        UIView.animate(withDuration: 0.5, delay: 0.0, options: UIView.AnimationOptions.curveEaseIn, animations: {
        self.alpha = 1.0 
      }, completion: nil)
    }

    func fadeOut() {
        UIView.animate(withDuration: 1.0, delay: 0.0, options: UIView.AnimationOptions.curveEaseOut, animations: {
            self.alpha = 0.0
        }, completion: nil)
    }
}
