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
    @State private var animateContent = false

    var body: some View {
        NavigationView {
            ZStack {
                // Clean white background
                Color.white.ignoresSafeArea()

                // Subtle green accent circles for depth
                GeometryReader { geometry in
                    Circle()
                        .fill(Color(red: 0.20, green: 0.73, blue: 0.45).opacity(0.06))
                        .frame(width: 500, height: 500)
                        .blur(radius: 80)
                        .offset(x: -150, y: -200)

                    Circle()
                        .fill(Color(red: 0.12, green: 0.47, blue: 0.31).opacity(0.05))
                        .frame(width: 450, height: 450)
                        .blur(radius: 70)
                        .offset(x: geometry.size.width - 100, y: geometry.size.height - 150)

                    // Floating project management icons with shadows
                    // Top left - Lightbulb (Ideas)
                    FloatingIcon(
                        systemName: "lightbulb.fill",
                        color: Color(red: 0.20, green: 0.73, blue: 0.45),
                        size: 50,
                        opacity: 0.15
                    )
                    .offset(x: 30, y: 120)

                    // Top right - Rocket (Launch)
                    FloatingIcon(
                        systemName: "rocket.fill",
                        color: Color(red: 0.16, green: 0.60, blue: 0.38),
                        size: 45,
                        opacity: 0.12
                    )
                    .offset(x: geometry.size.width - 80, y: 180)

                    // Middle left - People (Collaboration)
                    FloatingIcon(
                        systemName: "person.3.fill",
                        color: Color(red: 0.20, green: 0.73, blue: 0.45),
                        size: 40,
                        opacity: 0.1
                    )
                    .offset(x: 50, y: geometry.size.height / 2 - 100)

                    // Middle right - Target (Goals)
                    FloatingIcon(
                        systemName: "target",
                        color: Color(red: 0.12, green: 0.47, blue: 0.31),
                        size: 48,
                        opacity: 0.13
                    )
                    .offset(x: geometry.size.width - 90, y: geometry.size.height / 2 + 50)

                    // Bottom left - Chart (Progress)
                    FloatingIcon(
                        systemName: "chart.line.uptrend.xyaxis",
                        color: Color(red: 0.20, green: 0.73, blue: 0.45),
                        size: 42,
                        opacity: 0.11
                    )
                    .offset(x: 40, y: geometry.size.height - 280)

                    // Bottom right - Sparkles (Innovation)
                    FloatingIcon(
                        systemName: "sparkles",
                        color: Color(red: 0.16, green: 0.60, blue: 0.38),
                        size: 38,
                        opacity: 0.14
                    )
                    .offset(x: geometry.size.width - 70, y: geometry.size.height - 200)
                }

                VStack(spacing: 0) {
                    // Language switcher at top with proper spacing
                    HStack {
                        Spacer()
                        Button(action: {
                            localizationManager.toggleLanguage()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "globe")
                                    .font(.system(size: 16, weight: .medium))
                                Text(localizationManager.currentLanguage == .arabic ? "العربية" : "EN")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(Color(red: 0.12, green: 0.47, blue: 0.31))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(Color(red: 0.20, green: 0.73, blue: 0.45).opacity(0.1))
                                    .overlay(
                                        Capsule()
                                            .stroke(Color(red: 0.20, green: 0.73, blue: 0.45).opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 60)
                    .opacity(animateContent ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: animateContent)

                    Spacer()

                    // Content section
                    VStack(spacing: 40) {
                        // Logo - 50% larger (240x240)
                        Image("SynapseLogo")
                            .resizable()
                            .renderingMode(.original)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 240, height: 240)
                            .shadow(color: Color.black.opacity(0.08), radius: 25, x: 0, y: 12)
                            .opacity(animateContent ? 1 : 0)
                            .scaleEffect(animateContent ? 1 : 0.7)
                            .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2), value: animateContent)

                        // Welcome text
                        VStack(spacing: 12) {
                            Text(localizationManager.currentLanguage == .arabic ?
                                 "مرحباً بك في Synapse" :
                                 "Welcome to Synapse")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(Color.textPrimary)
                                .multilineTextAlignment(.center)

                            Text(localizationManager.currentLanguage == .arabic ?
                                 "حيث تتحول الأفكار إلى واقع" :
                                 "Where ideas come to life")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(Color.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 15)
                        .animation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.3), value: animateContent)

                        // Buttons section
                        VStack(spacing: 18) {
                            // Google Sign-In Button
                            GoogleSignInButton()
                                .frame(height: 58)

                            // Sign In Button
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    showingLogin = true
                                }
                            }) {
                                Text(localizationManager.currentLanguage == .arabic ?
                                     "تسجيل الدخول" :
                                     "Sign In")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(Color.textPrimary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 58)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1.5)
                                    )
                            }
                            .buttonStyle(ScaleButtonStyle())

                            // Divider
                            HStack(spacing: 14) {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 1)
                                Text(localizationManager.currentLanguage == .arabic ? "أو" : "or")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(Color.textSecondary)
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 1)
                            }
                            .padding(.vertical, 4)

                            // Create Account Button - Green
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    showingSignUp = true
                                }
                            }) {
                                Text(localizationManager.currentLanguage == .arabic ?
                                     "إنشاء حساب جديد" :
                                     "Create Account")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 58)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        Color(red: 0.20, green: 0.73, blue: 0.45),
                                                        Color(red: 0.16, green: 0.60, blue: 0.38)
                                                    ]),
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .shadow(color: Color(red: 0.20, green: 0.73, blue: 0.45).opacity(0.3), radius: 12, x: 0, y: 6)
                                    )
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                        .padding(.horizontal, 32)
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 30)
                        .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.4), value: animateContent)

                        // Terms text with clickable links
                        HStack(spacing: 4) {
                            Text(localizationManager.currentLanguage == .arabic ?
                                 "باستمرارك، أنت توافق على" :
                                 "By continuing, you agree to our")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(Color.textSecondary)

                            Button(action: {
                                if let url = URL(string: "https://usynapse.com/terms") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                Text(localizationManager.currentLanguage == .arabic ?
                                     "الشروط" :
                                     "Terms")
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(Color.accentGreen)
                                    .underline()
                            }

                            Text(localizationManager.currentLanguage == .arabic ?
                                 "و" :
                                 "&")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(Color.textSecondary)

                            Button(action: {
                                if let url = URL(string: "https://usynapse.com/privacy") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                Text(localizationManager.currentLanguage == .arabic ?
                                     "سياسة الخصوصية" :
                                     "Privacy Policy")
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(Color.accentGreen)
                                    .underline()
                            }
                        }
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .opacity(animateContent ? 1 : 0)
                        .animation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.5), value: animateContent)
                    }

                    Spacer()
                }
            }
        }
        .navigationBarHidden(true)
        .environment(\.layoutDirection, localizationManager.currentLanguage == .arabic ? .rightToLeft : .leftToRight)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    animateContent = true
                }
            }
        }
        .sheet(isPresented: $showingSignUp) {
            SignUpView()
        }
        .sheet(isPresented: $showingLogin) {
            LoginView()
        }
    }
    
    // MARK: - Language Switcher
    private var languageSwitcherCompact: some View {
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
    
    // MARK: - Hero Section (Compact)
    private var heroSection: some View {
        VStack(spacing: 16) {
            // App Icon (Smaller)
            // App Logo - Elegant and transparent
            Image("AppLogo")
                .resizable()
                .renderingMode(.original)
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
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
    @State private var agreedToTerms = false

    var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && !username.isEmpty &&
        password == confirmPassword && password.count >= 6 &&
        email.contains("@") && usernameError.isEmpty && agreedToTerms
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Modern gradient background matching home page
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.95, green: 0.98, blue: 0.96),
                        Color.white,
                        Color(red: 0.97, green: 1.0, blue: 0.98)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        headerSection
                        formSection
                        actionSection
                    }
                    .padding(.bottom, 50)
                }
            }
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
        VStack(spacing: 28) {
            // Top bar with close button and language switcher
            HStack {
                Button(action: { dismiss() }) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.9))
                            .frame(width: 40, height: 40)
                            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)

                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color.textSecondary)
                    }
                }

                Spacer()

                LanguageSwitcher()
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            // Modern title section with icon
            VStack(spacing: 16) {
                // Icon with green glow
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.accentGreen.opacity(0.2),
                                    Color.accentGreen.opacity(0.05),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 20,
                                endRadius: 60
                            )
                        )
                        .frame(width: 120, height: 120)

                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.accentGreen.opacity(0.15),
                                    Color.accentGreen.opacity(0.08)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 70, height: 70)

                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(Color.accentGreen)
                }

                VStack(spacing: 8) {
                    Text("Create Account".localized)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.accentGreen,
                                    Color.accentGreen.opacity(0.8)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text("Join the Synapse community".localized)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.textSecondary.opacity(0.8))
                }
            }
        }
    }
                    
    private var formSection: some View {
        // Modern card container for form
        VStack(spacing: 20) {
            usernameField
            emailField
            passwordField
            confirmPasswordField

            // Terms and conditions only
            termsCheckbox
                .padding(.top, 4)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.7))
                .shadow(color: Color.black.opacity(0.06), radius: 20, x: 0, y: 10)
        )
        .padding(.horizontal, 24)
    }

    private var usernameField: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Username".localized)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color.textPrimary.opacity(0.7))

            HStack(spacing: 12) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color.accentGreen.opacity(0.6))

                TextField("Enter username".localized, text: $username)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color.textPrimary)
                    .autocapitalization(.none)
                    .onChange(of: username) { _, newValue in
                        validateUsername(newValue)
                    }

                if isCheckingUsername {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color.accentGreen))
                        .scaleEffect(0.8)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(usernameError.isEmpty ? Color.black.opacity(0.08) : Color.red.opacity(0.3), lineWidth: 1.5)
                    )
            )

            if !usernameError.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 12))
                    Text(usernameError)
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(Color.red.opacity(0.8))
            }
        }
    }

    private var emailField: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Email".localized)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color.textPrimary.opacity(0.7))

            HStack(spacing: 12) {
                Image(systemName: "envelope.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color.accentGreen.opacity(0.6))

                TextField("Enter email".localized, text: $email)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color.textPrimary)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.black.opacity(0.08), lineWidth: 1.5)
                    )
            )
        }
    }

    private var passwordField: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Password".localized)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color.textPrimary.opacity(0.7))

            HStack(spacing: 12) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color.accentGreen.opacity(0.6))

                SecureField("Enter password".localized, text: $password)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color.textPrimary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.black.opacity(0.08), lineWidth: 1.5)
                    )
            )
        }
    }

    private var confirmPasswordField: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Confirm Password".localized)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color.textPrimary.opacity(0.7))

            HStack(spacing: 12) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color.accentGreen.opacity(0.6))

                SecureField("Confirm password".localized, text: $confirmPassword)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color.textPrimary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(!confirmPassword.isEmpty && password != confirmPassword ? Color.red.opacity(0.3) : Color.black.opacity(0.08), lineWidth: 1.5)
                    )
            )

            if !confirmPassword.isEmpty && password != confirmPassword {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 12))
                    Text("Passwords do not match".localized)
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(Color.red.opacity(0.8))
            }
        }
    }

    private var termsCheckbox: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: { agreedToTerms.toggle() }) {
                Image(systemName: agreedToTerms ? "checkmark.square.fill" : "square")
                    .font(.system(size: 22))
                    .foregroundColor(agreedToTerms ? Color.accentGreen : Color.textSecondary)
            }

            HStack(spacing: 0) {
                Text("I agree to the ")
                    .font(.system(size: 14))
                    .foregroundColor(Color.textPrimary)

                Button(action: {
                    if let url = URL(string: "https://usynapse.com/terms") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Text("Terms of Service")
                        .font(.system(size: 14))
                        .foregroundColor(Color.accentGreen)
                        .underline()
                }

                Text(" and ")
                    .font(.system(size: 14))
                    .foregroundColor(Color.textPrimary)

                Button(action: {
                    if let url = URL(string: "https://usynapse.com/privacy") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Text("Privacy Policy")
                        .font(.system(size: 14))
                        .foregroundColor(Color.accentGreen)
                        .underline()
                }
            }
            .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
    }

    private var actionSection: some View {
        VStack(spacing: 20) {
            signUpButton
            loginPrompt
        }
        .padding(.horizontal, 24)
    }

    private var signUpButton: some View {
        Button(action: signUp) {
            HStack(spacing: 12) {
                if isSubmitting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                } else {
                    Text("Create Account".localized)
                        .font(.system(size: 18, weight: .bold, design: .rounded))

                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        isFormValid && !isSubmitting ? Color.accentGreen : Color.gray.opacity(0.5),
                        isFormValid && !isSubmitting ? Color.accentGreen.opacity(0.85) : Color.gray.opacity(0.4)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(18)
            .shadow(color: isFormValid ? Color.accentGreen.opacity(0.4) : Color.clear, radius: 15, x: 0, y: 8)
        }
        .buttonStyle(ModernScaleButtonStyle())
        .disabled(!isFormValid || isSubmitting)
    }

    private var loginPrompt: some View {
        Button(action: { dismiss() }) {
            HStack(spacing: 6) {
                Text("Already have an account?".localized)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color.textSecondary)

                Text("Sign In".localized)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color.accentGreen)
            }
            .padding(.vertical, 12)
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
            ZStack {
                // Modern gradient background matching home page
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.95, green: 0.98, blue: 0.96),
                        Color.white,
                        Color(red: 0.97, green: 1.0, blue: 0.98)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        headerSection
                        formSection
                        actionSection
                    }
                    .padding(.bottom, 50)
                }
            }
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
        VStack(spacing: 28) {
            // Top bar with close button and language switcher
            HStack {
                Button(action: { dismiss() }) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.9))
                            .frame(width: 40, height: 40)
                            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)

                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color.textSecondary)
                    }
                }

                Spacer()

                LanguageSwitcher()
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            // Modern title section with icon
            VStack(spacing: 16) {
                // Icon with green glow
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.accentGreen.opacity(0.2),
                                    Color.accentGreen.opacity(0.05),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 20,
                                endRadius: 60
                            )
                        )
                        .frame(width: 120, height: 120)

                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.accentGreen.opacity(0.15),
                                    Color.accentGreen.opacity(0.08)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 70, height: 70)

                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(Color.accentGreen)
                }

                VStack(spacing: 8) {
                    Text("Welcome Back".localized)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.accentGreen,
                                    Color.accentGreen.opacity(0.8)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text("Sign in to your account".localized)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.textSecondary.opacity(0.8))
                }
            }
        }
    }

    private var formSection: some View {
        // Modern card container for form
        VStack(spacing: 20) {
            emailField
            passwordField
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.7))
                .shadow(color: Color.black.opacity(0.06), radius: 20, x: 0, y: 10)
        )
        .padding(.horizontal, 24)
    }

    private var emailField: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Email".localized)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color.textPrimary.opacity(0.7))

            HStack(spacing: 12) {
                Image(systemName: "envelope.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color.accentGreen.opacity(0.6))

                TextField("Enter email".localized, text: $email)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color.textPrimary)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.black.opacity(0.08), lineWidth: 1.5)
                    )
            )
        }
    }

    private var passwordField: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Password".localized)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color.textPrimary.opacity(0.7))

            HStack(spacing: 12) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color.accentGreen.opacity(0.6))

                SecureField("Enter password".localized, text: $password)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color.textPrimary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.black.opacity(0.08), lineWidth: 1.5)
                    )
            )
        }
    }

    private var actionSection: some View {
        VStack(spacing: 20) {
            signInButton
            signUpPrompt
        }
        .padding(.horizontal, 24)
    }

    private var signInButton: some View {
        Button(action: signIn) {
            HStack(spacing: 12) {
                if isSubmitting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                } else {
                    Text("Sign In".localized)
                        .font(.system(size: 18, weight: .bold, design: .rounded))

                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        isFormValid && !isSubmitting ? Color.accentGreen : Color.gray.opacity(0.5),
                        isFormValid && !isSubmitting ? Color.accentGreen.opacity(0.85) : Color.gray.opacity(0.4)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(18)
            .shadow(color: isFormValid ? Color.accentGreen.opacity(0.4) : Color.clear, radius: 15, x: 0, y: 8)
        }
        .buttonStyle(ModernScaleButtonStyle())
        .disabled(!isFormValid || isSubmitting)
    }

    private var signUpPrompt: some View {
        Button(action: { dismiss() }) {
            HStack(spacing: 6) {
                Text("Don't have an account?".localized)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color.textSecondary)

                Text("Sign Up".localized)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color.accentGreen)
            }
            .padding(.vertical, 12)
        }
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
    @State private var showSuccessAlert = false
    @State private var showErrorAlert = false

    var body: some View {
        ZStack {
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

            // Elegant Success Popup
            if showSuccessAlert {
                SuccessAlertView(
                    isPresented: $showSuccessAlert,
                    title: "Email Verified!",
                    message: "Your account has been successfully verified. Welcome to Synapse!",
                    onDismiss: {
                        dismiss()
                    }
                )
                .transition(.scale.combined(with: .opacity))
                .zIndex(999)
            }

            // Elegant Error Popup
            if showErrorAlert {
                ErrorAlertView(
                    isPresented: $showErrorAlert,
                    title: "Invalid Code",
                    message: errorMessage,
                    onDismiss: {
                        otpCode = ""
                    }
                )
                .transition(.scale.combined(with: .opacity))
                .zIndex(999)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showSuccessAlert)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showErrorAlert)
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

            // 6-digit OTP input with individual boxes and auto-focus
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

        // Limit to 6 digits
        if otpCode.count > 6 {
            otpCode = String(otpCode.prefix(6))
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
                    .fill(otpCode.count == 6 && !isSubmitting ? Color.accentGreen : Color.gray.opacity(0.3))
            )
        }
        .disabled(otpCode.count != 6 || isSubmitting)
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
                    self.showSuccessAlert = true
                }
            } catch {
                await MainActor.run {
                    self.isSubmitting = false
                    self.errorMessage = "The verification code you entered is incorrect. Please check your email and try again."
                    self.showErrorAlert = true
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
            // Extract only digits and take first 6
            let digits = clipboardContent.filter { $0.isNumber }
            otpCode = String(digits.prefix(6))
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
    @State private var showSuccessAlert = false
    @State private var showErrorAlert = false

    var body: some View {
        ZStack {
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

            // Elegant Success Popup
            if showSuccessAlert {
                SuccessAlertView(
                    isPresented: $showSuccessAlert,
                    title: "Email Verified!",
                    message: "Your account has been successfully verified. Welcome to Synapse!",
                    onDismiss: {
                        // Alert will auto-dismiss and user will see main app
                    }
                )
                .transition(.scale.combined(with: .opacity))
                .zIndex(999)
            }

            // Elegant Error Popup
            if showErrorAlert {
                ErrorAlertView(
                    isPresented: $showErrorAlert,
                    title: "Invalid Code",
                    message: errorMessage,
                    onDismiss: {
                        otpCode = ""
                    }
                )
                .transition(.scale.combined(with: .opacity))
                .zIndex(999)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showSuccessAlert)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showErrorAlert)
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

            // 6-digit OTP input with auto-focus
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

        if otpCode.count > 6 {
            otpCode = String(otpCode.prefix(6))
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
                    .fill(otpCode.count == 6 && !isSubmitting ? Color.accentGreen : Color.gray.opacity(0.3))
            )
        }
        .disabled(otpCode.count != 6 || isSubmitting)
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
                    self.showSuccessAlert = true
                }
            } catch {
                await MainActor.run {
                    self.isSubmitting = false
                    self.errorMessage = "The verification code you entered is incorrect. Please check your email and try again."
                    self.showErrorAlert = true
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
            // Extract only digits and take first 6
            let digits = clipboardContent.filter { $0.isNumber }
            otpCode = String(digits.prefix(6))
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

// MARK: - Google Sign-In Button (Modern Design)
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
            HStack(spacing: 14) {
                // Modern Google Logo
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 32, height: 32)
                        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)

                    Image(systemName: "globe")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.26, green: 0.52, blue: 0.96),
                                    Color(red: 0.92, green: 0.26, blue: 0.22)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                Text("Continue with Google".localized)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.textPrimary)

                Spacer()
            }
            .frame(maxWidth: .infinity)
            .frame(height: 62)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.black.opacity(0.06), lineWidth: 1.5)
            )
        }
        .buttonStyle(ModernScaleButtonStyle())
    }
} 

