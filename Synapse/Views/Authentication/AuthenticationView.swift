//
//  AuthenticationView.swift
//  Synapse
//
//  Created by AI Assistant on 2024-12-19.
//

import SwiftUI

// MARK: - Main Authentication View
struct AuthenticationView: View {
    @EnvironmentObject private var supabaseManager: SupabaseManager
    @EnvironmentObject private var localizationManager: LocalizationManager
    @State private var showingSignUp = false
    @State private var showingLogin = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                headerSection
                authOptionsSection
                Spacer()
            }
            .padding(.horizontal, 24)
            .background(Color.backgroundPrimary)
        }
        .navigationBarHidden(true)
            .sheet(isPresented: $showingSignUp) {
                SignUpView()
            }
            .sheet(isPresented: $showingLogin) {
                LoginView()
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Icon
            Image(systemName: "sparkles")
                .font(.system(size: 80))
                .foregroundColor(Color.accentGreen)
            
            // Title
            Text("Welcome to Synapse")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(Color.textPrimary)
            
            // Subtitle
            Text("Connect, collaborate, and bring your ideas to life")
                .font(.system(size: 16))
                .foregroundColor(Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.top, 60)
    }
    
    private var authOptionsSection: some View {
        VStack(spacing: 16) {
            // Google button (UI only for now)
            GoogleSignInButton()
            
            // Divider
            orDivider
            
            Button("Create Account") {
                showingSignUp = true
            }
            .buttonStyle(PrimaryButtonStyle())
            
            Button("Sign In") {
                showingLogin = true
            }
            .buttonStyle(SecondaryButtonStyle())
        }
    }

    // Simple divider
    private var orDivider: some View {
        HStack {
            Rectangle()
                .fill(Color.textSecondary.opacity(0.3))
                .frame(height: 1)
            Text("or".localized)
                .font(.system(size: 14))
                .foregroundColor(Color.textSecondary)
                .padding(.horizontal, 16)
            Rectangle()
                .fill(Color.textSecondary.opacity(0.3))
                .frame(height: 1)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Sign Up View
struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var supabaseManager: SupabaseManager
    @EnvironmentObject private var localizationManager: LocalizationManager
    
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isSubmitting = false
    @State private var usernameError = ""
    @State private var isCheckingUsername = false
    
    var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && !username.isEmpty &&
        password == confirmPassword && password.count >= 6 &&
        email.contains("@") && usernameError.isEmpty
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    formSection
                    actionSection
                }
                .padding(.bottom, 50)
            }
            .background(Color.backgroundPrimary)
        }
        .navigationBarHidden(true)
    }
    
    private var headerSection: some View {
        VStack(spacing: 24) {
                    HStack {
                        Button("Cancel".localized, action: { dismiss() })
                            .foregroundColor(Color.textSecondary)
                        
                        Spacer()
                        
                        LanguageSwitcher()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    VStack(spacing: 8) {
                        Text("Create Account".localized)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color.textPrimary)
                        
                        Text("Join the Synapse community".localized)
                            .font(.system(size: 16))
                            .foregroundColor(Color.textSecondary)
                    }
                    .padding(.top, 20)
        }
    }
                    
    private var formSection: some View {
                    VStack(spacing: 16) {
            usernameField
            emailField
            passwordField
            confirmPasswordField
        }
        .padding(.horizontal, 24)
    }
    
    private var usernameField: some View {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Username".localized)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color.textPrimary)
                            
                            HStack {
                                TextField("Enter username".localized, text: $username)
                                    .textFieldStyle(CustomTextFieldStyle())
                                                                    .onChange(of: username) { _, newValue in
                                    validateUsername(newValue)
                                }
                                
                                if isCheckingUsername {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: Color.accentGreen))
                                        .scaleEffect(0.8)
                                }
                            }
                            
                            if !usernameError.isEmpty {
                                Text(usernameError)
                    .font(.caption)
                                    .foregroundColor(Color.error)
            }
                            }
                        }
                        
    private var emailField: some View {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email".localized)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color.textPrimary)
                            
                            TextField("Enter email".localized, text: $email)
                                .textFieldStyle(CustomTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
        }
                        }
                        
    private var passwordField: some View {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password".localized)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color.textPrimary)
                            
                            SecureField("Enter password".localized, text: $password)
                                .textFieldStyle(CustomTextFieldStyle())
        }
                        }
                        
    private var confirmPasswordField: some View {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password".localized)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color.textPrimary)
                            
                            SecureField("Confirm password".localized, text: $confirmPassword)
                                .textFieldStyle(CustomTextFieldStyle())
                        
                        if !confirmPassword.isEmpty && password != confirmPassword {
                Text("Passwords do not match".localized)
                    .font(.caption)
                                .foregroundColor(Color.error)
                        }
                    }
    }
    
    private var actionSection: some View {
        VStack(spacing: 16) {
            signUpButton
            loginPrompt
        }
        .padding(.horizontal, 24)
    }
    
    private var signUpButton: some View {
                    Button(action: signUp) {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                    Text("Create Account".localized)
                        .fontWeight(.semibold)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isFormValid && !isSubmitting ? Color.accentGreen : Color.gray.opacity(0.3))
            )
                    }
                    .disabled(!isFormValid || isSubmitting)
        .padding(.top, 8)
    }
    
    private var loginPrompt: some View {
        HStack {
            Text("Already have an account?".localized)
                .foregroundColor(Color.textSecondary)
            
            Button("Sign In".localized) {
                dismiss()
            }
            .foregroundColor(Color.accentGreen)
            .fontWeight(.medium)
        }
        .font(.system(size: 14))
        .padding(.top, 16)
    }
    
    private func validateUsername(_ username: String) {
        guard !username.isEmpty else {
            usernameError = ""
            return
        }
        
        // Basic validation
        if username.count < 3 {
            usernameError = "Username must be at least 3 characters".localized
            return
        }
        
        if !username.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "_" }) {
            usernameError = "Username can only contain letters, numbers, and underscores".localized
            return
        }
        
        // Check availability
        isCheckingUsername = true
        usernameError = ""
        
        Task {
            do {
                let isAvailable = try await supabaseManager.validateUsername(username)
                await MainActor.run {
                    isCheckingUsername = false
                    if !isAvailable {
                        usernameError = "Username is already taken".localized
                    }
                }
            } catch {
                await MainActor.run {
                    isCheckingUsername = false
                    usernameError = "Error checking username availability".localized
                }
            }
        }
    }
    
    private func signUp() {
        guard isFormValid else { return }
        
        isSubmitting = true
        
        Task {
            do {
                print("🚀 SignUpView: Creating account for: \(email)")
                try await supabaseManager.signUp(email: email, password: password, username: username)
                print("✅ SignUpView: Account created successfully")
                
                DispatchQueue.main.async {
                    self.isSubmitting = false
                    dismiss()
                }
                
            } catch {
                print("❌ SignUpView: Account creation failed - \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isSubmitting = false
                }
            }
        }
    }
}

