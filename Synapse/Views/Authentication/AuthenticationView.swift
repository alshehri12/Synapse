//
//  AuthenticationView.swift
//  Synapse
//
//  Created by Abdulrahman Alshehri on 18/01/1447 AH.
//

import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject private var firebaseManager: FirebaseManager
    @EnvironmentObject private var localizationManager: LocalizationManager
    @State private var showingSignUp = false
    @State private var showingLogin = false
    @State private var showingError = false
    @State private var showingSuccess = false
    @State private var showingEmailVerification = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                headerSection
                Spacer()
                actionButtonsSection
                Spacer()
                footerSection
            }
            .padding(.vertical, 40)
            .background(Color.backgroundSecondary)
            .sheet(isPresented: $showingSignUp) {
                SignUpView()
            }
            .sheet(isPresented: $showingLogin) {
                LoginView()
            }
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Language Switcher at the top
            HStack {
                Spacer()
                LanguageSwitcher()
                    .padding(.top, 20)
                    .padding(.trailing, 20)
            }
            
            // Main Header
            appHeaderContent
        }
    }
    
    private var appHeaderContent: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 80))
                .foregroundColor(Color.accentGreen)
            
            Text("Welcome to Synapse".localized)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(Color.textPrimary)
            
            Text("Connect, collaborate, and bring your ideas to life".localized)
                .font(.system(size: 16))
                .foregroundColor(Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            // Custom Google Sign-In Button
            CustomGoogleSignInButton(action: signInWithGoogle)
            
            // Divider
            orDivider
            
            // Sign Up Button
            signUpButton
            
            // Sign In Button
            signInButton
        }
        .padding(.horizontal, 40)
    }
    
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
    
    private var signUpButton: some View {
        Button(action: { showingSignUp = true }) {
            HStack {
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 16, weight: .semibold))
                Text("Create Account".localized)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.accentGreen)
            .cornerRadius(12)
        }
    }
    
    private var signInButton: some View {
        Button(action: { showingLogin = true }) {
            HStack {
                Image(systemName: "person")
                    .font(.system(size: 16, weight: .semibold))
                Text("Sign In".localized)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(Color.accentGreen)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.accentGreen.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.accentGreen, lineWidth: 1)
            )
        }
    }
    

    
    private var footerSection: some View {
        Text("By continuing, you agree to our Terms of Service and Privacy Policy".localized)
            .font(.system(size: 12))
            .foregroundColor(Color.textSecondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 40)
    }
    
    // MARK: - Actions
    

    
    private func signInWithGoogle() {
        Task {
            do {
                print("AuthenticationView: Starting Google Sign-In...")
                try await firebaseManager.signInWithGoogle()
                print("AuthenticationView: Google Sign-In completed successfully")
            } catch {
                print("AuthenticationView: Google Sign-In failed with error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.showingError = true
                }
            }
        }
    }
}

