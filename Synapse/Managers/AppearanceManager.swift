//
//  AppearanceManager.swift
//  Synapse
//
//  Manages app appearance settings including dark mode preferences
//

import SwiftUI
import Combine

class AppearanceManager: ObservableObject {
    static let shared = AppearanceManager()

    // MARK: - Published Properties
    @Published var colorScheme: ColorScheme? {
        didSet {
            UserDefaults.standard.set(colorSchemeRawValue, forKey: "selectedColorScheme")
        }
    }

    // MARK: - Color Scheme Options
    enum ColorSchemePreference: String, CaseIterable {
        case system = "System"
        case light = "Light"
        case dark = "Dark"

        var icon: String {
            switch self {
            case .system:
                return "circle.lefthalf.filled"
            case .light:
                return "sun.max.fill"
            case .dark:
                return "moon.fill"
            }
        }

        var colorScheme: ColorScheme? {
            switch self {
            case .system:
                return nil
            case .light:
                return .light
            case .dark:
                return .dark
            }
        }
    }

    @Published var preference: ColorSchemePreference = .system {
        didSet {
            colorScheme = preference.colorScheme
        }
    }

    // MARK: - Computed Properties
    private var colorSchemeRawValue: String? {
        switch colorScheme {
        case .light:
            return "light"
        case .dark:
            return "dark"
        default:
            return nil
        }
    }

    // MARK: - Initialization
    private init() {
        loadPreference()
    }

    // MARK: - Methods
    private func loadPreference() {
        if let saved = UserDefaults.standard.string(forKey: "selectedColorScheme") {
            switch saved {
            case "light":
                preference = .light
                colorScheme = .light
            case "dark":
                preference = .dark
                colorScheme = .dark
            default:
                preference = .system
                colorScheme = nil
            }
        } else {
            preference = .system
            colorScheme = nil
        }
    }

    func setPreference(_ newPreference: ColorSchemePreference) {
        preference = newPreference
    }

    // MARK: - Quick Toggles
    func toggleDarkMode() {
        if preference == .dark {
            setPreference(.light)
        } else {
            setPreference(.dark)
        }
    }
}
