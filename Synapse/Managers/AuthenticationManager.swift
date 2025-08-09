//
//  AuthenticationManager.swift
//  Synapse
//
//  Created by Abdulrahman Alshehri on 18/01/1447 AH.
//

import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions

class AuthenticationManager: ObservableObject, AuthenticationServiceProtocol {
    static let shared = AuthenticationManager()
    
    @Published var currentUser: User?
    @Published var authError: String?
    @Published var isEmailVerified = false
    @Published var otpCode: String = ""
    @Published var isOtpSent = false
    @Published var isOtpVerified = false
    @Published var isSigningUp = false
    @Published var lastSignUpAttempt: Date? = nil
    
    private let firebaseService: FirebaseServiceProtocol
    private var userManager: (any UserManagerProtocol)?
    
    private var auth: Auth { firebaseService.auth }
    private var db: Firestore { firebaseService.db }
    private var functions: Functions { firebaseService.functions }
    
    init(firebaseService: FirebaseServiceProtocol = FirebaseService.shared) {
        self.firebaseService = firebaseService
        setupAuthStateListener()
    }
    
    func setUserManager(_ userManager: any UserManagerProtocol) {
        self.userManager = userManager
    }
    
    private func setupAuthStateListener() {
        _ = auth.addStateDidChangeListener { [weak self] _, user in
            print("\n🔄 ===== AUTH STATE CHANGED =====")
            if let user = user {
                print("👤 User signed in: \(user.uid)")
                print("📧 User email: \(user.email ?? "no email")")
                print("🔍 Firebase isEmailVerified: \(user.isEmailVerified)")
                
                DispatchQueue.main.async {
                    self?.currentUser = user
                    self?.isEmailVerified = user.isEmailVerified
                    print("✅ Auth state set: currentUser=\(user.uid)")
                }
            } else {
                print("🚪 User signed out")
                DispatchQueue.main.async {
                    self?.currentUser = nil
                    self?.isEmailVerified = false
                    print("✅ Auth state cleared: currentUser=nil, isEmailVerified=false")
                }
            }
            print("===== AUTH STATE CHANGE COMPLETE =====\n")
        }
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
        
        // Set flag to prevent navigation during sign-up
        await MainActor.run {
            self.isSigningUp = true
            self.lastSignUpAttempt = Date()
        }
        
        do {
            print("📝 Creating new user account...")
            let result = try await auth.createUser(withEmail: email, password: password)
            print("✅ Firebase user created: \(result.user.uid)")
            
            // Set the user's display name in Firebase Auth
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = username
            try await changeRequest.commitChanges()
            print("✅ Display name set to: \(username)")
            
            // Create user profile in Firestore via UserManager
            if let userManager = userManager {
                try await userManager.createUserProfile(userId: result.user.uid, email: email, username: username)
                print("✅ User profile created in Firestore")
            } else {
                print("⚠️ UserManager not available, skipping profile creation")
            }
            
            // Send Firebase email verification link
            do {
                try await result.user.sendEmailVerification()
                print("📨 Email verification link sent to: \(email)")
            } catch {
                print("⚠️ Failed to send verification email: \(error.localizedDescription)")
            }
            
            print("🎉 Sign-up completed successfully! Awaiting email verification.")
            
            // Clear flag after sign-up is complete
            await MainActor.run {
                self.isSigningUp = false
                self.isEmailVerified = result.user.isEmailVerified
            }
            
        } catch {
            print("❌ Sign-up failed: \(error.localizedDescription)")
            await MainActor.run {
                self.isSigningUp = false
                self.authError = self.localizedAuthError(error)
            }
            throw error
        }
    }
    
    func signIn(email: String, password: String) async throws {
        print("\n🔐 ===== SIGN-IN CHECK STARTED =====")
        print("📧 Email: \(email)")
        
        // Clear any previous errors
        DispatchQueue.main.async {
            self.authError = nil
        }
        
        do {
            print("🔍 Checking email and password with Firebase...")
            let result = try await auth.signIn(withEmail: email, password: password)
            print("✅ Email and password are correct!")
            print("👤 User signed in: \(result.user.uid)")
            
            // Check if displayName is missing and update it for existing users
            if result.user.displayName == nil || result.user.displayName?.isEmpty == true {
                print("⚠️ DisplayName is missing, updating from Firestore...")
                try await updateDisplayNameFromFirestore(for: result.user)
            }
            
            // Success - user credentials are valid
            await MainActor.run {
                self.isEmailVerified = result.user.isEmailVerified
            }
            print("🎉 Sign-in successful! isEmailVerified=\(result.user.isEmailVerified)")
            
        } catch {
            print("❌ Sign-in failed: \(error.localizedDescription)")
            
            // Make sure user is signed out on error so no conflicting states
            try? auth.signOut()
            
            // Set clear error message for wrong credentials
            let errorMessage = "Wrong email or password"
            
            DispatchQueue.main.async {
                self.authError = errorMessage
            }
            
            print("⚠️ Showing error to user: \(errorMessage)")
            print("🔒 User signed out to prevent state conflicts")
            throw error
        }
    }

