//
//  Shadows.swift
//  Synapse Design System
//
//  Shadow and elevation system
//

import SwiftUI

// MARK: - Shadow System
struct Shadows {

    // MARK: - Shadow Definitions
    struct Level {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }

    // MARK: - Elevation Levels
    static let none = Level(color: .clear, radius: 0, x: 0, y: 0)

    static let xs = Level(
        color: Color.Shadow.small,
        radius: 2,
        x: 0,
        y: 1
    )

    static let sm = Level(
        color: Color.Shadow.small,
        radius: 4,
        x: 0,
        y: 2
    )

    static let md = Level(
        color: Color.Shadow.medium,
        radius: 8,
        x: 0,
        y: 4
    )

    static let lg = Level(
        color: Color.Shadow.medium,
        radius: 12,
        x: 0,
        y: 6
    )

    static let xl = Level(
        color: Color.Shadow.large,
        radius: 16,
        x: 0,
        y: 8
    )

    static let xl2 = Level(
        color: Color.Shadow.large,
        radius: 20,
        x: 0,
        y: 10
    )

    static let xl3 = Level(
        color: Color.Shadow.extraLarge,
        radius: 24,
        x: 0,
        y: 12
    )

    // MARK: - Semantic Shadows
    static let card = sm
    static let cardHover = md
    static let button = xs
    static let buttonPressed = none
    static let modal = xl
    static let dropdown = lg
    static let tooltip = md
}

// MARK: - View Extensions for Shadows
extension View {

    // MARK: - Shadow Level Modifiers
    func shadowNone() -> some View {
        self.shadow(
            color: Shadows.none.color,
            radius: Shadows.none.radius,
            x: Shadows.none.x,
            y: Shadows.none.y
        )
    }

    func shadowXS() -> some View {
        self.shadow(
            color: Shadows.xs.color,
            radius: Shadows.xs.radius,
            x: Shadows.xs.x,
            y: Shadows.xs.y
        )
    }

    func shadowSM() -> some View {
        self.shadow(
            color: Shadows.sm.color,
            radius: Shadows.sm.radius,
            x: Shadows.sm.x,
            y: Shadows.sm.y
        )
    }

    func shadowMD() -> some View {
        self.shadow(
            color: Shadows.md.color,
            radius: Shadows.md.radius,
            x: Shadows.md.x,
            y: Shadows.md.y
        )
    }

    func shadowLG() -> some View {
        self.shadow(
            color: Shadows.lg.color,
            radius: Shadows.lg.radius,
            x: Shadows.lg.x,
            y: Shadows.lg.y
        )
    }

    func shadowXL() -> some View {
        self.shadow(
            color: Shadows.xl.color,
            radius: Shadows.xl.radius,
            x: Shadows.xl.x,
            y: Shadows.xl.y
        )
    }

    func shadowXL2() -> some View {
        self.shadow(
            color: Shadows.xl2.color,
            radius: Shadows.xl2.radius,
            x: Shadows.xl2.x,
            y: Shadows.xl2.y
        )
    }

    func shadowXL3() -> some View {
        self.shadow(
            color: Shadows.xl3.color,
            radius: Shadows.xl3.radius,
            x: Shadows.xl3.x,
            y: Shadows.xl3.y
        )
    }

    // MARK: - Semantic Shadow Modifiers
    func cardShadow() -> some View {
        self.shadowSM()
    }

    func cardHoverShadow() -> some View {
        self.shadowMD()
    }

    func buttonShadow() -> some View {
        self.shadowXS()
    }

    func modalShadow() -> some View {
        self.shadowXL()
    }

    func dropdownShadow() -> some View {
        self.shadowLG()
    }

    func tooltipShadow() -> some View {
        self.shadowMD()
    }

    // MARK: - Custom Shadow
    func customShadow(color: Color, radius: CGFloat, x: CGFloat = 0, y: CGFloat = 0) -> some View {
        self.shadow(color: color, radius: radius, x: x, y: y)
    }

    // MARK: - Layered Shadows (for more depth)
    func layeredCardShadow() -> some View {
        self
            .shadow(color: Color.Shadow.small, radius: 2, x: 0, y: 1)
            .shadow(color: Color.Shadow.small, radius: 4, x: 0, y: 2)
    }

    func layeredModalShadow() -> some View {
        self
            .shadow(color: Color.Shadow.medium, radius: 8, x: 0, y: 4)
            .shadow(color: Color.Shadow.large, radius: 16, x: 0, y: 8)
    }
}
