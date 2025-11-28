//
//  Typography.swift
//  Synapse Design System
//
//  Typography scale and text styles
//

import SwiftUI

// MARK: - Font Weights
extension Font.Weight {
    static let light = Font.Weight.light
    static let regular = Font.Weight.regular
    static let medium = Font.Weight.medium
    static let semibold = Font.Weight.semibold
    static let bold = Font.Weight.bold
}

// MARK: - Typography Scale
struct Typography {

    // MARK: - Font Sizes (Scale)
    enum Size {
        static let xs: CGFloat = 10      // Extra small
        static let sm: CGFloat = 12      // Small
        static let base: CGFloat = 14    // Base/Body
        static let md: CGFloat = 16      // Medium
        static let lg: CGFloat = 18      // Large
        static let xl: CGFloat = 20      // Extra large
        static let xl2: CGFloat = 24     // 2XL
        static let xl3: CGFloat = 28     // 3XL
        static let xl4: CGFloat = 32     // 4XL
        static let xl5: CGFloat = 40     // 5XL
        static let xl6: CGFloat = 48     // 6XL
    }

    // MARK: - Line Heights (Leading)
    enum LineHeight {
        static let tight: CGFloat = 1.15
        static let normal: CGFloat = 1.5
        static let relaxed: CGFloat = 1.75
        static let loose: CGFloat = 2.0
    }

    // MARK: - Letter Spacing (Tracking)
    enum LetterSpacing {
        static let tight: CGFloat = -0.5
        static let normal: CGFloat = 0
        static let wide: CGFloat = 0.5
        static let wider: CGFloat = 1.0
    }
}

// MARK: - Text Styles (Semantic)
extension Font {

    // MARK: - Display Styles
    static let displayLarge = system(size: Typography.Size.xl6, weight: .bold)
    static let displayMedium = system(size: Typography.Size.xl5, weight: .bold)
    static let displaySmall = system(size: Typography.Size.xl4, weight: .bold)

    // MARK: - Heading Styles
    static let heading1 = system(size: Typography.Size.xl4, weight: .semibold)
    static let heading2 = system(size: Typography.Size.xl3, weight: .semibold)
    static let heading3 = system(size: Typography.Size.xl2, weight: .semibold)
    static let heading4 = system(size: Typography.Size.xl, weight: .semibold)
    static let heading5 = system(size: Typography.Size.lg, weight: .semibold)
    static let heading6 = system(size: Typography.Size.md, weight: .semibold)

    // MARK: - Body Styles
    static let bodyLarge = system(size: Typography.Size.lg, weight: .regular)
    static let bodyMedium = system(size: Typography.Size.md, weight: .regular)
    static let bodyBase = system(size: Typography.Size.base, weight: .regular)
    static let bodySmall = system(size: Typography.Size.sm, weight: .regular)

    // MARK: - Label Styles
    static let labelLarge = system(size: Typography.Size.md, weight: .medium)
    static let labelMedium = system(size: Typography.Size.base, weight: .medium)
    static let labelSmall = system(size: Typography.Size.sm, weight: .medium)

    // MARK: - Caption Styles
    static let caption = system(size: Typography.Size.sm, weight: .regular)
    static let captionBold = system(size: Typography.Size.sm, weight: .semibold)
    static let overline = system(size: Typography.Size.xs, weight: .semibold)

    // MARK: - Button Styles
    static let buttonLarge = system(size: Typography.Size.lg, weight: .semibold)
    static let buttonMedium = system(size: Typography.Size.md, weight: .semibold)
    static let buttonSmall = system(size: Typography.Size.base, weight: .medium)
}

// MARK: - View Extensions for Typography
extension View {

    // MARK: - Display Text Modifiers
    func displayLarge(color: Color = .textPrimary) -> some View {
        self
            .font(.displayLarge)
            .foregroundColor(color)
            .lineSpacing(Typography.Size.xl6 * (Typography.LineHeight.tight - 1))
    }

    func displayMedium(color: Color = .textPrimary) -> some View {
        self
            .font(.displayMedium)
            .foregroundColor(color)
            .lineSpacing(Typography.Size.xl5 * (Typography.LineHeight.tight - 1))
    }

    func displaySmall(color: Color = .textPrimary) -> some View {
        self
            .font(.displaySmall)
            .foregroundColor(color)
            .lineSpacing(Typography.Size.xl4 * (Typography.LineHeight.tight - 1))
    }

    // MARK: - Heading Text Modifiers
    func heading1(color: Color = .textPrimary) -> some View {
        self
            .font(.heading1)
            .foregroundColor(color)
            .lineSpacing(Typography.Size.xl4 * (Typography.LineHeight.normal - 1))
    }

    func heading2(color: Color = .textPrimary) -> some View {
        self
            .font(.heading2)
            .foregroundColor(color)
            .lineSpacing(Typography.Size.xl3 * (Typography.LineHeight.normal - 1))
    }

    func heading3(color: Color = .textPrimary) -> some View {
        self
            .font(.heading3)
            .foregroundColor(color)
            .lineSpacing(Typography.Size.xl2 * (Typography.LineHeight.normal - 1))
    }

    func heading4(color: Color = .textPrimary) -> some View {
        self
            .font(.heading4)
            .foregroundColor(color)
    }

    func heading5(color: Color = .textPrimary) -> some View {
        self
            .font(.heading5)
            .foregroundColor(color)
    }

    func heading6(color: Color = .textPrimary) -> some View {
        self
            .font(.heading6)
            .foregroundColor(color)
    }

    // MARK: - Body Text Modifiers
    func bodyLarge(color: Color = .textPrimary) -> some View {
        self
            .font(.bodyLarge)
            .foregroundColor(color)
            .lineSpacing(Typography.Size.lg * (Typography.LineHeight.normal - 1))
    }

    func bodyMedium(color: Color = .textPrimary) -> some View {
        self
            .font(.bodyMedium)
            .foregroundColor(color)
            .lineSpacing(Typography.Size.md * (Typography.LineHeight.normal - 1))
    }

    func bodyBase(color: Color = .textPrimary) -> some View {
        self
            .font(.bodyBase)
            .foregroundColor(color)
            .lineSpacing(Typography.Size.base * (Typography.LineHeight.normal - 1))
    }

    func bodySmall(color: Color = .textSecondary) -> some View {
        self
            .font(.bodySmall)
            .foregroundColor(color)
    }

    // MARK: - Label Text Modifiers
    func labelLarge(color: Color = .textPrimary) -> some View {
        self
            .font(.labelLarge)
            .foregroundColor(color)
    }

    func labelMedium(color: Color = .textPrimary) -> some View {
        self
            .font(.labelMedium)
            .foregroundColor(color)
    }

    func labelSmall(color: Color = .textSecondary) -> some View {
        self
            .font(.labelSmall)
            .foregroundColor(color)
    }

    // MARK: - Caption Text Modifiers
    func caption(color: Color = .textSecondary) -> some View {
        self
            .font(.caption)
            .foregroundColor(color)
    }

    func captionBold(color: Color = .textPrimary) -> some View {
        self
            .font(.captionBold)
            .foregroundColor(color)
    }

    func overline(color: Color = .textSecondary) -> some View {
        if #available(iOS 16.0, *) {
            return AnyView(
                self
                    .font(.overline)
                    .foregroundColor(color)
                    .tracking(Typography.LetterSpacing.wider)
                    .textCase(.uppercase)
            )
        } else {
            // iOS 15: Skip letter spacing (not available)
            return AnyView(
                self
                    .font(.overline)
                    .foregroundColor(color)
                    .textCase(.uppercase)
            )
        }
    }
}
