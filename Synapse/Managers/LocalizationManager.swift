//
//  LocalizationManager.swift
//  Synapse
//
//  Created by Abdulrahman Alshehri on 18/01/1447 AH.
//

import Foundation
import SwiftUI

class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    @Published var currentLanguage: Language {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "selectedLanguage")
            updateLocale()
        }
    }
    
    @Published var locale: Locale {
        didSet {
            UserDefaults.standard.set(locale.identifier, forKey: "appLocale")
        }
    }
    
    enum Language: String, CaseIterable {
        case english = "en"
        case arabic = "ar"
        
        var displayName: String {
            switch self {
            case .english:
                return "English"
            case .arabic:
                return "العربية"
            }
        }
        
        var locale: Locale {
            switch self {
            case .english:
                return Locale(identifier: "en")
            case .arabic:
                return Locale(identifier: "ar")
            }
        }
    }
    
    private init() {
        // Load saved language preference
        let savedLanguage = UserDefaults.standard.string(forKey: "selectedLanguage") ?? Language.english.rawValue
        let language = Language(rawValue: savedLanguage) ?? .english
        self.currentLanguage = language
        
        // Initialize locale based on the language
        self.locale = language.locale
    }
    
    private func updateLocale() {
        locale = currentLanguage.locale
    }
    
    func setLanguage(_ language: Language) {
        currentLanguage = language
    }
}

// MARK: - Localized String Extension
extension String {
    var localized: String {
        let language = LocalizationManager.shared.currentLanguage
        let bundle = Bundle.main
        
        if let path = bundle.path(forResource: language.rawValue, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return NSLocalizedString(self, bundle: bundle, comment: "")
        }
        
        return NSLocalizedString(self, comment: "")
    }
} 