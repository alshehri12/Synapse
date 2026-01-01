//
//  ResetPasswordView.swift
//  Synapse
//
//  Created for password reset via deep link
//

import SwiftUI

struct ResetPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var supabaseManager: SupabaseManager
    @EnvironmentObject private var localizationManager: LocalizationManager

    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSuccess = false

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.backgroundPrimary
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 12) {
                            Image(systemName: "lock.rotation")
                                .font(.system(size: 60))
                                .foregroundColor(.accentGreen)

                            Text("Reset Your Password")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.textPrimary)

                            Text("Enter your new password below")
                                .font(.subheadline)
                                .foregroundColor(.textSecondary)
                        }
                        .padding(.top, 40)

                        // Password Fields
                        VStack(spacing: 16) {
                            // New Password
                            VStack(alignment: .leading, spacing: 8) {
                                Text("New Password")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.textPrimary)

                                SecureField("Enter new password", text: $newPassword)
                                    .textFieldStyle(RoundedTextFieldStyle())
                                    .textContentType(.newPassword)
                                    .autocapitalization(.none)
                            }

                            // Confirm Password
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Confirm Password")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.textPrimary)

                                SecureField("Confirm new password", text: $confirmPassword)
                                    .textFieldStyle(RoundedTextFieldStyle())
                                    .textContentType(.newPassword)
                                    .autocapitalization(.none)
                            }

                            // Password Requirements
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Password must:")
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)

                                PasswordRequirement(
                                    text: "Be at least 6 characters",
                                    isMet: newPassword.count >= 6
                                )

                                PasswordRequirement(
                                    text: "Match confirmation",
                                    isMet: !newPassword.isEmpty && newPassword == confirmPassword
                                )
                            }
                            .padding(.top, 8)
                        }
                        .padding(.horizontal, 24)

                        // Error Message
                        if let errorMessage = errorMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                Text(errorMessage)
                                    .font(.subheadline)
                            }
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(12)
                            .padding(.horizontal, 24)
                        }

                        // Reset Button
                        Button(action: handleResetPassword) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Reset Password")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            isFormValid
                                ? Color.accentGreen
                                : Color.gray.opacity(0.3)
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.horizontal, 24)
                        .disabled(!isFormValid || isLoading)

                        Spacer()
                    }
                }

                // Success Overlay
                if showSuccess {
                    SuccessAlertView(
                        title: "Password Reset!",
                        message: "Your password has been successfully updated. You can now sign in with your new password.",
                        onDismiss: {
                            showSuccess = false
                            dismiss()
                        }
                    )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.textSecondary)
                    }
                }
            }
        }
    }

    private var isFormValid: Bool {
        !newPassword.isEmpty &&
        newPassword.count >= 6 &&
        newPassword == confirmPassword
    }

    private func handleResetPassword() {
        errorMessage = nil
        isLoading = true

        Task {
            do {
                try await supabaseManager.updatePassword(newPassword: newPassword)

                await MainActor.run {
                    isLoading = false
                    showSuccess = true
                }

                // Dismiss after showing success
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

struct PasswordRequirement: View {
    let text: String
    let isMet: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: isMet ? "checkmark.circle.fill" : "circle")
                .font(.caption)
                .foregroundColor(isMet ? .green : .gray)

            Text(text)
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
    }
}

// Text field style
struct RoundedTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.backgroundSecondary)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
    }
}

#Preview {
    ResetPasswordView()
        .environmentObject(SupabaseManager.shared)
        .environmentObject(LocalizationManager.shared)
}
