//
//  Inputs.swift
//  Synapse Design System
//
//  Input field components with consistent styling
//

import SwiftUI

// MARK: - Text Input Field
struct DSTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil
    var errorMessage: String? = nil
    var helperText: String? = nil
    var isDisabled: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.md) {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(errorMessage != nil ? Color.Status.error : Color.Text.secondary)
                        .font(.system(size: Spacing.iconMedium))
                }

                TextField(placeholder, text: $text)
                    .bodyMedium()
                    .disabled(isDisabled)
            }
            .padding(Spacing.inputPadding)
            .background(isDisabled ? Color.Background.secondary : Color.Background.elevated)
            .overlay(
                RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium)
                    .stroke(
                        errorMessage != nil ? Color.Border.error :
                        Color.Border.primary,
                        lineWidth: Spacing.borderThin
                    )
            )
            .cornerRadiusMedium()

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .caption(color: Color.Status.error)
            } else if let helperText = helperText {
                Text(helperText)
                    .caption(color: Color.Text.secondary)
            }
        }
    }
}

// MARK: - Secure Text Input Field
struct DSSecureField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil
    var errorMessage: String? = nil
    var helperText: String? = nil
    @State private var isSecured: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
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

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .caption(color: Color.Status.error)
            } else if let helperText = helperText {
                Text(helperText)
                    .caption(color: Color.Text.secondary)
            }
        }
    }
}

// MARK: - Text Area (Multi-line)
struct DSTextArea: View {
    let placeholder: String
    @Binding var text: String
    var minHeight: CGFloat = 100
    var maxHeight: CGFloat = 200
    var errorMessage: String? = nil
    var helperText: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .bodyMedium(color: Color.Text.tertiary)
                        .padding(.top, 8)
                        .padding(.leading, 4)
                }

                TextEditor(text: $text)
                    .bodyMedium()
                    .frame(minHeight: minHeight, maxHeight: maxHeight)
                    .scrollContentBackground(.hidden)
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

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .caption(color: Color.Status.error)
            } else if let helperText = helperText {
                Text(helperText)
                    .caption(color: Color.Text.secondary)
            }
        }
    }
}

// MARK: - Search Field
struct DSSearchField: View {
    let placeholder: String
    @Binding var text: String
    var onSubmit: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color.Text.secondary)
                .font(.system(size: Spacing.iconMedium))

            TextField(placeholder, text: $text)
                .bodyMedium()
                .onSubmit {
                    onSubmit?()
                }

            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color.Text.secondary)
                        .font(.system(size: Spacing.iconMedium))
                }
            }
        }
        .padding(Spacing.inputPadding)
        .background(Color.Background.secondary)
        .cornerRadiusMedium()
    }
}

// MARK: - Form Field with Label
struct DSFormField<Content: View>: View {
    let label: String
    let isRequired: Bool
    let content: Content

    init(
        label: String,
        isRequired: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.label = label
        self.isRequired = isRequired
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: 4) {
                Text(label)
                    .labelMedium()

                if isRequired {
                    Text("*")
                        .foregroundColor(Color.Status.error)
                        .labelMedium()
                }
            }

            content
        }
    }
}

// MARK: - Toggle Switch
struct DSToggle: View {
    let label: String
    @Binding var isOn: Bool
    var subtitle: String? = nil

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(label)
                    .labelMedium()

                if let subtitle = subtitle {
                    Text(subtitle)
                        .caption(color: Color.Text.secondary)
                }
            }
        }
        .tint(Color.Brand.primary)
    }
}

// MARK: - Checkbox
struct DSCheckbox: View {
    let label: String
    @Binding var isChecked: Bool
    var subtitle: String? = nil

    var body: some View {
        Button(action: { isChecked.toggle() }) {
            HStack(spacing: Spacing.md) {
                Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                    .foregroundColor(isChecked ? Color.Brand.primary : Color.Text.secondary)
                    .font(.system(size: Spacing.iconMedium))

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(label)
                        .labelMedium(color: Color.Text.primary)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .caption(color: Color.Text.secondary)
                    }
                }

                Spacer()
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Radio Button
struct DSRadioButton: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void
    var subtitle: String? = nil

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                ZStack {
                    Circle()
                        .stroke(
                            isSelected ? Color.Brand.primary : Color.Text.secondary,
                            lineWidth: 2
                        )
                        .frame(width: 20, height: 20)

                    if isSelected {
                        Circle()
                            .fill(Color.Brand.primary)
                            .frame(width: 12, height: 12)
                    }
                }

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(label)
                        .labelMedium(color: Color.Text.primary)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .caption(color: Color.Text.secondary)
                    }
                }

                Spacer()
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Chip/Tag Input
struct DSChip: View {
    let text: String
    var onDelete: (() -> Void)? = nil
    var color: Color = Color.Brand.primary

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Text(text)
                .caption(color: color)

            if let onDelete = onDelete {
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(color.opacity(0.7))
                }
            }
        }
        .paddingSM()
        .background(color.opacity(0.1))
        .cornerRadiusSmall()
    }
}
