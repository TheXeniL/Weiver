//
//  UITextView.swift
//  Weiver
//
//  Created by Nikita Elizarov on 02.07.2019.
//  Copyright © 2019 Nikita Elizarov. All rights reserved.
//

import Foundation
import UIKit

extension String {
    var characterArray: [Character]{
        var characterArray = [Character]()
        for character in self {
            characterArray.append(character)
        }
        return characterArray
    }
}
extension UITextView {
    func typeOn(string: String) {
        let characterArray = string.characterArray
        var characterIndex = 0

        Timer.scheduledTimer(withTimeInterval: 0.04, repeats: true) { (timer) in
            if characterArray[characterIndex] != "$" {
                while characterArray[characterIndex] == " " {
                    self.text.append(" ")
                    characterIndex += 1
                    if characterIndex == characterArray.count {
                        timer.invalidate()
                        return
                    }
                }
                self.text.append(characterArray[characterIndex])
            }
            characterIndex += 1
            if characterIndex == characterArray.count {
                timer.invalidate()
            }
        }
    }
}