// MARK: - Login View
struct LoginView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var supabaseManager: SupabaseManager
    @EnvironmentObject private var localizationManager: LocalizationManager
    @State private var email = ""
    @State private var password = ""
    @State private var isSubmitting = false
    
    var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && email.contains("@")
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    formSection
                    actionSection
                }
                .padding(.bottom, 50)
            }
            .background(Color.backgroundPrimary)
        }
        .navigationBarHidden(true)
    }
    
    private var headerSection: some View {
        VStack(spacing: 24) {
                    HStack {
                        Button("Cancel".localized, action: { dismiss() })
                            .foregroundColor(Color.textSecondary)
                        
                        Spacer()
                        
                        LanguageSwitcher()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    VStack(spacing: 8) {
                        Text("Welcome Back".localized)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color.textPrimary)
                        
                        Text("Sign in to your account".localized)
                            .font(.system(size: 16))
                            .foregroundColor(Color.textSecondary)
                    }
                    .padding(.top, 20)
        }
    }
                    
    private var formSection: some View {
                    VStack(spacing: 16) {
            emailField
            passwordField
        }
        .padding(.horizontal, 24)
    }
    
    private var emailField: some View {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email".localized)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color.textPrimary)
                            
                            TextField("Enter email".localized, text: $email)
                                .textFieldStyle(CustomTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
        }
                        }
                        
    private var passwordField: some View {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password".localized)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color.textPrimary)
                            
                            SecureField("Enter password".localized, text: $password)
                                .textFieldStyle(CustomTextFieldStyle())
                        }
                    }
    
    private var actionSection: some View {
        VStack(spacing: 16) {
            signInButton
            signUpPrompt
        }
        .padding(.horizontal, 24)
    }
    
    private var signInButton: some View {
                    Button(action: signIn) {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                    Text("Sign In".localized)
                        .fontWeight(.semibold)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isFormValid && !isSubmitting ? Color.accentGreen : Color.gray.opacity(0.3))
            )
                    }
                    .disabled(!isFormValid || isSubmitting)
        .padding(.top, 8)
    }
    
    private var signUpPrompt: some View {
        HStack {
            Text("Don't have an account?".localized)
                .foregroundColor(Color.textSecondary)
            
            Button("Sign Up".localized) {
                    dismiss()
                }
            .foregroundColor(Color.accentGreen)
            .fontWeight(.medium)
            }
        .font(.system(size: 14))
        .padding(.top, 16)
    }
    
    private func signIn() {
        guard isFormValid else { return }
        
        isSubmitting = true
        
        Task {
            do {
                print("🚀 LoginView: Signing in user: \(email)")
                try await supabaseManager.signIn(email: email, password: password)
                print("✅ LoginView: Sign in successful")
                
                DispatchQueue.main.async {
                    self.isSubmitting = false
                    dismiss()
                }
                
            } catch {
                print("❌ LoginView: Sign in failed - \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isSubmitting = false
                }
            }
        }
    }
}

