//
//  Theme.swift
//  llitgi
//
//  Created by Xavi Moll on 24/08/2018.
//  Copyright © 2018 xmollv. All rights reserved.
//

import Foundation
import UIKit

enum Theme: String {
    case light
    case dark
    case black
    
    init(withName name: String) {
        switch name {
        case "light": self = .light
        case "dark": self = .dark
        case "black": self = .black
        default: self = .light
        }
    }
    
    var tintColor: UIColor {
        switch self {
        case .light: return .black
        case .dark, .black: return .white
        }
    }
    
    var backgroundColor: UIColor {
        switch self {
        case .light: return .white
        case .dark: return UIColor(red: 30/255, green: 40/255, blue: 52/255, alpha: 1)
        case .black: return .black
        }
    }
    
    var textTitleColor: UIColor {
        switch self {
        case .light: return .black
        case .dark, .black: return .white
        }
    }
    
    var textSubtitleColor: UIColor {
        switch self {
        case .light: return .darkGray
        case .dark, .black: return .lightGray
        }
    }
}

final class ThemeManager {
    
    typealias ThemeChanged = (_ theme: Theme) -> Void
    
    //MARK:- Private properties
    private var themeChangedBlocks: [ThemeChanged] = []
    
    //MARK: Public properties
    var theme: Theme = .light {
        didSet {
            UserDefaults.standard.setValue(theme.rawValue, forKey: "savedTheme")
            self.themeChangedBlocks.forEach{ $0(theme) }
            //self.themeChanged?(theme)
        }
    }
    var themeChanged: ThemeChanged? {
        didSet {
            guard let block = self.themeChanged else { return }
            //TODO: The array is holding the blocks in a strong way, therefore they are never being deallocated
            //and can cause the same call more times than extened.
            self.themeChangedBlocks.append(block)
        }
    }
    
    init() {
        self.theme = Theme(withName: UserDefaults.standard.string(forKey: "savedTheme") ?? "")
    }
}