// MARK: - Sign Up View
struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var firebaseManager: FirebaseManager
    @EnvironmentObject private var localizationManager: LocalizationManager
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var username = ""
    @State private var isSubmitting = false
    @State private var showingError = false
    @State private var showingSuccess = false
    @State private var showingEmailVerification = false
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
                    // Language Switcher at the top
                    HStack {
                        Button("Cancel".localized, action: { dismiss() })
                            .foregroundColor(Color.textSecondary)
                        
                        Spacer()
                        
                        LanguageSwitcher()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    // Header
                    VStack(spacing: 8) {
                        Text("Create Account".localized)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color.textPrimary)
                        
                        Text("Join the Synapse community".localized)
                            .font(.system(size: 16))
                            .foregroundColor(Color.textSecondary)
                    }
                    .padding(.top, 20)
                    
                    // Form Fields
                    VStack(spacing: 16) {
                        // Username
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
                                    .font(.system(size: 12))
                                    .foregroundColor(Color.error)
                            }
                        }
                        
                        // Email
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email".localized)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color.textPrimary)
                            
                            TextField("Enter email".localized, text: $email)
                                .textFieldStyle(CustomTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                        }
                        
                        // Password
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password".localized)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color.textPrimary)
                            
                            SecureField("Enter password".localized, text: $password)
                                .textFieldStyle(CustomTextFieldStyle())
                        }
                        
                        // Confirm Password
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password".localized)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color.textPrimary)
                            
                            SecureField("Confirm password".localized, text: $confirmPassword)
                                .textFieldStyle(CustomTextFieldStyle())
                        }
                        
                        if !confirmPassword.isEmpty && password != confirmPassword {
                            Text("Passwords don't match".localized)
                                .font(.system(size: 12))
                                .foregroundColor(Color.error)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Submit Button
                    Button(action: signUp) {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "person.badge.plus")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            
                            Text(isSubmitting ? "Creating Account...".localized : "Create Account".localized)
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(isFormValid && !isSubmitting ? Color.accentGreen : Color.textSecondary.opacity(0.3))
                        .cornerRadius(12)
                    }
                    .disabled(!isFormValid || isSubmitting)
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 40)
            }
            .background(Color.backgroundSecondary)
            .navigationBarHidden(true)
            .sheet(isPresented: $showingEmailVerification) {
                OtpVerificationView(email: email)
            }
            .alert("Error".localized, isPresented: $showingError) {
                Button("OK".localized) {
                    firebaseManager.clearAuthError()
                }
            } message: {
                Text(firebaseManager.authError ?? "An error occurred".localized)
            }
            .onChange(of: firebaseManager.authError) { _, error in
                showingError = error != nil
            }
            // Removed the onChange handler that automatically dismisses the view
            // when a user is signed in, since we now want users to return to login
        }
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
        
        if username.count > 20 {
            usernameError = "Username must be less than 20 characters".localized
            return
        }
        
        // Check for valid characters
        let usernameRegex = "^[a-zA-Z0-9_]+$"
        if username.range(of: usernameRegex, options: .regularExpression) == nil {
            usernameError = "Username can only contain letters, numbers, and underscores".localized
            return
        }
        
        // Check availability in database
        isCheckingUsername = true
        usernameError = ""
        
        Task {
            do {
                let isAvailable = try await firebaseManager.validateUsername(username)
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
                try await firebaseManager.signUp(email: email, password: password, username: username)
                print("✅ SignUpView: Account created successfully")
                // Attempt to send OTP email, then show OTP sheet
                do { try await firebaseManager.sendOtpEmail(email: email) } catch { print("⚠️ OTP send failed: \(error.localizedDescription)") }
                DispatchQueue.main.async {
                    self.isSubmitting = false
                    self.showingEmailVerification = true
                }
                
            } catch {
                print("❌ SignUpView: Account creation failed - \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isSubmitting = false
                }
                // Error is handled by FirebaseManager
            }
        }
    }
}

// MARK: - Login View
struct LoginView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var firebaseManager: FirebaseManager
    @EnvironmentObject private var localizationManager: LocalizationManager
    @State private var email = ""
    @State private var password = ""
    @State private var isSubmitting = false
    @State private var showingError = false
    
    var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Language Switcher at the top
                    HStack {
                        Button("Cancel".localized, action: { dismiss() })
                            .foregroundColor(Color.textSecondary)
                        
                        Spacer()
                        
                        LanguageSwitcher()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    // Header
                    VStack(spacing: 8) {
                        Text("Welcome Back".localized)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color.textPrimary)
                        
                        Text("Sign in to your account".localized)
                            .font(.system(size: 16))
                            .foregroundColor(Color.textSecondary)
                    }
                    .padding(.top, 20)
                    
                    // Form Fields
                    VStack(spacing: 16) {
                        // Email
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email".localized)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color.textPrimary)
                            
                            TextField("Enter email".localized, text: $email)
                                .textFieldStyle(CustomTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                        }
                        
                        // Password
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password".localized)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color.textPrimary)
                            
                            SecureField("Enter password".localized, text: $password)
                                .textFieldStyle(CustomTextFieldStyle())
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Submit Button
                    Button(action: signIn) {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "person")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            
                            Text(isSubmitting ? "Signing In...".localized : "Sign In".localized)
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(isFormValid && !isSubmitting ? Color.accentGreen : Color.textSecondary.opacity(0.3))
                        .cornerRadius(12)
                    }
                    .disabled(!isFormValid || isSubmitting)
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 40)
            }
            .background(Color.backgroundSecondary)
            .navigationBarHidden(true)
            .alert("Sign In Error", isPresented: $showingError) {
                Button("OK") {
                    firebaseManager.clearAuthError()
                    // Stay on login page - don't dismiss
                }
            } message: {
                Text(firebaseManager.authError ?? "An error occurred")
            }
            .onChange(of: firebaseManager.authError) { _, error in
                showingError = error != nil
                // Don't dismiss the view on error
            }
            .onChange(of: firebaseManager.currentUser) { _, user in
                // Only dismiss if user is signed in AND there's no error
                if user != nil && firebaseManager.authError == nil {
                    print("✅ LoginView: User signed in successfully, dismissing view")
                    dismiss()
                }
            }
        }
    }
    
    private func signIn() {
        guard isFormValid else { return }
        
        print("🔐 LoginView: Starting sign-in process for: \(email)")
        isSubmitting = true
        
        Task {
            do {
                try await firebaseManager.signIn(email: email, password: password)
                print("✅ LoginView: Sign-in successful")
                DispatchQueue.main.async {
                    self.isSubmitting = false
                }
            } catch {
                print("❌ LoginView: Sign-in failed with error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isSubmitting = false
                }
                // Error is handled by FirebaseManager
            }
        }
    }
}