// MARK: - OTP Verification View
struct OtpVerificationView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var supabaseManager: SupabaseManager
    @EnvironmentObject private var localizationManager: LocalizationManager
    
    let email: String
    @State private var otpCode = ""
    @State private var isSubmitting = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                headerSection
                otpSection
                actionSection
                Spacer()
            }
            .padding(.horizontal, 24)
            .background(Color.backgroundPrimary)
        }
        .navigationBarHidden(true)
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
                    Text("Verify Your Email".localized)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Color.textPrimary)
                    
            Text("Enter the verification code sent to \(email)")
                .font(.system(size: 16))
                        .foregroundColor(Color.textSecondary)
                        .multilineTextAlignment(.center)
        }
        .padding(.top, 60)
    }
    
    private var otpSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Verification Code".localized)
                .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.textPrimary)
            
            TextField("Enter code".localized, text: $otpCode)
                .textFieldStyle(CustomTextFieldStyle())
                .keyboardType(.numberPad)
        }
    }
    
    private var actionSection: some View {
        VStack(spacing: 16) {
            verifyButton
            resendButton
        }
    }
    
    private var verifyButton: some View {
        Button(action: verifyOTP) {
                            HStack {
                if isSubmitting {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                    Text("Verify".localized)
                                        .fontWeight(.semibold)
                                }
                            }
                            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(!otpCode.isEmpty && !isSubmitting ? Color.accentGreen : Color.gray.opacity(0.3))
            )
        }
        .disabled(otpCode.isEmpty || isSubmitting)
    }
    
    private var resendButton: some View {
        Button("Resend Code".localized) {
            resendOTP()
                            }
                            .foregroundColor(Color.accentGreen)
                        .fontWeight(.medium)
    }
    
    private func verifyOTP() {
        guard !otpCode.isEmpty else { return }
        
        isSubmitting = true
        
        Task {
            do {
                try await supabaseManager.verifyOtp(email: email, otp: otpCode)
                DispatchQueue.main.async {
                    self.isSubmitting = false
                    dismiss()
                }
            } catch {
                DispatchQueue.main.async {
                    self.isSubmitting = false
                }
            }
        }
    }
    
    private func resendOTP() {
        Task {
            do {
                try await supabaseManager.resendOtp(email: email)
            } catch {
                print("❌ Failed to resend OTP: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Email Verification Required View
struct EmailVerificationRequiredView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var supabaseManager: SupabaseManager
    @EnvironmentObject private var localizationManager: LocalizationManager
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                headerSection
                actionSection
                Spacer()
            }
            .padding(.horizontal, 24)
        .background(Color.backgroundPrimary)
        }
        .navigationBarHidden(true)
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "envelope.badge")
                .font(.system(size: 64))
                .foregroundColor(Color.accentGreen)
            
            Text("Check Your Email".localized)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Color.textPrimary)
            
            Text("We've sent a verification link to your email address. Please check your email and click the link to verify your account.")
                .font(.system(size: 16))
                .foregroundColor(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 60)
    }
    
    private var actionSection: some View {
        VStack(spacing: 16) {
            Button("I've Verified My Email".localized) {
                Task {
                    try await supabaseManager.reloadCurrentUser()
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            
            signOutButton
        }
    }
    
    private var signOutButton: some View {
        Button {
            Task {
                await signOut()
            }
        } label: {
            Text("Sign Out".localized)
                .fontWeight(.medium)
                .foregroundColor(Color.error)
        }
    }
    
    private func signOut() async {
        do {
            try await supabaseManager.signOut()
            } catch {
            print("Error signing out: \(error)")
        }
    }
}

// MARK: - Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.accentGreen)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(Color.accentGreen)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.accentGreen, lineWidth: 2)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Google Sign-In Button (UI only)
struct GoogleSignInButton: View {
    @EnvironmentObject private var supabaseManager: SupabaseManager
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            isPressed = true
            Task {
                do {
                    try await supabaseManager.signInWithGoogle()
                } catch {
                    print("❌ Google Sign-In failed: \(error.localizedDescription)")
                }
                await MainActor.run { isPressed = false }
            }
        }) {
            HStack(spacing: 12) {
                // Google Logo with gradient
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.95, green: 0.35, blue: 0.15),
                                    Color(red: 0.95, green: 0.65, blue: 0.15)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 28, height: 28)
                        .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 2)
                    Image(systemName: "globe")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
                Text("Continue with Google".localized)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.textPrimary)
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.textSecondary)
                    .opacity(0.7)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.backgroundPrimary)
                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.border, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
    }
}

// MARK: - Language Switcher
struct LanguageSwitcher: View {
    @EnvironmentObject private var localizationManager: LocalizationManager
    
    var body: some View {
        Menu {
            Button("English") {
                localizationManager.setLanguage(.english)
            }
            Button("العربية") {
                localizationManager.setLanguage(.arabic)
            }
        } label: {
            HStack {
                    Image(systemName: "globe")
                Text(localizationManager.currentLanguage == .arabic ? "العربية" : "English")
            }
                    .foregroundColor(Color.textSecondary)
            .font(.system(size: 14))
        }
    }
}