    // MARK: - Email Verification Link Helpers
    func sendEmailVerificationLink() async throws {
        guard let user = auth.currentUser else { throw NSError(domain: "AuthenticationManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not signed in"]) }
        try await user.sendEmailVerification()
    }
    
    func reloadCurrentUser() async {
        do {
            try await auth.currentUser?.reload()
            let verified = auth.currentUser?.isEmailVerified ?? false
            await MainActor.run {
                self.isEmailVerified = verified
            }
        } catch {
            print("⚠️ Failed to reload current user: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Helper Methods for DisplayName Updates
    
    private func updateDisplayNameFromFirestore(for user: User) async throws {
        do {
            // Fetch user document from Firestore
            let userDoc = try await db.collection("users").document(user.uid).getDocument()
            
            guard userDoc.exists, 
                  let data = userDoc.data(),
                  let username = data["username"] as? String else {
                print("❌ Could not find username in Firestore for user: \(user.uid)")
                return
            }
            
            // Update Firebase Auth profile with username
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = username
            try await changeRequest.commitChanges()
            print("✅ DisplayName updated to: \(username) for existing user")
            
        } catch {
            print("❌ Error updating displayName from Firestore: \(error.localizedDescription)")
            // Don't throw the error - sign-in should still succeed even if displayName update fails
        }
    }
    
    func signOut() throws {
        try auth.signOut()
        DispatchQueue.main.async {
            self.currentUser = nil
            self.isEmailVerified = false
            self.otpCode = ""
            self.isOtpSent = false
            self.isOtpVerified = false
        }
    }
    
    // MARK: - OTP Email Verification Methods
    
    func sendOtpEmail(email: String) async throws {
        do {
            print("📧 Sending OTP email to: \(email)")
            
            // Generate 6-digit OTP
            let otp = String(format: "%06d", Int.random(in: 100000...999999))
            print("🔢 Generated OTP: \(otp)")
            
            // Calculate expiration time (15 minutes from now)
            let expirationTime = Date().addingTimeInterval(15 * 60) // 15 minutes
            
            // Store OTP in Firestore for verification
            try await db.collection("otp_codes").document(email).setData([
                "otp": otp,
                "createdAt": FieldValue.serverTimestamp(),
                "expiresAt": Timestamp(date: expirationTime), // Set proper expiration time
                "email": email
            ])
            print("💾 OTP stored in Firestore with 15-minute expiration")
            
            // Try to send actual email via Cloud Function first
            var emailSent = false
            do {
                let data: [String: Any] = [
                    "email": email,
                    "otp": otp,
                    "type": "verification"
                ]
                
                _ = try await functions.httpsCallable("sendOtpEmail").call(data)
                print("✅ Custom OTP email sent via Cloud Function")
                emailSent = true
            } catch {
                print("⚠️ Cloud Function not available: \(error.localizedDescription)")
            }
            
            // Fallback: Try Firebase's built-in email verification if we have a current user
            if !emailSent && auth.currentUser != nil {
                do {
                    try await auth.currentUser?.sendEmailVerification()
                    print("📨 Firebase verification email sent as fallback")
                    emailSent = true
                } catch {
                    print("⚠️ Firebase email verification also failed: \(error.localizedDescription)")
                }
            }
            
            // For development: Print the OTP to console since email might not work
            // Comment out in production
            print("🧪 DEV MODE: OTP for \(email) is: \(otp)")
            
            DispatchQueue.main.async {
                self.isOtpSent = true
                self.otpCode = ""
                // Don't set error even if email wasn't sent - OTP is stored and can be used
            }
            
            if !emailSent {
                print("⚠️ Email sending failed, but OTP is stored and can be verified")
                // Don't throw error - allow verification with stored OTP or bypass code
            }
            
        } catch {
            print("❌ Failed to send OTP email: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.authError = "Failed to send verification email. Please try again.".localized
            }
            throw error
        }
    }
    
    func verifyOtp(email: String, otp: String) async throws {
        do {
            print("🔍 Verifying OTP: \(otp) for email: \(email)")
            
            // Validate OTP strictly (no universal bypass in production)
            do {
                print("🔍 Fetching stored OTP from Firestore...")
                let document = try await db.collection("otp_codes").document(email).getDocument()
                
                guard document.exists else {
                    print("❌ No OTP found for email: \(email)")
                    throw NSError(domain: "AuthenticationManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "No verification code found. Please request a new one.".localized])
                }
                
                guard let data = document.data(),
                      let storedOtp = data["otp"] as? String,
                      let expiresAt = data["expiresAt"] as? Timestamp else {
                    print("❌ Invalid OTP data structure")
                    throw NSError(domain: "AuthenticationManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid verification code. Please request a new one.".localized])
                }
                
                print("✅ Found stored OTP data")
                print("🔍 Stored OTP: \(storedOtp)")
                print("🔍 Expires at: \(expiresAt.dateValue())")
                print("🔍 Current time: \(Date())")
                
                // Check if OTP is expired
                if Date() > expiresAt.dateValue() {
                    print("❌ OTP has expired")
                    throw NSError(domain: "AuthenticationManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Verification code has expired. Please request a new one.".localized])
                }
                
                // Verify OTP
                if otp != storedOtp {
                    print("❌ OTP mismatch: entered '\(otp)' vs stored '\(storedOtp)'")
                    throw NSError(domain: "AuthenticationManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid verification code. Please try again.".localized])
                }
                
                print("✅ OTP verified successfully")
                
                // Delete OTP from database after successful verification
                try await db.collection("otp_codes").document(email).delete()
                print("🗑️ OTP deleted from database")
            }
            
            // Mark email as verified in our custom system
            print("🔍 Finding user by email: \(email)")
            let userSnapshot = try await db.collection("users")
                .whereField("email", isEqualTo: email)
                .getDocuments()
            
            guard let userDocument = userSnapshot.documents.first else {
                print("❌ No user found with email: \(email)")
                throw NSError(domain: "AuthenticationManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "User account not found. Please try signing up again.".localized])
            }
            
            print("✅ Found user document: \(userDocument.documentID)")
            
            // Update user profile to mark email as verified
            try await userDocument.reference.updateData([
                "isEmailVerified": true,
                "emailVerifiedAt": FieldValue.serverTimestamp()
            ])
            print("✅ User email marked as verified in database")
            
            // Update the local state
            DispatchQueue.main.async {
                self.isOtpVerified = true
                self.isEmailVerified = false  // Keep false since user is not signed in yet
                print("✅ Local state updated: isOtpVerified=true")
            }
            
            print("🎉 Email verification completed successfully for user: \(userDocument.documentID)")
            
        } catch {
            print("❌ OTP verification failed: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.authError = error.localizedDescription
            }
            throw error
        }
    }
    
    func resendOtp(email: String) async throws {
        try await sendOtpEmail(email: email)
    }
    
    // MARK: - OTP State Management
    
    func resetOtpState() {
        DispatchQueue.main.async {
            self.isOtpSent = false
            self.isOtpVerified = false
            self.otpCode = ""
        }
    }
    
    func clearAuthError() {
        DispatchQueue.main.async {
            self.authError = nil
        }
        print("🧹 Auth error cleared")
    }
    
    // MARK: - Error Handling
    
    private func localizedAuthError(_ error: Error) -> String {
        print("🔍 Processing auth error: \(error)")
        
        if let authError = error as NSError? {
            print("🔍 Auth error code: \(authError.code)")
            print("🔍 Auth error domain: \(authError.domain)")
            
            // Check if it's a Firebase Auth error
            if authError.domain == "FIRAuthErrorDomain" {
                switch AuthErrorCode(rawValue: authError.code) {
                case .emailAlreadyInUse:
                    return "Email already in use".localized
                case .invalidEmail:
                    return "Invalid email format".localized
                case .weakPassword:
                    return "Password is too weak".localized
                case .wrongPassword:
                    return "Incorrect password".localized
                case .userNotFound:
                    return "Account not found. Please check your email or create a new account".localized
                case .tooManyRequests:
                    return "Too many failed attempts. Please try again later".localized
                case .userDisabled:
                    return "This account has been disabled".localized
                case .requiresRecentLogin:
                    return "Please sign in again for security reasons".localized
                case .networkError:
                    return "Network error. Please check your connection".localized
                default:
                    return "Authentication failed. Please check your credentials".localized
                }
            }
        }
        
        // For custom errors or other types
        return error.localizedDescription
    }
    
    // MARK: - User Validation Methods
    
    func checkUserExists(email: String) async throws -> Bool {
        do {
            // Try to get user by email from Firestore
            let snapshot = try await db.collection("users")
                .whereField("email", isEqualTo: email)
                .getDocuments()
            
            return !snapshot.documents.isEmpty
        } catch {
            // If query fails, assume user doesn't exist
            return false
        }
    }
    
    func validateUsername(_ username: String) async throws -> Bool {
        // Check if username is already taken
        let snapshot = try await db.collection("users")
            .whereField("username", isEqualTo: username)
            .getDocuments()
        
        return snapshot.documents.isEmpty
    }
    
    // MARK: - Anonymous Authentication
    
    func signInAnonymously() async throws {
        do {
            let result = try await auth.signInAnonymously()
            DispatchQueue.main.async {
                self.currentUser = result.user
            }
        } catch {
            DispatchQueue.main.async {
                self.authError = self.localizedAuthError(error)
            }
            throw error
        }
    }
    
    // MARK: - Google Sign-In
    
    func signInWithGoogle() async throws {
        try await GoogleSignInManager.shared.signIn()
    }
} 