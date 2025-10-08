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
            VStack(spacing: 0) {
                // Language Switcher
                languageSwitcher
                
                // Hero Section (Compact)
                heroSection
                
                // Features Section (Compact)
                featuresSection
                
                // Auth Section
                authSection
                
                Spacer()
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.backgroundPrimary,
                        Color.backgroundSecondary.opacity(0.3)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .navigationBarHidden(true)
        .environment(\.layoutDirection, localizationManager.currentLanguage == .arabic ? .rightToLeft : .leftToRight)
        .sheet(isPresented: $showingSignUp) {
            SignUpView()
        }
        .sheet(isPresented: $showingLogin) {
            LoginView()
        }
    }
    
    // MARK: - Language Switcher
    private var languageSwitcher: some View {
        HStack {
            Spacer()
            
            Button(action: {
                localizationManager.toggleLanguage()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "globe")
                        .font(.system(size: 14, weight: .medium))
                    
                    Text(localizationManager.currentLanguage == .arabic ? "العربية" : "English")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(Color.accentGreen)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.accentGreen.opacity(0.1))
                        .overlay(
                            Capsule()
                                .stroke(Color.accentGreen.opacity(0.3), lineWidth: 1)
                        )
                )
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 10)
    }
    
    // MARK: - Hero Section (Compact)
    private var heroSection: some View {
        VStack(spacing: 16) {
            // App Icon (Smaller)
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.accentGreen.opacity(0.2),
                                Color.accentGreen.opacity(0.05)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(Color.accentGreen)
            }
            .padding(.top, 40)
            
            // Main Title (Compact)
            VStack(spacing: 8) {
                Text(localizationManager.currentLanguage == .arabic ? "مرحباً بك في" : "Welcome to")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color.textSecondary)
                
                Text("Synapse")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(Color.textPrimary)
                    .overlay(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.accentGreen,
                                Color.accentGreen.opacity(0.7)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .mask(
                            Text("Synapse")
                                .font(.system(size: 36, weight: .bold))
                        )
                    )
            }
            
            // Subtitle (Shorter)
            Text(localizationManager.currentLanguage == .arabic ? 
                 "حول أفكارك إلى واقع من خلال التعاون" : 
                 "Transform ideas into reality through collaboration")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .lineLimit(2)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
    }
    
    // MARK: - Features Section (Compact)
    private var featuresSection: some View {
        VStack(spacing: 16) {
            // Section Title (Smaller)
            Text(localizationManager.currentLanguage == .arabic ? "لماذا تختار سينابس؟" : "Why Choose Synapse?")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color.textPrimary)
                .padding(.horizontal, 24)
            
            // Features Row (2 features only) - Equal width
            HStack(spacing: 16) {
                CompactFeatureCard(
                    icon: "lightbulb.fill",
                    title: localizationManager.currentLanguage == .arabic ? "شارك الأفكار" : "Share Ideas",
                    description: localizationManager.currentLanguage == .arabic ? "حول الأفكار إلى مشاريع" : "Turn thoughts into projects"
                )
                .frame(maxWidth: .infinity)
                
                CompactFeatureCard(
                    icon: "person.3.fill",
                    title: localizationManager.currentLanguage == .arabic ? "بناء الفرق" : "Build Teams",
                    description: localizationManager.currentLanguage == .arabic ? "تعاون مع المبدعين" : "Collaborate with innovators"
                )
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 24)
        }
        .padding(.bottom, 20)
    }
    
    // MARK: - Auth Section (Compact)
    private var authSection: some View {
        VStack(spacing: 16) {
            // Section Title (Smaller)
            Text(localizationManager.currentLanguage == .arabic ? "ابدأ اليوم" : "Get Started Today")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color.textPrimary)
                .padding(.horizontal, 24)
            
            VStack(spacing: 12) {
                // Google button
                GoogleSignInButton()
                
                // Divider
                orDivider
                
                // Primary CTA
                Button(localizationManager.currentLanguage == .arabic ? "إنشاء حساب" : "Create Account") {
                    showingSignUp = true
                }
                .buttonStyle(PrimaryButtonStyle())
                
                // Secondary CTA
                Button(localizationManager.currentLanguage == .arabic ? "تسجيل الدخول" : "Sign In") {
                    showingLogin = true
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            .padding(.horizontal, 24)
        }
        .padding(.bottom, 20)
    }

    // Simple divider
    private var orDivider: some View {
        HStack {
            Rectangle()
                .fill(Color.textSecondary.opacity(0.3))
                .frame(height: 1)
            Text(localizationManager.currentLanguage == .arabic ? "أو" : "or")
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

// MARK: - Supporting Components

struct CompactFeatureCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 8) {
            // Icon (Smaller)
            ZStack {
                Circle()
                    .fill(Color.accentGreen.opacity(0.1))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color.accentGreen)
            }
            
            // Title (Smaller)
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color.textPrimary)
                .multilineTextAlignment(.center)
            
            // Description (Shorter)
            Text(description)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.backgroundSecondary.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.accentGreen.opacity(0.2), lineWidth: 1)
                )
        )
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
    @State private var showSuccessAlert = false
    @State private var showOtpVerification = false
    @State private var showError = false
    @State private var errorMessage = ""
    
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
        .sheet(isPresented: $showOtpVerification) {
            OtpVerificationView(email: email, username: username)
        }
        .alert("Sign Up Error", isPresented: $showError) {
            Button("OK") {
                showError = false
            }
        } message: {
            Text(errorMessage)
        }
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
        
        // Allow any Unicode letters or numbers, plus underscore and dot; disallow spaces
        let allowed: (Character) -> Bool = { ch in
            ch.isLetter || ch.isNumber || ch == "_" || ch == "."
        }
        if !username.unicodeScalars.reduce(true, { acc, _ in acc }) {
            // noop to keep compiler happy if optimizer folds closures
        }
        if !username.allSatisfy(allowed) {
            usernameError = "Username can contain letters (any language), numbers, underscores, and dots".localized
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

                await MainActor.run {
                    self.isSubmitting = false
                    // Always show OTP verification screen after successful account creation
                    self.showOtpVerification = true
                }

            } catch {
                print("❌ SignUpView: Account creation failed - \(error.localizedDescription)")
                await MainActor.run {
                    self.isSubmitting = false
                    self.errorMessage = supabaseManager.authError ?? error.localizedDescription
                    self.showError = true
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
    @State private var showError = false
    @State private var errorMessage = ""

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
        .alert("Sign In Error", isPresented: $showError) {
            Button("OK") {
                showError = false
            }
        } message: {
            Text(errorMessage)
        }
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

        Task {
            await MainActor.run {
                isSubmitting = true
            }

            do {
                print("🚀 LoginView: Signing in user: \(email)")
                try await supabaseManager.signIn(email: email, password: password)
                print("✅ LoginView: Sign in successful - email verified")

                await MainActor.run {
                    self.isSubmitting = false
                    dismiss()
                }

            } catch let error as AuthError where error == .emailNotVerified {
                print("⚠️ LoginView: Email not verified")
                await MainActor.run {
                    self.isSubmitting = false
                    self.errorMessage = "Please verify your email before signing in. Check your inbox for the verification code."
                    self.showError = true
                }
                // Don't dismiss - let user stay on login screen to see the error
            } catch {
                print("❌ LoginView: Sign in failed - \(error.localizedDescription)")
                await MainActor.run {
                    self.isSubmitting = false
                    self.errorMessage = error.localizedDescription
                    self.showError = true
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
    let username: String
    @State private var otpCode = ""
    @State private var isSubmitting = false
    @State private var errorMessage = ""
    
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
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Verification Code".localized)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.textPrimary)

                Spacer()

                // Paste button
                Button(action: pasteOTP) {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.on.clipboard")
                            .font(.system(size: 14))
                        Text("Paste")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(Color.accentGreen)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.accentGreen.opacity(0.1))
                    )
                }
            }

            // 4-digit OTP input with individual boxes and auto-focus
            OTPInputView(otpCode: $otpCode)
                .padding(.horizontal, 20)

            // Error message
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(Color.error)
                    .padding(.top, 4)
            }
        }
    }
    
    // Helper functions for OTP handling
    private func otpDigit(at index: Int) -> String {
        guard index < otpCode.count else { return "" }
        let digitIndex = otpCode.index(otpCode.startIndex, offsetBy: index)
        return String(otpCode[digitIndex])
    }
    
    private func updateOtpCode(at index: Int, with digit: String) {
        var codeArray = Array(otpCode)
        
        // Ensure array is long enough
        while codeArray.count <= index {
            codeArray.append(" ")
        }
        
        // Update the digit
        if digit.isEmpty {
            // Remove digit (backspace)
            if index < codeArray.count {
                codeArray[index] = " "
            }
        } else {
            // Add/replace digit
            codeArray[index] = Character(digit)
        }
        
        // Convert back to string and clean up
        otpCode = String(codeArray).replacingOccurrences(of: " ", with: "")

        // Limit to 4 digits
        if otpCode.count > 4 {
            otpCode = String(otpCode.prefix(4))
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
                    .fill(otpCode.count == 4 && !isSubmitting ? Color.accentGreen : Color.gray.opacity(0.3))
            )
        }
        .disabled(otpCode.count != 4 || isSubmitting)
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
        errorMessage = ""

        Task {
            do {
                try await supabaseManager.verifyOtp(email: email, otp: otpCode, username: username)
                await MainActor.run {
                    self.isSubmitting = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    self.isSubmitting = false
                    self.errorMessage = "Invalid verification code. Please check and try again."
                    // Clear OTP for retry
                    self.otpCode = ""
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

    private func pasteOTP() {
        #if os(iOS)
        if let clipboardContent = UIPasteboard.general.string {
            // Extract only digits and take first 4
            let digits = clipboardContent.filter { $0.isNumber }
            otpCode = String(digits.prefix(4))
        }
        #endif
    }
}

// MARK: - Email Verification Required View
struct EmailVerificationRequiredView: View {
    @EnvironmentObject private var supabaseManager: SupabaseManager
    @EnvironmentObject private var localizationManager: LocalizationManager
    @State private var otpCode = ""
    @State private var isSubmitting = false
    @State private var errorMessage = ""

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
            Image(systemName: "envelope.badge")
                .font(.system(size: 64))
                .foregroundColor(Color.accentGreen)
                .padding(.top, 60)

            Text("Verify Your Email".localized)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Color.textPrimary)

            Text("You did not verify your account yet. Please enter the verification code sent to \(supabaseManager.currentUser?.email ?? "your email")")
                .font(.system(size: 16))
                .foregroundColor(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private var otpSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Verification Code".localized)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.textPrimary)

                Spacer()

                // Paste button
                Button(action: pasteOTP) {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.on.clipboard")
                            .font(.system(size: 14))
                        Text("Paste")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(Color.accentGreen)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.accentGreen.opacity(0.1))
                    )
                }
            }

            // 4-digit OTP input with auto-focus
            OTPInputView(otpCode: $otpCode)
                .padding(.horizontal, 20)

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(Color.error)
            }
        }
    }

    private func otpDigit(at index: Int) -> String {
        guard index < otpCode.count else { return "" }
        let digitIndex = otpCode.index(otpCode.startIndex, offsetBy: index)
        return String(otpCode[digitIndex])
    }

    private func updateOtpCode(at index: Int, with digit: String) {
        var codeArray = Array(otpCode)

        while codeArray.count <= index {
            codeArray.append(" ")
        }

        if digit.isEmpty {
            if index < codeArray.count {
                codeArray[index] = " "
            }
        } else {
            codeArray[index] = Character(digit)
        }

        otpCode = String(codeArray).replacingOccurrences(of: " ", with: "")

        if otpCode.count > 4 {
            otpCode = String(otpCode.prefix(4))
        }
    }

    private var actionSection: some View {
        VStack(spacing: 16) {
            verifyButton
            resendButton
            signOutButton
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
                    .fill(otpCode.count == 4 && !isSubmitting ? Color.accentGreen : Color.gray.opacity(0.3))
            )
        }
        .disabled(otpCode.count != 4 || isSubmitting)
    }

    private var resendButton: some View {
        Button("Resend Code".localized) {
            resendOTP()
        }
        .foregroundColor(Color.accentGreen)
        .fontWeight(.medium)
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

    private func verifyOTP() {
        guard !otpCode.isEmpty, let email = supabaseManager.currentUser?.email else { return }

        isSubmitting = true
        errorMessage = ""

        Task {
            do {
                try await supabaseManager.verifyOtp(email: email, otp: otpCode)
                await MainActor.run {
                    self.isSubmitting = false
                }
            } catch {
                await MainActor.run {
                    self.isSubmitting = false
                    self.errorMessage = "Invalid verification code. Please try again."
                }
            }
        }
    }

    private func resendOTP() {
        guard let email = supabaseManager.currentUser?.email else { return }

        Task {
            do {
                try await supabaseManager.resendOtp(email: email)
                await MainActor.run {
                    self.errorMessage = ""
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to resend code. Please try again."
                }
            }
        }
    }

    private func signOut() async {
        do {
            try await supabaseManager.signOut()
        } catch {
            print("Error signing out: \(error)")
        }
    }

    private func pasteOTP() {
        #if os(iOS)
        if let clipboardContent = UIPasteboard.general.string {
            // Extract only digits and take first 4
            let digits = clipboardContent.filter { $0.isNumber }
            otpCode = String(digits.prefix(4))
        }
        #endif
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
            .contentShape(Rectangle()) // This ensures the entire frame is clickable
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

// MARK: - OTP Input View with Auto-Focus
struct OTPInputView: View {
    @Binding var otpCode: String
    @FocusState private var focusedField: Int?
    @State private var digits: [String] = ["", "", "", ""]

    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<4, id: \.self) { index in
                TextField("", text: Binding(
                    get: { digits[index] },
                    set: { newValue in
                        handleDigitChange(at: index, newValue: newValue)
                    }
                ))
                .multilineTextAlignment(.center)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(Color.textPrimary)
                .frame(width: 50, height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(focusedField == index ? Color.accentGreen : Color.border, lineWidth: 2)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.backgroundSecondary)
                        )
                )
                .keyboardType(.numberPad)
                .focused($focusedField, equals: index)
                .onChange(of: digits[index]) { oldValue, newValue in
                    // Auto-advance to next field
                    if !newValue.isEmpty && index < 3 {
                        focusedField = index + 1
                    }
                }
            }
        }
        .onAppear {
            // Auto-focus first field
            focusedField = 0
        }
        .onChange(of: otpCode) { oldValue, newValue in
            // Update digits when otpCode changes (e.g., from paste)
            updateDigitsFromCode(newValue)
        }
    }

    private func handleDigitChange(at index: Int, newValue: String) {
        let filtered = newValue.filter { $0.isNumber }

        if filtered.isEmpty {
            // Backspace - move to previous field
            digits[index] = ""
            if index > 0 {
                focusedField = index - 1
            }
        } else {
            // Take only first digit
            digits[index] = String(filtered.prefix(1))
        }

        // Update the bound otpCode
        otpCode = digits.joined()
    }

    private func updateDigitsFromCode(_ code: String) {
        let chars = Array(code)
        for i in 0..<4 {
            digits[i] = i < chars.count ? String(chars[i]) : ""
        }
        // Focus on next empty field or last field
        if code.count < 4 {
            focusedField = code.count
        }
    }
}

// MARK: - OTP Digit Field Component
struct OTPDigitField: View {
    let digit: String
    let onDigitChange: (String) -> Void
    @State private var text: String = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        TextField("", text: $text)
            .multilineTextAlignment(.center)
            .font(.system(size: 24, weight: .semibold))
            .foregroundColor(Color.textPrimary)
            .frame(width: 50, height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isFocused ? Color.accentGreen : Color.border, lineWidth: 2)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.backgroundSecondary)
                    )
            )
            .keyboardType(.numberPad)
            .focused($isFocused)
            .onChange(of: text) { _, newValue in
                // Only allow single digits
                let filtered = newValue.filter { $0.isNumber }
                if filtered.count <= 1 {
                    text = filtered
                    onDigitChange(filtered)
                    
                    // Auto-focus next field if digit entered
                    if !filtered.isEmpty {
                        // Move focus to next field (handled by parent)
                    }
                } else {
                    text = String(filtered.prefix(1))
                    onDigitChange(text)
                }
            }
            .onAppear {
                text = digit
            }
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