// MARK: - OTP Verification View
struct OtpVerificationView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var firebaseManager = FirebaseManager.shared
    @State private var otpCode = ""
    @State private var isVerifying = false
    @State private var isResending = false
    @State private var showingError = false
    @State private var showingSuccess = false
    @State private var email: String
    @State private var timeRemaining = 60
    @State private var canResend = false
    
    init(email: String) {
        self.email = email
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 80))
                        .foregroundColor(Color.accentGreen)
                    
                    Text("Verify Your Email".localized)
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("We've sent a 6-digit verification code to".localized)
                        .font(.body)
                        .foregroundColor(Color.textSecondary)
                        .multilineTextAlignment(.center)
                    
                    Text(email)
                        .font(.headline)
                        .foregroundColor(Color.textPrimary)
                        .fontWeight(.semibold)
                }
                
                // OTP Input
                VStack(spacing: 20) {
                    Text("Enter the 6-digit code".localized)
                        .font(.subheadline)
                        .foregroundColor(Color.textSecondary)
                    
                    HStack(spacing: 12) {
                        ForEach(0..<6, id: \.self) { index in
                            OtpDigitField(
                                index: index,
                                otpCode: $otpCode,
                                isVerifying: isVerifying
                            )
                        }
                    }
                    
                    if !otpCode.isEmpty && otpCode.count == 6 {
                        Button(action: verifyOtp) {
                            HStack {
                                if isVerifying {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Text("Verify Code".localized)
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentGreen)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(isVerifying)
                    }
                }
                
                // Resend Section
                VStack(spacing: 16) {
                    if canResend {
                        Button(action: resendOtp) {
                            HStack {
                                if isResending {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: Color.accentGreen))
                                        .scaleEffect(0.8)
                                } else {
                                    Text("Resend Code".localized)
                                        .fontWeight(.semibold)
                                }
                            }
                            .foregroundColor(Color.accentGreen)
                        }
                        .disabled(isResending)
                    } else {
                        HStack {
                            Text("Resend code in".localized)
                                .foregroundColor(Color.textSecondary)
                            Text("\(timeRemaining)s")
                                .fontWeight(.semibold)
                                .foregroundColor(Color.accentGreen)
                        }
                        .font(.subheadline)
                    }
                    
                    Text("Didn't receive the code? Check your spam folder.".localized)
                        .font(.caption)
                        .foregroundColor(Color.textSecondary)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                // Back to Sign In
                Button(action: { dismiss() }) {
                    Text("Back to Sign In".localized)
                        .fontWeight(.medium)
                        .foregroundColor(Color.textSecondary)
                }
            }
            .padding(24)
            .navigationBarHidden(true)
            .onAppear {
                startTimer()
            }
            .onChange(of: firebaseManager.isOtpVerified) { _, isVerified in
                if isVerified {
                    showingSuccess = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        dismiss()
                    }
                }
            }
            .onChange(of: firebaseManager.authError) { _, error in
                showingError = error != nil
            }
            .alert("Error".localized, isPresented: $showingError) {
                Button("OK".localized) {
                    firebaseManager.clearAuthError()
                }
            } message: {
                Text(firebaseManager.authError ?? "An error occurred".localized)
            }
            .alert("Email Verified!".localized, isPresented: $showingSuccess) {
                Button("Continue".localized) { 
                    dismiss()
                }
            } message: {
                Text("Your email has been verified successfully! Please return to the sign-in page to log into your account.".localized)
            }
        }
    }
    
    private func verifyOtp() {
        guard otpCode.count == 6 else { return }
        
        isVerifying = true
        
        Task {
            do {
                try await firebaseManager.verifyOtp(email: email, otp: otpCode)
                isVerifying = false
            } catch {
                isVerifying = false
                // Error is handled by FirebaseManager
            }
        }
    }
    
    private func resendOtp() {
        isResending = true
        
        Task {
            do {
                try await firebaseManager.resendOtp(email: email)
                isResending = false
                startTimer()
            } catch {
                isResending = false
                // Error is handled by FirebaseManager
            }
        }
    }
    
    private func startTimer() {
        timeRemaining = 60
        canResend = false
        
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                canResend = true
                timer.invalidate()
            }
        }
    }
}

