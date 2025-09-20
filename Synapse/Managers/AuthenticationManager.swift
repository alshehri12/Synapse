//
//  AuthenticationManager.swift
//  Synapse
//
//  Created by Abdulrahman Alshehri on 18/01/1447 AH.
//  Updated for Supabase migration on 16/01/2025.
//

import Foundation
import Supabase
import Combine

// For backwards compatibility during migration
typealias User = Supabase.User

class AuthenticationManager: ObservableObject {
    static let shared = AuthenticationManager()
    
    @Published var currentUser: User?
    @Published var authError: String?
    @Published var isEmailVerified = false
    @Published var otpCode: String = ""
    @Published var isOtpSent = false
    @Published var isOtpVerified = false
    @Published var isSigningUp = false
    @Published var lastSignUpAttempt: Date? = nil
    
    private let supabaseManager: SupabaseManager
    // User management is now handled directly by SupabaseManager
    private var cancellables = Set<AnyCancellable>()
    
    init(supabaseManager: SupabaseManager = SupabaseManager.shared) {
        self.supabaseManager = supabaseManager
        setupAuthStateListener()
    }
    
    // User management is now handled directly by SupabaseManager
    // func setUserManager is no longer needed
    
    private func setupAuthStateListener() {
        // Listen to Supabase auth state changes through SupabaseManager
        supabaseManager.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                print("\n🔄 ===== SUPABASE AUTH STATE CHANGED =====")
            if let user = user {
                    print("👤 User signed in: \(user.id)")
                print("📧 User email: \(user.email ?? "no email")")
                    print("🔍 Supabase isEmailVerified: \(user.emailConfirmedAt != nil)")
                
                    self?.currentUser = user
                    self?.isEmailVerified = user.emailConfirmedAt != nil
                    print("✅ Auth state set: currentUser=\(user.id)")
            } else {
                print("🚪 User signed out")
                    self?.currentUser = nil
                    self?.isEmailVerified = false
                    print("✅ Auth state cleared: currentUser=nil, isEmailVerified=false")
                }
                print("===== AUTH STATE CHANGE COMPLETE =====\n")
            }
            .store(in: &cancellables)
        
        // Also sync auth errors from SupabaseManager
        supabaseManager.$authError
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.authError = error
            }
            .store(in: &cancellables)
        
        // Sync isSigningUp state
        supabaseManager.$isSigningUp
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isSigningUp in
                self?.isSigningUp = isSigningUp
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Authentication Methods
    
    func signUp(email: String, password: String, username: String) async throws {
        // Rate limiting: Prevent rapid sign-up attempts (anti-bot measure)
        if let lastAttempt = lastSignUpAttempt {
            let timeSinceLastAttempt = Date().timeIntervalSince(lastAttempt)
            if timeSinceLastAttempt < 30 { // 30 second cooldown
                throw NSError(domain: "AuthenticationManager", code: -1, 
                            userInfo: [NSLocalizedDescriptionKey: "Please wait 30 seconds before creating another account".localized])
            }
        }
        
        await MainActor.run {
            self.lastSignUpAttempt = Date()
        }
        
        do {
            print("📝 Creating new user account with Supabase...")
            try await supabaseManager.signUp(email: email, password: password, username: username)
            print("✅ Supabase user created successfully")
            
            // Note: User profile creation in Supabase will be handled differently
            // Database operations now use Supabase
            // User profile creation is now handled by SupabaseManager during sign up
            // The user profile is automatically created in Supabase when user signs up
            print("✅ User profile will be created automatically by SupabaseManager")
            
        } catch {
            print("❌ Sign-up failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    func signIn(email: String, password: String) async throws {
        print("\n🔐 ===== SUPABASE SIGN-IN CHECK STARTED =====")
        print("📧 Email: \(email)")
        
        do {
            try await supabaseManager.signIn(email: email, password: password)
            print("✅ Supabase sign-in successful")
        } catch {
            print("❌ Sign-in failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    func signOut() async throws {
        print("🚪 Signing out from Supabase...")
        try await supabaseManager.signOut()
        print("✅ Signed out successfully")
    }
    
    // Protocol requirement - synchronous version
    func signOut() throws {
        Task {
            try await signOut()
        }
    }
    
    func sendEmailVerificationLink() async throws {
        print("📨 Sending email verification link via Supabase...")
        try await supabaseManager.sendEmailVerificationLink()
        print("✅ Email verification link sent")
    }
    
    func reloadCurrentUser() async throws {
        print("🔄 Reloading current user from Supabase...")
        try await supabaseManager.reloadCurrentUser()
        print("✅ User reloaded")
    }
    
    // MARK: - OTP Methods (Legacy - kept for compatibility)
    
    func sendOtpEmail(email: String, otp: String) async throws {
        print("📨 OTP email sending not implemented for Supabase yet")
        // This could be implemented with a serverless function if needed
    }
    
    func sendOtpEmail(email: String) async throws {
        print("📨 OTP email sending not implemented for Supabase yet")
        // This could be implemented with a serverless function if needed
    }
    
    func verifyOtp(email: String, enteredOtp: String) async throws -> Bool {
        print("🔍 OTP verification not implemented for Supabase yet")
        return false
    }
    
    func verifyOtp(email: String, otp: String) async throws {
        print("🔍 OTP verification not implemented for Supabase yet")
    }
    
    func resetOtpState() {
        isOtpSent = false
        isOtpVerified = false
        otpCode = ""
    }
    
    func resendOtp(email: String) async throws {
        print("📨 OTP resend not implemented for Supabase yet")
        // This could be implemented with a serverless function if needed
    }
    
    func clearAuthError() {
        authError = nil
    }
    
    func checkUserExists(email: String) async throws -> Bool {
        do {
            let users = try await supabaseManager.getAllUsers()
            return users.contains { $0.email.lowercased() == email.lowercased() }
        } catch {
            print("❌ Error checking if user exists: \(error)")
            throw error
        }
    }
    
    func validateUsername(_ username: String) async throws -> Bool {
        // Use SupabaseManager's implementation
        return try await supabaseManager.validateUsername(username)
    }
    
    func signInAnonymously() async throws {
        print("🔍 Anonymous sign in not implemented for Supabase yet")
        throw NSError(domain: "AuthenticationManager", code: -1, 
                     userInfo: [NSLocalizedDescriptionKey: "Anonymous sign in not supported"])
    }
    
    func signInWithGoogle() async throws {
        print("🔍 Starting Google sign in with Supabase...")
        do {
            try await supabaseManager.signInWithGoogle()
            print("✅ Google sign in successful")
        } catch {
            print("❌ Google sign in failed: \(error)")
            throw error
        }
    }
    
    // MARK: - Helper Methods
    
    private func localizedAuthError(_ error: Error) -> String {
        // Convert Supabase errors to user-friendly messages
        let errorMessage = error.localizedDescription
        
        if errorMessage.contains("Invalid login credentials") {
            return "Invalid email or password. Please check your credentials and try again.".localized
        } else if errorMessage.contains("Email not confirmed") {
            return "Please verify your email before signing in.".localized
        } else if errorMessage.contains("User already registered") {
            return "An account with this email already exists.".localized
        } else {
            return "Authentication failed: \(errorMessage)".localized
        }
    }
}

// MARK: - String Extension for Localization (removed to avoid redeclaration)