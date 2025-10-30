//
//  ColorTokens.swift
//  Synapse Design System
//
//  Comprehensive color system with light/dark mode support
//

import SwiftUI

// MARK: - Color Tokens
extension Color {

    // MARK: - Brand Colors
    struct Brand {
        static let primary = Color("BrandPrimary", bundle: nil, light: Color(hex: "3D9970"), dark: Color(hex: "4CAF84"))
        static let secondary = Color("BrandSecondary", bundle: nil, light: Color(hex: "FFB347"), dark: Color(hex: "FFB347"))
        static let tertiary = Color("BrandTertiary", bundle: nil, light: Color(hex: "87CEEB"), dark: Color(hex: "87CEEB"))

        // Primary variations
        static let primaryLight = Color("BrandPrimaryLight", bundle: nil, light: Color(hex: "E8F5F0"), dark: Color(hex: "1A3D30"))
        static let primaryDark = Color("BrandPrimaryDark", bundle: nil, light: Color(hex: "2D7556"), dark: Color(hex: "5FC89A"))

        // Secondary variations
        static let secondaryLight = Color("BrandSecondaryLight", bundle: nil, light: Color(hex: "FFF3E0"), dark: Color(hex: "4D3820"))
        static let secondaryDark = Color("BrandSecondaryDark", bundle: nil, light: Color(hex: "FF9800"), dark: Color(hex: "FFD699"))
    }

    // MARK: - Text Colors
    struct Text {
        static let primary = Color("TextPrimary", bundle: nil, light: Color(hex: "333333"), dark: Color(hex: "FFFFFF"))
        static let secondary = Color("TextSecondary", bundle: nil, light: Color(hex: "666666"), dark: Color(hex: "B3B3B3"))
        static let tertiary = Color("TextTertiary", bundle: nil, light: Color(hex: "999999"), dark: Color(hex: "808080"))
        static let disabled = Color("TextDisabled", bundle: nil, light: Color(hex: "CCCCCC"), dark: Color(hex: "4D4D4D"))
        static let inverse = Color("TextInverse", bundle: nil, light: Color(hex: "FFFFFF"), dark: Color(hex: "000000"))
        static let link = Color("TextLink", bundle: nil, light: Color(hex: "3D9970"), dark: Color(hex: "4CAF84"))
    }

    // MARK: - Background Colors
    struct Background {
        static let primary = Color("BackgroundPrimary", bundle: nil, light: Color(hex: "FFFFFF"), dark: Color(hex: "121212"))
        static let secondary = Color("BackgroundSecondary", bundle: nil, light: Color(hex: "F8F8F8"), dark: Color(hex: "1E1E1E"))
        static let tertiary = Color("BackgroundTertiary", bundle: nil, light: Color(hex: "F0F0F0"), dark: Color(hex: "2A2A2A"))
        static let elevated = Color("BackgroundElevated", bundle: nil, light: Color(hex: "FFFFFF"), dark: Color(hex: "1E1E1E"))
        static let overlay = Color("BackgroundOverlay", bundle: nil, light: Color(hex: "000000").opacity(0.4), dark: Color(hex: "000000").opacity(0.6))
    }

    // MARK: - Border Colors
    struct Border {
        static let primary = Color("BorderPrimary", bundle: nil, light: Color(hex: "E5E5E5"), dark: Color(hex: "333333"))
        static let secondary = Color("BorderSecondary", bundle: nil, light: Color(hex: "F0F0F0"), dark: Color(hex: "2A2A2A"))
        static let focus = Color("BorderFocus", bundle: nil, light: Color(hex: "3D9970"), dark: Color(hex: "4CAF84"))
        static let error = Color("BorderError", bundle: nil, light: Color(hex: "E84A5F"), dark: Color(hex: "FF6B7A"))
    }

    // MARK: - Status Colors
    struct Status {
        static let success = Color("StatusSuccess", bundle: nil, light: Color(hex: "3D9970"), dark: Color(hex: "4CAF84"))
        static let warning = Color("StatusWarning", bundle: nil, light: Color(hex: "FFB347"), dark: Color(hex: "FFB347"))
        static let error = Color("StatusError", bundle: nil, light: Color(hex: "E84A5F"), dark: Color(hex: "FF6B7A"))
        static let info = Color("StatusInfo", bundle: nil, light: Color(hex: "87CEEB"), dark: Color(hex: "87CEEB"))

        // Status background variants (for alerts, badges, etc.)
        static let successBackground = Color("StatusSuccessBackground", bundle: nil, light: Color(hex: "E8F5F0"), dark: Color(hex: "1A3D30"))
        static let warningBackground = Color("StatusWarningBackground", bundle: nil, light: Color(hex: "FFF3E0"), dark: Color(hex: "4D3820"))
        static let errorBackground = Color("StatusErrorBackground", bundle: nil, light: Color(hex: "FFE5E9"), dark: Color(hex: "4D1F26"))
        static let infoBackground = Color("StatusInfoBackground", bundle: nil, light: Color(hex: "E3F2FD"), dark: Color(hex: "1A3447"))
    }

    // MARK: - Interactive States
    struct Interactive {
        static let enabled = Color("InteractiveEnabled", bundle: nil, light: Color(hex: "3D9970"), dark: Color(hex: "4CAF84"))
        static let hover = Color("InteractiveHover", bundle: nil, light: Color(hex: "2D7556"), dark: Color(hex: "5FC89A"))
        static let pressed = Color("InteractivePressed", bundle: nil, light: Color(hex: "266045"), dark: Color(hex: "70D9AC"))
        static let disabled = Color("InteractiveDisabled", bundle: nil, light: Color(hex: "E5E5E5"), dark: Color(hex: "333333"))
        static let disabledText = Color("InteractiveDisabledText", bundle: nil, light: Color(hex: "CCCCCC"), dark: Color(hex: "4D4D4D"))
    }

    // MARK: - Shadow Colors
    struct Shadow {
        static let small = Color.black.opacity(0.05)
        static let medium = Color.black.opacity(0.08)
        static let large = Color.black.opacity(0.12)
        static let extraLarge = Color.black.opacity(0.15)
    }

    // MARK: - Gradient Definitions
    struct Gradients {
        static let primary = LinearGradient(
            colors: [Color.Brand.primary, Color.Brand.primaryDark],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let secondary = LinearGradient(
            colors: [Color.Brand.secondary, Color.Brand.secondaryDark],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let success = LinearGradient(
            colors: [Color.Status.success, Color.Brand.primaryDark],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let authBackground = LinearGradient(
            colors: [
                Color(hex: "E8F5F0"),
                Color(hex: "F0FFF4"),
                Color(hex: "E8F5F0")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let card = LinearGradient(
            colors: [Color.white, Color(hex: "F8F8F8")],
            startPoint: .top,
            endPoint: .bottom
        )
    }

}

// MARK: - Color Hex Initializer
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    // Helper to create color with light/dark variants
    init(_ name: String, bundle: Bundle? = nil, light: Color, dark: Color) {
        #if os(iOS)
        self.init(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(dark)
            default:
                return UIColor(light)
            }
        })
        #else
        self = light
        #endif
    }
}
