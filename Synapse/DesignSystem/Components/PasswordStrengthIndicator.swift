//
//  PasswordStrengthIndicator.swift
//  Synapse Design System
//
//  Password strength indicator component
//

import SwiftUI

// MARK: - Password Strength
enum PasswordStrength {
    case weak, fair, good, strong

    var color: Color {
        switch self {
        case .weak: return Color.Status.error
        case .fair: return Color.Status.warning
        case .good: return Color(hex: "FFD700") // Gold
        case .strong: return Color.Status.success
        }
    }

    var label: String {
        switch self {
        case .weak: return "Weak"
        case .fair: return "Fair"
        case .good: return "Good"
        case .strong: return "Strong"
        }
    }

    var progress: Double {
        switch self {
        case .weak: return 0.25
        case .fair: return 0.5
        case .good: return 0.75
        case .strong: return 1.0
        }
    }
}

// MARK: - Password Strength Calculator
struct PasswordStrengthCalculator {
    static func calculateStrength(for password: String) -> PasswordStrength {
        var score = 0

        // Length check
        if password.count >= 8 {
            score += 1
        }
        if password.count >= 12 {
            score += 1
        }

        // Character variety checks
        if password.range(of: "[A-Z]", options: .regularExpression) != nil {
            score += 1 // Has uppercase
        }
        if password.range(of: "[a-z]", options: .regularExpression) != nil {
            score += 1 // Has lowercase
        }
        if password.range(of: "[0-9]", options: .regularExpression) != nil {
            score += 1 // Has numbers
        }
        if password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil {
            score += 1 // Has special characters
        }

        // Determine strength based on score
        switch score {
        case 0...2:
            return .weak
        case 3...4:
            return .fair
        case 5:
            return .good
        case 6...:
            return .strong
        default:
            return .weak
        }
    }

    static func getRequirements(for password: String) -> [PasswordRequirement] {
        [
            PasswordRequirement(
                label: "At least 8 characters",
                isMet: password.count >= 8
            ),
            PasswordRequirement(
                label: "Contains uppercase letter",
                isMet: password.range(of: "[A-Z]", options: .regularExpression) != nil
            ),
            PasswordRequirement(
                label: "Contains lowercase letter",
                isMet: password.range(of: "[a-z]", options: .regularExpression) != nil
            ),
            PasswordRequirement(
                label: "Contains number",
                isMet: password.range(of: "[0-9]", options: .regularExpression) != nil
            ),
            PasswordRequirement(
                label: "Contains special character",
                isMet: password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil
            )
        ]
    }
}

// MARK: - Password Requirement
struct PasswordRequirement {
    let label: String
    let isMet: Bool
}

// MARK: - Password Strength Indicator View
struct PasswordStrengthIndicator: View {
    let password: String
    var showRequirements: Bool = true

    private var strength: PasswordStrength {
        PasswordStrengthCalculator.calculateStrength(for: password)
    }

    private var requirements: [PasswordRequirement] {
        PasswordStrengthCalculator.getRequirements(for: password)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            if !password.isEmpty {
                // Strength bar
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack {
                        Text("Password Strength:")
                            .caption(color: Color.Text.secondary)

                        Spacer()

                        Text(strength.label)
                            .captionBold(color: strength.color)
                    }

                    DSProgressBar(
                        progress: strength.progress,
                        height: 4,
                        color: strength.color
                    )
                }

                // Requirements checklist
                if showRequirements {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        ForEach(Array(requirements.enumerated()), id: \.offset) { index, requirement in
                            HStack(spacing: Spacing.sm) {
                                Image(systemName: requirement.isMet ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 12))
                                    .foregroundColor(requirement.isMet ? Color.Status.success : Color.Text.tertiary)

                                Text(requirement.label)
                                    .caption(color: requirement.isMet ? Color.Text.primary : Color.Text.secondary)
                            }
                        }
                    }
                    .paddingSM()
                }
            }
        }
    }
}

// MARK: - Password Field with Strength Indicator
struct DSPasswordField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String? = "lock"
    var showStrengthIndicator: Bool = true
    var errorMessage: String? = nil

    @State private var isSecured: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Password input
            HStack(spacing: Spacing.md) {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(errorMessage != nil ? Color.Status.error : Color.Text.secondary)
                        .font(.system(size: Spacing.iconMedium))
                }

                if isSecured {
                    SecureField(placeholder, text: $text)
                        .bodyMedium()
                } else {
                    TextField(placeholder, text: $text)
                        .bodyMedium()
                }

                Button(action: { isSecured.toggle() }) {
                    Image(systemName: isSecured ? "eye.slash" : "eye")
                        .foregroundColor(Color.Text.secondary)
                        .font(.system(size: Spacing.iconMedium))
                }
            }
            .padding(Spacing.inputPadding)
            .background(Color.Background.elevated)
            .overlay(
                RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium)
                    .stroke(
                        errorMessage != nil ? Color.Border.error :
                        Color.Border.primary,
                        lineWidth: Spacing.borderThin
                    )
            )
            .cornerRadiusMedium()

            // Error message
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .caption(color: Color.Status.error)
            }

            // Strength indicator
            if showStrengthIndicator {
                PasswordStrengthIndicator(password: text, showRequirements: true)
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        DSPasswordField(
            placeholder: "Enter password",
            text: .constant("Test123!"),
            showStrengthIndicator: true
        )
        .paddingLG()

        DSPasswordField(
            placeholder: "Enter password",
            text: .constant("weak"),
            showStrengthIndicator: true
        )
        .paddingLG()

        DSPasswordField(
            placeholder: "Enter password",
            text: .constant("StrongP@ssw0rd!"),
            showStrengthIndicator: true
        )
        .paddingLG()
    }
    .padding()
}
