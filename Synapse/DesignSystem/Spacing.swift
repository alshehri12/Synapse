//
//  Spacing.swift
//  Synapse Design System
//
//  Spacing scale and layout constants
//

import SwiftUI

// MARK: - Spacing Scale
struct Spacing {

    // MARK: - Base Spacing Unit (4pt baseUnit)
    private static let baseUnit: CGFloat = 4

    // MARK: - Spacing Values
    static let xs: CGFloat = baseUnit * 1     // 4pt
    static let sm: CGFloat = baseUnit * 2     // 8pt
    static let md: CGFloat = baseUnit * 3     // 12pt
    static let lg: CGFloat = baseUnit * 4     // 16pt
    static let xl: CGFloat = baseUnit * 5     // 20pt
    static let xl2: CGFloat = baseUnit * 6    // 24pt
    static let xl3: CGFloat = baseUnit * 8    // 32pt
    static let xl4: CGFloat = baseUnit * 10   // 40pt
    static let xl5: CGFloat = baseUnit * 12   // 48pt
    static let xl6: CGFloat = baseUnit * 16   // 64pt

    // MARK: - Semantic Spacing
    static let none: CGFloat = 0
    static let hairline: CGFloat = 1
    static let extraSmall: CGFloat = xs
    static let small: CGFloat = sm
    static let medium: CGFloat = md
    static let base: CGFloat = lg
    static let large: CGFloat = xl
    static let extraLarge: CGFloat = xl2
    static let extraExtraLarge: CGFloat = xl3

    // MARK: - Screen Margins
    static let screenHorizontal: CGFloat = lg       // 16pt
    static let screenVertical: CGFloat = xl         // 20pt
    static let screenPadding = EdgeInsets(
        top: screenVertical,
        leading: screenHorizontal,
        bottom: screenVertical,
        trailing: screenHorizontal
    )

    // MARK: - Card Spacing
    static let cardPadding: CGFloat = lg            // 16pt
    static let cardSpacing: CGFloat = md            // 12pt
    static let cardContentSpacing: CGFloat = sm     // 8pt

    // MARK: - Component Spacing
    static let buttonPadding = EdgeInsets(
        top: md,           // 12pt
        leading: xl2,      // 24pt
        bottom: md,        // 12pt
        trailing: xl2      // 24pt
    )

    static let inputPadding = EdgeInsets(
        top: md,           // 12pt
        leading: lg,       // 16pt
        bottom: md,        // 12pt
        trailing: lg       // 16pt
    )

    static let iconTextSpacing: CGFloat = sm        // 8pt
    static let stackSpacing: CGFloat = md           // 12pt
    static let listItemSpacing: CGFloat = lg        // 16pt

    // MARK: - Corner Radius
    static let cornerRadiusSmall: CGFloat = 8
    static let cornerRadiusMedium: CGFloat = 12
    static let cornerRadiusLarge: CGFloat = 16
    static let cornerRadiusExtraLarge: CGFloat = 24
    static let cornerRadiusRound: CGFloat = 999     // Fully rounded

    // MARK: - Border Width
    static let borderThin: CGFloat = 1
    static let borderMedium: CGFloat = 2
    static let borderThick: CGFloat = 3

    // MARK: - Icon Sizes
    static let iconSmall: CGFloat = 16
    static let iconMedium: CGFloat = 20
    static let iconLarge: CGFloat = 24
    static let iconExtraLarge: CGFloat = 32

    // MARK: - Avatar Sizes
    static let avatarSmall: CGFloat = 32
    static let avatarMedium: CGFloat = 40
    static let avatarLarge: CGFloat = 56
    static let avatarExtraLarge: CGFloat = 80

    // MARK: - Button Heights
    static let buttonHeightSmall: CGFloat = 36
    static let buttonHeightMedium: CGFloat = 44      // Apple recommended minimum
    static let buttonHeightLarge: CGFloat = 52

    // MARK: - Input Heights
    static let inputHeightSmall: CGFloat = 36
    static let inputHeightMedium: CGFloat = 44
    static let inputHeightLarge: CGFloat = 52
}

// MARK: - View Extensions for Spacing
extension View {

    // MARK: - Padding Shortcuts
    func paddingXS() -> some View {
        self.padding(Spacing.xs)
    }

    func paddingSM() -> some View {
        self.padding(Spacing.sm)
    }

    func paddingMD() -> some View {
        self.padding(Spacing.md)
    }

    func paddingLG() -> some View {
        self.padding(Spacing.lg)
    }

    func paddingXL() -> some View {
        self.padding(Spacing.xl)
    }

    func paddingXL2() -> some View {
        self.padding(Spacing.xl2)
    }

    func paddingXL3() -> some View {
        self.padding(Spacing.xl3)
    }

    // MARK: - Screen Padding
    func screenPadding() -> some View {
        self.padding(Spacing.screenPadding)
    }

    func horizontalScreenPadding() -> some View {
        self.padding(.horizontal, Spacing.screenHorizontal)
    }

    func verticalScreenPadding() -> some View {
        self.padding(.vertical, Spacing.screenVertical)
    }

    // MARK: - Card Padding
    func cardPadding() -> some View {
        self.padding(Spacing.cardPadding)
    }

    func cardContentSpacing() -> some View {
        self.padding(Spacing.cardContentSpacing)
    }

    // MARK: - Corner Radius Shortcuts
    func cornerRadiusSmall() -> some View {
        self.cornerRadius(Spacing.cornerRadiusSmall)
    }

    func cornerRadiusMedium() -> some View {
        self.cornerRadius(Spacing.cornerRadiusMedium)
    }

    func cornerRadiusLarge() -> some View {
        self.cornerRadius(Spacing.cornerRadiusLarge)
    }

    func cornerRadiusXL() -> some View {
        self.cornerRadius(Spacing.cornerRadiusExtraLarge)
    }

    func cornerRadiusRound() -> some View {
        self.cornerRadius(Spacing.cornerRadiusRound)
    }
}