// MARK: - OTP Input View with Auto-Focus (6-Digit)
struct OTPInputView: View {
    @Binding var otpCode: String
    @FocusState private var focusedField: Int?
    @State private var digit1: String = ""
    @State private var digit2: String = ""
    @State private var digit3: String = ""
    @State private var digit4: String = ""
    @State private var digit5: String = ""
    @State private var digit6: String = ""
    @State private var isUpdatingFromParent = false

    var body: some View {
        HStack(spacing: 8) {
            // Field 1
            OTPSingleField(text: $digit1, isFocused: focusedField == 0)
                .focused($focusedField, equals: 0)
                .onChange(of: digit1) { oldValue, newValue in
                    guard !isUpdatingFromParent else { return }
                    handleChange(field: 0, oldValue: oldValue, newValue: newValue)
                }

            // Field 2
            OTPSingleField(text: $digit2, isFocused: focusedField == 1)
                .focused($focusedField, equals: 1)
                .onChange(of: digit2) { oldValue, newValue in
                    guard !isUpdatingFromParent else { return }
                    handleChange(field: 1, oldValue: oldValue, newValue: newValue)
                }

            // Field 3
            OTPSingleField(text: $digit3, isFocused: focusedField == 2)
                .focused($focusedField, equals: 2)
                .onChange(of: digit3) { oldValue, newValue in
                    guard !isUpdatingFromParent else { return }
                    handleChange(field: 2, oldValue: oldValue, newValue: newValue)
                }

            // Field 4
            OTPSingleField(text: $digit4, isFocused: focusedField == 3)
                .focused($focusedField, equals: 3)
                .onChange(of: digit4) { oldValue, newValue in
                    guard !isUpdatingFromParent else { return }
                    handleChange(field: 3, oldValue: oldValue, newValue: newValue)
                }

            // Field 5
            OTPSingleField(text: $digit5, isFocused: focusedField == 4)
                .focused($focusedField, equals: 4)
                .onChange(of: digit5) { oldValue, newValue in
                    guard !isUpdatingFromParent else { return }
                    handleChange(field: 4, oldValue: oldValue, newValue: newValue)
                }

            // Field 6
            OTPSingleField(text: $digit6, isFocused: focusedField == 5)
                .focused($focusedField, equals: 5)
                .onChange(of: digit6) { oldValue, newValue in
                    guard !isUpdatingFromParent else { return }
                    handleChange(field: 5, oldValue: oldValue, newValue: newValue)
                }
        }
        .environment(\.layoutDirection, .leftToRight) // Force LTR for OTP fields
        .onAppear {
            // Auto-focus first field on appear
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                focusedField = 0
            }
        }
        .onChange(of: otpCode) { oldValue, newValue in
            // Only update if pasted from outside (not from our own updates)
            let currentCode = getCurrentCode()
            if newValue != currentCode && newValue.count >= 6 {
                isUpdatingFromParent = true
                let digits = Array(newValue.filter { $0.isNumber }.prefix(6))
                digit1 = digits.count > 0 ? String(digits[0]) : ""
                digit2 = digits.count > 1 ? String(digits[1]) : ""
                digit3 = digits.count > 2 ? String(digits[2]) : ""
                digit4 = digits.count > 3 ? String(digits[3]) : ""
                digit5 = digits.count > 4 ? String(digits[4]) : ""
                digit6 = digits.count > 5 ? String(digits[5]) : ""
                focusedField = 5
                isUpdatingFromParent = false
            }
        }
    }

    private func getCurrentCode() -> String {
        return digit1 + digit2 + digit3 + digit4 + digit5 + digit6
    }

    private func handleChange(field: Int, oldValue: String, newValue: String) {
        let filtered = newValue.filter { $0.isNumber }
        let wasEmpty = oldValue.isEmpty

        // Prevent re-entrancy
        guard !isUpdatingFromParent else { return }

        switch field {
        case 0:
            if filtered.isEmpty {
                digit1 = ""
            } else {
                digit1 = String(filtered.prefix(1))
                if !digit1.isEmpty {
                    focusedField = 1
                }
            }
        case 1:
            if filtered.isEmpty {
                digit2 = ""
                if wasEmpty {
                    focusedField = 0
                }
            } else {
                digit2 = String(filtered.prefix(1))
                if !digit2.isEmpty {
                    focusedField = 2
                }
            }
        case 2:
            if filtered.isEmpty {
                digit3 = ""
                if wasEmpty {
                    focusedField = 1
                }
            } else {
                digit3 = String(filtered.prefix(1))
                if !digit3.isEmpty {
                    focusedField = 3
                }
            }
        case 3:
            if filtered.isEmpty {
                digit4 = ""
                if wasEmpty {
                    focusedField = 2
                }
            } else {
                digit4 = String(filtered.prefix(1))
                if !digit4.isEmpty {
                    focusedField = 4
                }
            }
        case 4:
            if filtered.isEmpty {
                digit5 = ""
                if wasEmpty {
                    focusedField = 3
                }
            } else {
                digit5 = String(filtered.prefix(1))
                if !digit5.isEmpty {
                    focusedField = 5
                }
            }
        case 5:
            if filtered.isEmpty {
                digit6 = ""
                if wasEmpty {
                    focusedField = 4
                }
            } else {
                digit6 = String(filtered.prefix(1))
            }
        default:
            break
        }

        // Update binding after state changes
        DispatchQueue.main.async {
            otpCode = getCurrentCode()
        }
    }
}

