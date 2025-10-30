//
//  Buttons.swift
//  Synapse Design System
//
//  Comprehensive button component library
//

import SwiftUI

// MARK: - Button Styles

/// Primary button style with filled background
struct DSPrimaryButtonStyle: ButtonStyle {
    var isLoading: Bool = false
    var isDisabled: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.buttonMedium)
            .foregroundColor(Color.Text.inverse)
            .frame(maxWidth: .infinity)
            .frame(height: Spacing.buttonHeightMedium)
            .background(
                isDisabled ? Color.Interactive.disabled :
                configuration.isPressed ? Color.Interactive.pressed :
                Color.Interactive.enabled
            )
            .cornerRadiusMedium()
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(Animations.Spring.snappy.animation, value: configuration.isPressed)
            .opacity(isLoading ? 0.6 : 1.0)
            .overlay(
                Group {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                }
            )
    }
}

/// Secondary button style with outlined border
struct DSSecondaryButtonStyle: ButtonStyle {
    var isLoading: Bool = false
    var isDisabled: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.buttonMedium)
            .foregroundColor(isDisabled ? Color.Interactive.disabledText : Color.Brand.primary)
            .frame(maxWidth: .infinity)
            .frame(height: Spacing.buttonHeightMedium)
            .background(Color.Background.primary)
            .overlay(
                RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium)
                    .stroke(
                        isDisabled ? Color.Interactive.disabled :
                        configuration.isPressed ? Color.Interactive.pressed :
                        Color.Brand.primary,
                        lineWidth: Spacing.borderMedium
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(Animations.Spring.snappy.animation, value: configuration.isPressed)
            .opacity(isLoading ? 0.6 : 1.0)
            .overlay(
                Group {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color.Brand.primary))
                    }
                }
            )
    }
}

/// Tertiary/Ghost button style with no border or background
struct DSTertiaryButtonStyle: ButtonStyle {
    var isLoading: Bool = false
    var isDisabled: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.buttonMedium)
            .foregroundColor(isDisabled ? Color.Interactive.disabledText : Color.Brand.primary)
            .frame(height: Spacing.buttonHeightMedium)
            .paddingLG()
            .background(
                configuration.isPressed ?
                    Color.Brand.primaryLight.opacity(0.3) :
                    Color.clear
            )
            .cornerRadiusMedium()
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(Animations.Spring.snappy.animation, value: configuration.isPressed)
            .opacity(isLoading ? 0.6 : 1.0)
            .overlay(
                Group {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color.Brand.primary))
                    }
                }
            )
    }
}

/// Destructive button style for dangerous actions
struct DSDestructiveButtonStyle: ButtonStyle {
    var isLoading: Bool = false
    var isDisabled: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.buttonMedium)
            .foregroundColor(Color.Text.inverse)
            .frame(maxWidth: .infinity)
            .frame(height: Spacing.buttonHeightMedium)
            .background(
                isDisabled ? Color.Interactive.disabled :
                configuration.isPressed ? Color.Status.error.opacity(0.8) :
                Color.Status.error
            )
            .cornerRadiusMedium()
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(Animations.Spring.snappy.animation, value: configuration.isPressed)
            .opacity(isLoading ? 0.6 : 1.0)
            .overlay(
                Group {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                }
            )
    }
}

/// Pill-shaped button style
struct DSPillButtonStyle: ButtonStyle {
    var color: Color = Color.Brand.primary
    var isLoading: Bool = false
    var isDisabled: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.labelMedium)
            .foregroundColor(Color.Text.inverse)
            .paddingMD()
            .paddingLG()
            .background(
                isDisabled ? Color.Interactive.disabled :
                configuration.isPressed ? color.opacity(0.8) :
                color
            )
            .cornerRadiusRound()
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(Animations.Spring.snappy.animation, value: configuration.isPressed)
            .opacity(isLoading ? 0.6 : 1.0)
            .overlay(
                Group {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                }
            )
    }
}

// MARK: - Convenience Buttons

/// Primary action button
struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var icon: String? = nil
    var isLoading: Bool = false
    var isDisabled: Bool = false

    var body: some View {
        Button(action: isDisabled || isLoading ? {} : action) {
            HStack(spacing: Spacing.iconTextSpacing) {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
        }
        .buttonStyle(DSPrimaryButtonStyle(isLoading: isLoading, isDisabled: isDisabled))
        .disabled(isDisabled || isLoading)
    }
}

/// Secondary action button
struct SecondaryButton: View {
    let title: String
    let action: () -> Void
    var icon: String? = nil
    var isLoading: Bool = false
    var isDisabled: Bool = false

    var body: some View {
        Button(action: isDisabled || isLoading ? {} : action) {
            HStack(spacing: Spacing.iconTextSpacing) {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
        }
        .buttonStyle(DSSecondaryButtonStyle(isLoading: isLoading, isDisabled: isDisabled))
        .disabled(isDisabled || isLoading)
    }
}

/// Tertiary/Ghost action button
struct TertiaryButton: View {
    let title: String
    let action: () -> Void
    var icon: String? = nil
    var isLoading: Bool = false
    var isDisabled: Bool = false

    var body: some View {
        Button(action: isDisabled || isLoading ? {} : action) {
            HStack(spacing: Spacing.iconTextSpacing) {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
        }
        .buttonStyle(DSTertiaryButtonStyle(isLoading: isLoading, isDisabled: isDisabled))
        .disabled(isDisabled || isLoading)
    }
}

/// Destructive action button
struct DestructiveButton: View {
    let title: String
    let action: () -> Void
    var icon: String? = nil
    var isLoading: Bool = false
    var isDisabled: Bool = false

    var body: some View {
        Button(action: isDisabled || isLoading ? {} : action) {
            HStack(spacing: Spacing.iconTextSpacing) {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
        }
        .buttonStyle(DSDestructiveButtonStyle(isLoading: isLoading, isDisabled: isDisabled))
        .disabled(isDisabled || isLoading)
    }
}

/// Icon-only button
struct IconButton: View {
    let icon: String
    let action: () -> Void
    var size: CGFloat = Spacing.iconMedium
    var color: Color = Color.Brand.primary
    var backgroundColor: Color = Color.clear
    var isDisabled: Bool = false

    var body: some View {
        Button(action: isDisabled ? {} : action) {
            Image(systemName: icon)
                .font(.system(size: size))
                .foregroundColor(isDisabled ? Color.Interactive.disabledText : color)
                .frame(width: size * 2, height: size * 2)
                .background(backgroundColor)
                .cornerRadiusMedium()
        }
        .disabled(isDisabled)
        .scaleButtonStyle()
    }
}

/// Floating action button (FAB)
struct FloatingActionButton: View {
    let icon: String
    let action: () -> Void
    var color: Color = Color.Brand.primary

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: Spacing.iconLarge, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(color)
                .cornerRadius(28)
                .shadowLG()
        }
        .scaleButtonStyle()
    }
}

// MARK: - Button Size Variants
extension View {
    func buttonSizeSmall() -> some View {
        self.frame(height: Spacing.buttonHeightSmall)
    }

    func buttonSizeMedium() -> some View {
        self.frame(height: Spacing.buttonHeightMedium)
    }

    func buttonSizeLarge() -> some View {
        self.frame(height: Spacing.buttonHeightLarge)
    }
}
