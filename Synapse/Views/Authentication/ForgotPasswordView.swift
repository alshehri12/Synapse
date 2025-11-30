//
//  ForgotPasswordView.swift
//  Synapse
//
//  Forgot password flow for password reset
//

import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var supabaseManager: SupabaseManager
    @EnvironmentObject private var localizationManager: LocalizationManager

    @State private var email: String = ""
    @State private var isLoading: Bool = false
    @State private var showSuccess: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Spacing.xl2) {
                    // Header
                    VStack(spacing: Spacing.md) {
                        Image(systemName: "lock.rotation")
                            .font(.system(size: 64))
                            .foregroundColor(Color.Brand.primary)
                            .paddingXL()

                        Text("Forgot Password?".localized)
                            .heading2()

                        Text("Enter your email address and we'll send you a link to reset your password.".localized)
                            .bodyMedium(color: Color.Text.secondary)
                            .multilineTextAlignment(.center)
                            .paddingLG()
                    }
                    .paddingXL()

                    // Email Input
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        DSTextField(
                            placeholder: "Email".localized,
                            text: $email,
                            icon: "envelope",
                            errorMessage: errorMessage,
                            helperText: nil
                        )
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                    }
                    .paddingLG()

                    // Send Reset Link Button
                    PrimaryButton(
                        title: "Send Reset Link".localized,
                        action: sendResetLink,
                        icon: "paperplane.fill",
                        isLoading: isLoading,
                        isDisabled: email.isEmpty
                    )
                    .paddingLG()

                    Spacer()
                }
                .padding(Spacing.screenPadding)
            }
            .background(Color.white)
            .navigationTitle("Reset Password".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(Color.Text.primary)
                    }
                }
            }
            .alert("Check Your Email".localized, isPresented: $showSuccess) {
                Button("OK".localized) {
                    dismiss()
                }
            } message: {
                Text("If an account exists with that email, you'll receive a password reset link shortly.".localized)
            }
        }
    }

    private func sendResetLink() {
        errorMessage = nil
        isLoading = true

        Task {
            do {
                try await supabaseManager.resetPassword(email: email)
                await MainActor.run {
                    isLoading = false
                    showSuccess = true
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

#Preview {
    ForgotPasswordView()
        .environmentObject(LocalizationManager.shared)
        .environmentObject(SupabaseManager.shared)
}