// MARK: - OTP Single Field Component
struct OTPSingleField: View {
    @Binding var text: String
    let isFocused: Bool

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
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
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

// MARK: - Scale Button Style for Modern Interactions
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0), value: configuration.isPressed)
    }
}

// MARK: - Modern Scale Button Style with Enhanced Feedback
struct ModernScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .brightness(configuration.isPressed ? -0.05 : 0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7, blendDuration: 0), value: configuration.isPressed)
    }
}

// MARK: - Rounded Corner Shape (for Grab-style bottom section)
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Floating Icon Component
struct FloatingIcon: View {
    let systemName: String
    let color: Color
    let size: CGFloat
    let opacity: Double

    @State private var isAnimating = false

    var body: some View {
        ZStack {
            // Shadow circle
            Circle()
                .fill(color.opacity(opacity * 0.3))
                .frame(width: size + 20, height: size + 20)
                .blur(radius: 8)

            // Icon
            Image(systemName: systemName)
                .font(.system(size: size * 0.5, weight: .medium))
                .foregroundColor(color.opacity(opacity))
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(Color.white)
                        .shadow(color: color.opacity(opacity * 0.4), radius: 10, x: 0, y: 4)
                )
        }
        .offset(y: isAnimating ? -10 : 10)
        .animation(
            Animation.easeInOut(duration: 3.0)
                .repeatForever(autoreverses: true),
            value: isAnimating
        )
        .onAppear {
            isAnimating = true
        }
    }
}

