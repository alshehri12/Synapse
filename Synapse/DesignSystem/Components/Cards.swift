//
//  Cards.swift
//  Synapse Design System
//
//  Card components for consistent container styling
//

import SwiftUI

// MARK: - Basic Card
struct Card<Content: View>: View {
    let content: Content
    var padding: CGFloat = Spacing.cardPadding
    var backgroundColor: Color = Color.Background.elevated
    var cornerRadius: CGFloat = Spacing.cornerRadiusMedium
    var shadow: Bool = true

    init(
        padding: CGFloat = Spacing.cardPadding,
        backgroundColor: Color = Color.Background.elevated,
        cornerRadius: CGFloat = Spacing.cornerRadiusMedium,
        shadow: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.shadow = shadow
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .modifier(ConditionalShadow(applyShadow: shadow))
    }
}

// MARK: - Elevated Card (with prominent shadow)
struct ElevatedCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = Spacing.cardPadding

    init(
        padding: CGFloat = Spacing.cardPadding,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(Color.Background.elevated)
            .cornerRadiusMedium()
            .shadowMD()
    }
}

// MARK: - Outlined Card
struct OutlinedCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = Spacing.cardPadding
    var borderColor: Color = Color.Border.primary

    init(
        padding: CGFloat = Spacing.cardPadding,
        borderColor: Color = Color.Border.primary,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.borderColor = borderColor
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(Color.Background.primary)
            .overlay(
                RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium)
                    .stroke(borderColor, lineWidth: Spacing.borderThin)
            )
    }
}

// MARK: - Gradient Card
struct GradientCard<Content: View>: View {
    let content: Content
    var gradient: LinearGradient = Color.Gradients.primary
    var padding: CGFloat = Spacing.cardPadding

    init(
        gradient: LinearGradient = Color.Gradients.primary,
        padding: CGFloat = Spacing.cardPadding,
        @ViewBuilder content: () -> Content
    ) {
        self.gradient = gradient
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(gradient)
            .cornerRadiusMedium()
            .shadowSM()
    }
}

// MARK: - Info Card (with icon and content)
struct DSInfoCard: View {
    let icon: String
    let title: String
    let subtitle: String?
    var iconColor: Color = Color.Brand.primary
    var backgroundColor: Color = Color.Background.elevated

    init(
        icon: String,
        title: String,
        subtitle: String? = nil,
        iconColor: Color = Color.Brand.primary,
        backgroundColor: Color = Color.Background.elevated
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.iconColor = iconColor
        self.backgroundColor = backgroundColor
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: Spacing.iconLarge))
                .foregroundColor(iconColor)
                .frame(width: 48, height: 48)
                .background(iconColor.opacity(0.1))
                .cornerRadiusMedium()

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .labelLarge()

                if let subtitle = subtitle {
                    Text(subtitle)
                        .bodySmall()
                }
            }

            Spacer()
        }
        .cardPadding()
        .background(backgroundColor)
        .cornerRadiusMedium()
        .cardShadow()
    }
}

// MARK: - Stat Card
struct DSStatCard: View {
    let value: String
    let label: String
    var icon: String? = nil
    var color: Color = Color.Brand.primary

    var body: some View {
        VStack(spacing: Spacing.sm) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: Spacing.iconMedium))
                    .foregroundColor(color)
            }

            Text(value)
                .heading4(color: Color.Text.primary)

            Text(label)
                .caption(color: Color.Text.secondary)
        }
        .frame(maxWidth: .infinity)
        .paddingLG()
        .background(Color.Background.elevated)
        .cornerRadiusMedium()
        .cardShadow()
    }
}

// MARK: - Action Card (clickable card)
struct ActionCard<Content: View>: View {
    let content: Content
    let action: () -> Void
    var padding: CGFloat = Spacing.cardPadding

    init(
        padding: CGFloat = Spacing.cardPadding,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.action = action
        self.content = content()
    }

    var body: some View {
        Button(action: action) {
            content
                .padding(padding)
                .background(Color.Background.elevated)
                .cornerRadiusMedium()
                .cardShadow()
        }
        .buttonStyle(PlainButtonStyle())
        .scaleButtonStyle(pressedScale: 0.98)
    }
}

// MARK: - Helper Modifiers
private struct ConditionalShadow: ViewModifier {
    let applyShadow: Bool

    func body(content: Content) -> some View {
        if applyShadow {
            content.cardShadow()
        } else {
            content
        }
    }
}

// MARK: - Card Modifiers
extension View {
    /// Applies standard card styling
    func cardStyle(
        padding: CGFloat = Spacing.cardPadding,
        backgroundColor: Color = Color.Background.elevated,
        cornerRadius: CGFloat = Spacing.cornerRadiusMedium,
        shadow: Bool = true
    ) -> some View {
        self
            .padding(padding)
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .modifier(ConditionalShadow(applyShadow: shadow))
    }

    /// Applies elevated card styling with prominent shadow
    func elevatedCardStyle(padding: CGFloat = Spacing.cardPadding) -> some View {
        self
            .padding(padding)
            .background(Color.Background.elevated)
            .cornerRadiusMedium()
            .shadowMD()
    }

    /// Applies outlined card styling
    func outlinedCardStyle(
        padding: CGFloat = Spacing.cardPadding,
        borderColor: Color = Color.Border.primary
    ) -> some View {
        self
            .padding(padding)
            .background(Color.Background.primary)
            .overlay(
                RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium)
                    .stroke(borderColor, lineWidth: Spacing.borderThin)
            )
    }
}