// MARK: - OTP Digit Field
struct OtpDigitField: View {
    let index: Int
    @Binding var otpCode: String
    let isVerifying: Bool
    
    var body: some View {
        TextField("", text: Binding(
            get: {
                if index < otpCode.count {
                    return String(otpCode[otpCode.index(otpCode.startIndex, offsetBy: index)])
                }
                return ""
            },
            set: { newValue in
                if newValue.count <= 1 {
                    if newValue.isEmpty {
                        if otpCode.count > index {
                            otpCode.remove(at: otpCode.index(otpCode.startIndex, offsetBy: index))
                        }
                    } else {
                        if index < otpCode.count {
                            otpCode.remove(at: otpCode.index(otpCode.startIndex, offsetBy: index))
                            otpCode.insert(newValue.first!, at: otpCode.index(otpCode.startIndex, offsetBy: index))
                        } else {
                            otpCode.append(newValue)
                        }
                    }
                }
            }
        ))
        .keyboardType(.numberPad)
        .multilineTextAlignment(.center)
        .font(.title2)
        .fontWeight(.bold)
        .frame(width: 50, height: 60)
        .background(Color.backgroundPrimary)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(otpCode.count > index ? Color.accentGreen : Color.border, lineWidth: 2)
        )
        .disabled(isVerifying)
    }
}

