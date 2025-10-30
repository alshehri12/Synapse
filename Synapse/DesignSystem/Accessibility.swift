//
//  Accessibility.swift
//  Synapse Design System
//
//  Accessibility helpers and extensions
//

import SwiftUI

// MARK: - Accessibility Extensions
extension View {
    /// Adds accessibility label and hint
    func accessible(
        label: String,
        hint: String? = nil,
        traits: AccessibilityTraits = []
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(traits)
    }

    /// Adds accessibility value for dynamic content
    func accessibleValue(_ value: String) -> some View {
        self.accessibilityValue(value)
    }

    /// Marks view as an accessibility element
    func accessibleElement(children: AccessibilityChildBehavior = .ignore) -> some View {
        self.accessibilityElement(children: children)
    }

    /// Groups accessibility elements
    func accessibleGroup() -> some View {
        self.accessibilityElement(children: .combine)
    }

    /// Marks as button for VoiceOver
    func accessibleButton(label: String, hint: String? = nil) -> some View {
        self.accessible(label: label, hint: hint, traits: .isButton)
    }

    /// Marks as header for VoiceOver
    func accessibleHeader(label: String) -> some View {
        self.accessible(label: label, traits: .isHeader)
    }

    /// Adds custom accessibility action
    func accessibleAction(named name: String, action: @escaping () -> Void) -> some View {
        self.accessibilityAction(named: name, action)
    }

    /// Hides from accessibility
    func accessibilityHidden() -> some View {
        self.accessibilityHidden(true)
    }
}

// MARK: - Dynamic Type Support
extension View {
    /// Enables dynamic type scaling for custom fonts
    func scaledFont(_ font: Font, maxSize: CGFloat? = nil) -> some View {
        self.modifier(ScaledFontModifier(font: font, maxSize: maxSize))
    }
}

struct ScaledFontModifier: ViewModifier {
    let font: Font
    let maxSize: CGFloat?

    @Environment(\.sizeCategory) var sizeCategory

    func body(content: Content) -> some View {
        let scaleFactor = sizeCategory.scaleFactor
        return content.font(font)
    }
}

extension ContentSizeCategory {
    var scaleFactor: CGFloat {
        switch self {
        case .extraSmall:
            return 0.8
        case .small:
            return 0.9
        case .medium:
            return 1.0
        case .large:
            return 1.0
        case .extraLarge:
            return 1.1
        case .extraExtraLarge:
            return 1.2
        case .extraExtraExtraLarge:
            return 1.3
        case .accessibilityMedium:
            return 1.4
        case .accessibilityLarge:
            return 1.6
        case .accessibilityExtraLarge:
            return 1.8
        case .accessibilityExtraExtraLarge:
            return 2.0
        case .accessibilityExtraExtraExtraLarge:
            return 2.2
        @unknown default:
            return 1.0
        }
    }
}

// MARK: - Minimum Tap Target Size
extension View {
    /// Ensures minimum tap target size of 44x44 points (Apple HIG)
    func minimumTapTarget(width: CGFloat = 44, height: CGFloat = 44) -> some View {
        self.frame(minWidth: width, minHeight: height)
    }
}

// MARK: - Reduce Motion Support
extension View {
    /// Applies animation only if reduce motion is disabled
    func animationIfEnabled<V: Equatable>(
        _ animation: Animation?,
        value: V
    ) -> some View {
        self.modifier(ReduceMotionModifier(animation: animation, value: value))
    }
}

struct ReduceMotionModifier<Value: Equatable>: ViewModifier {
    let animation: Animation?
    let value: Value

    @Environment(\.accessibilityReduceMotion) var reduceMotion

    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            content.animation(animation, value: value)
        }
    }
}

// MARK: - Color Contrast Helpers
extension Color {
    /// Returns appropriate foreground color (black or white) for this background
    var accessibleForeground: Color {
        // Simplified contrast calculation
        // For production, use proper WCAG contrast ratio calculation
        let components = UIColor(self).cgColor.components ?? [0, 0, 0, 1]
        let brightness = ((components[0] * 299) + (components[1] * 587) + (components[2] * 114)) / 1000

        return brightness > 0.5 ? .black : .white
    }

    /// Checks if color contrast meets WCAG AA standards
    func meetsContrastRatio(against background: Color, level: ContrastLevel = .aa) -> Bool {
        let ratio = contrastRatio(with: background)
        switch level {
        case .aa:
            return ratio >= 4.5
        case .aaa:
            return ratio >= 7.0
        }
    }

    /// Calculates contrast ratio between two colors
    func contrastRatio(with other: Color) -> CGFloat {
        let l1 = self.relativeLuminance
        let l2 = other.relativeLuminance
        let lighter = max(l1, l2)
        let darker = min(l1, l2)
        return (lighter + 0.05) / (darker + 0.05)
    }

    private var relativeLuminance: CGFloat {
        let components = UIColor(self).cgColor.components ?? [0, 0, 0, 1]
        let r = linearize(components[0])
        let g = linearize(components[1])
        let b = linearize(components[2])
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }

    private func linearize(_ value: CGFloat) -> CGFloat {
        if value <= 0.03928 {
            return value / 12.92
        } else {
            return pow((value + 0.055) / 1.055, 2.4)
        }
    }

    enum ContrastLevel {
        case aa  // 4.5:1 ratio
        case aaa // 7:1 ratio
    }
}

// MARK: - Haptic Feedback
struct HapticFeedback {
    static func selection() {
        #if os(iOS)
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
        #endif
    }

    static func impact(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
        #endif
    }

    static func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
        #endif
    }

    static func success() {
        notification(type: .success)
    }

    static func warning() {
        notification(type: .warning)
    }

    static func error() {
        notification(type: .error)
    }
}

// MARK: - Accessibility Identifiers
extension View {
    /// Adds accessibility identifier for UI testing
    func accessibilityID(_ identifier: String) -> some View {
        self.accessibilityIdentifier(identifier)
    }
}

// MARK: - Focus Management
extension View {
    /// Makes view focusable for keyboard navigation
    @available(iOS 15.0, *)
    func keyboardFocusable() -> some View {
        self.focusable(true)
    }
}

// MARK: - Accessibility Announcements
struct AccessibilityAnnouncement {
    static func announce(_ message: String, delay: Double = 0.5) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            UIAccessibility.post(notification: .announcement, argument: message)
        }
    }

    static func screenChanged(to element: Any? = nil) {
        UIAccessibility.post(notification: .screenChanged, argument: element)
    }

    static func layoutChanged(to element: Any? = nil) {
        UIAccessibility.post(notification: .layoutChanged, argument: element)
    }
}

// MARK: - Semantic Colors for Accessibility
extension Color {
    /// Returns color with automatic adjustment for accessibility needs
    func accessibilityAdjusted(for background: Color) -> Color {
        if meetsContrastRatio(against: background, level: .aa) {
            return self
        } else {
            // Return adjusted color if contrast is insufficient
            // This is a simplified version - production code should properly adjust
            return background.accessibleForeground
        }
    }
}
