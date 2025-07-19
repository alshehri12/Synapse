//
//  AuthenticationView.swift
//  Synapse
//
//  Created by Abdulrahman Alshehri on 18/01/1447 AH.
//

import SwiftUI

struct AuthenticationView: View {
    @StateObject private var firebaseManager = FirebaseManager.shared
    @State private var showingSignUp = false
    @State private var showingLogin = false
    @State private var showingError = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                // Header
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
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 16) {
                    // Custom Google Sign-In Button
                    CustomGoogleSignInButton(action: signInWithGoogle)
                    
                    // Divider
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
                    
                    Button(action: signInAnonymously) {
                        HStack {
                            Image(systemName: "eye")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Browse Anonymously".localized)
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(Color.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.backgroundPrimary)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.textSecondary.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                // Footer
                Text("By continuing, you agree to our Terms of Service and Privacy Policy".localized)
                    .font(.system(size: 12))
                    .foregroundColor(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .padding(.vertical, 40)
            .background(Color.backgroundSecondary)
            .sheet(isPresented: $showingSignUp) {
                SignUpView()
            }
            .sheet(isPresented: $showingLogin) {
                LoginView()
            }
            .alert("Error".localized, isPresented: $showingError) {
                Button("OK".localized) {
                    firebaseManager.clearAuthError()
                }
            } message: {
                Text(firebaseManager.authError ?? "An error occurred".localized)
            }
            .onChange(of: firebaseManager.authError) { error in
                showingError = error != nil
            }
        }
    }
    
    private func signInAnonymously() {
        Task {
            do {
                try await firebaseManager.signInAnonymously()
            } catch {
                // Error is handled by FirebaseManager
            }
        }
    }
    
    private func signInWithGoogle() {
        Task {
            do {
                try await firebaseManager.signInWithGoogle()
            } catch {
                // Error is handled by FirebaseManager
            }
        }
    }
}

// MARK: - Sign Up View
struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var firebaseManager = FirebaseManager.shared
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var username = ""
    @State private var isSubmitting = false
    @State private var showingError = false
    
    var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && !username.isEmpty &&
        password == confirmPassword && password.count >= 6 &&
        email.contains("@")
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
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
                            
                            TextField("Enter username".localized, text: $username)
                                .textFieldStyle(CustomTextFieldStyle())
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
            .alert("Error".localized, isPresented: $showingError) {
                Button("OK".localized) {
                    firebaseManager.clearAuthError()
                }
            } message: {
                Text(firebaseManager.authError ?? "An error occurred".localized)
            }
            .onChange(of: firebaseManager.authError) { error in
                showingError = error != nil
            }
            .onChange(of: firebaseManager.currentUser) { user in
                if user != nil {
                    dismiss()
                }
            }
        }
    }
    
    private func signUp() {
        guard isFormValid else { return }
        
        isSubmitting = true
        
        Task {
            do {
                try await firebaseManager.signUp(email: email, password: password, username: username)
                isSubmitting = false
            } catch {
                isSubmitting = false
                // Error is handled by FirebaseManager
            }
        }
    }
}

// MARK: - Login View
struct LoginView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var firebaseManager = FirebaseManager.shared
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
            .alert("Error".localized, isPresented: $showingError) {
                Button("OK".localized) {
                    firebaseManager.clearAuthError()
                }
            } message: {
                Text(firebaseManager.authError ?? "An error occurred".localized)
            }
            .onChange(of: firebaseManager.authError) { error in
                showingError = error != nil
            }
            .onChange(of: firebaseManager.currentUser) { user in
                if user != nil {
                    dismiss()
                }
            }
        }
    }
    
    private func signIn() {
        guard isFormValid else { return }
        
        isSubmitting = true
        
        Task {
            do {
                try await firebaseManager.signIn(email: email, password: password)
                isSubmitting = false
            } catch {
                isSubmitting = false
                // Error is handled by FirebaseManager
            }
        }
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