// MARK: - Email Verification Required View
struct EmailVerificationRequiredView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var firebaseManager = FirebaseManager.shared
    @State private var otpCode = ""
    @State private var isVerifying = false
    @State private var isResending = false
    @State private var showingError = false
    @State private var showingSuccess = false
    @State private var email: String
    @State private var timeRemaining = 60
    @State private var canResend = false
    
    init(email: String) {
        self._email = State(initialValue: email)
    }
    
    var body: some View {
        NavigationView {
            mainContent
                .onAppear {
                    startTimer()
                    // Send OTP automatically when view appears
                    Task {
                        try? await firebaseManager.sendOtpEmail(email: email)
                    }
                }
                .onChange(of: firebaseManager.isOtpVerified) { _, isVerified in
                    if isVerified {
                        showingSuccess = true
                    }
                }
                .onChange(of: firebaseManager.authError) { _, error in
                    showingError = error != nil
                }
                .alert("Error".localized, isPresented: $showingError) {
                    Button("OK".localized) {
                        firebaseManager.clearAuthError()
                    }
                } message: {
                    Text(firebaseManager.authError ?? "An error occurred".localized)
                }
                .alert("Email Verified!".localized, isPresented: $showingSuccess) {
                    Button("Continue".localized) {
                        // The app will automatically navigate to main content
                        // when isEmailVerified becomes true
                    }
                } message: {
                    Text("Your email has been verified successfully! Welcome to Synapse!".localized)
                }
        }
    }
    
    private var mainContent: some View {
        VStack(spacing: 32) {
            headerSection
            otpInputSection
            resendSection
            Spacer()
            signOutButton
        }
        .padding(24)
        .background(Color.backgroundSecondary)
        .navigationBarHidden(true)
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "envelope.badge.shield.half.filled")
                .font(.system(size: 80))
                .foregroundColor(Color.accentGreen)
            
            Text("Email Verification Required".localized)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("To continue using Synapse, please verify your email address.".localized)
                .font(.body)
                .foregroundColor(Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            Text(email)
                .font(.headline)
                .foregroundColor(Color.textPrimary)
                .fontWeight(.semibold)
        }
    }
    
    private var otpInputSection: some View {
        VStack(spacing: 20) {
            Text("Enter the 6-digit verification code sent to your email".localized)
                .font(.subheadline)
                .foregroundColor(Color.textSecondary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 12) {
                ForEach(0..<6, id: \.self) { index in
                    OtpDigitField(
                        index: index,
                        otpCode: $otpCode,
                        isVerifying: isVerifying
                    )
                }
            }
            
            if !otpCode.isEmpty && otpCode.count == 6 {
                verifyButton
            }
        }
    }
    
    private var verifyButton: some View {
        Button(action: verifyOtp) {
            HStack {
                if isVerifying {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Text("Verify Email".localized)
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentGreen)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(isVerifying)
        .padding(.horizontal, 20)
    }
    
    private var resendSection: some View {
        VStack(spacing: 16) {
            if canResend {
                resendButton
            } else {
                resendTimerDisplay
            }
            
            Text("Didn't receive the code? Check your spam folder.".localized)
                .font(.caption)
                .foregroundColor(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var resendButton: some View {
        Button(action: resendOtp) {
            HStack {
                if isResending {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color.accentGreen))
                        .scaleEffect(0.8)
                } else {
                    Text("Resend Verification Code".localized)
                        .fontWeight(.semibold)
                }
            }
            .foregroundColor(Color.accentGreen)
        }
        .disabled(isResending)
    }
    
    private var resendTimerDisplay: some View {
        HStack {
            Text("Resend code in".localized)
                .foregroundColor(Color.textSecondary)
            Text("\(timeRemaining)s")
                .fontWeight(.semibold)
                .foregroundColor(Color.accentGreen)
        }
        .font(.subheadline)
    }
    
    private var signOutButton: some View {
        Button(action: signOut) {
            Text("Sign Out".localized)
                .fontWeight(.medium)
                .foregroundColor(Color.error)
        }
    }
    
    private func verifyOtp() {
        guard otpCode.count == 6 else { return }
        
        print("🔍 EmailVerificationRequiredView: Starting OTP verification")
        print("📧 Email: \(email)")
        print("🔢 OTP: \(otpCode)")
        
        isVerifying = true
        
        Task {
            do {
                try await firebaseManager.verifyOtp(email: email, otp: otpCode)
                print("✅ EmailVerificationRequiredView: OTP verification successful")
                await MainActor.run {
                    isVerifying = false
                }
            } catch {
                print("❌ EmailVerificationRequiredView: OTP verification failed - \(error.localizedDescription)")
                await MainActor.run {
                    isVerifying = false
                }
                // Error is handled by FirebaseManager
            }
        }
    }
    
    private func resendOtp() {
        isResending = true
        
        Task {
            do {
                try await firebaseManager.resendOtp(email: email)
                isResending = false
                startTimer()
            } catch {
                isResending = false
                // Error is handled by FirebaseManager
            }
        }
    }
    
    private func signOut() {
        do {
            try firebaseManager.signOut()
        } catch {
            print("Error signing out: \(error)")
        }
    }
    
    private func startTimer() {
        timeRemaining = 60
        canResend = false
        
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                canResend = true
                timer.invalidate()
            }
        }
    }
}

// MARK: - Language Switcher
struct LanguageSwitcher: View {
    @EnvironmentObject private var localizationManager: LocalizationManager
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(LocalizationManager.Language.allCases, id: \.self) { language in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        localizationManager.setLanguage(language)
                    }
                }) {
                    Text(language.displayName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(
                            localizationManager.currentLanguage == language 
                            ? .white 
                            : Color.textPrimary
                        )
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            localizationManager.currentLanguage == language 
                            ? Color.accentGreen 
                            : Color.clear
                        )
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    localizationManager.currentLanguage == language 
                                    ? Color.clear 
                                    : Color.border, 
                                    lineWidth: 1
                                )
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.backgroundPrimary.opacity(0.8))
        .cornerRadius(25)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(LocalizationManager.shared)
        .environmentObject(FirebaseManager.shared)
}

// MARK: - Custom Google Sign-In Button
struct CustomGoogleSignInButton: View {
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
                action()
            }
        }) {
            HStack(spacing: 12) {
                // Google Logo with gradient
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.95, green: 0.35, blue: 0.15), // Google Red
                                    Color(red: 0.95, green: 0.65, blue: 0.15)  // Google Orange
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
                
                // Arrow indicator
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
