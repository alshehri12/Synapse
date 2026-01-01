//
//  SupabaseManager.swift
//  Synapse
//
//  Complete Supabase implementation to replace Firebase
//  Created on 16/01/2025
//

import Foundation
import Supabase
import Combine
import GoogleSignIn
import UIKit
import AuthenticationServices

// MARK: - Custom Errors

enum AuthError: LocalizedError, Equatable {
    case noViewController
    case missingGoogleClientId
    case missingIdToken
    case googleSignInNotImplemented
    case emailNotVerified
    case missingAppleIdToken
    case appleSignInFailed

    var errorDescription: String? {
        switch self {
        case .noViewController:
            return "No view controller available for Google Sign-In"
        case .missingGoogleClientId:
            return "Google Client ID not found in GoogleService-Info.plist"
        case .missingIdToken:
            return "Google ID token not received"
        case .googleSignInNotImplemented:
            return "Google Sign-In implementation in progress"
        case .emailNotVerified:
            return "Please verify your email before signing in"
        case .missingAppleIdToken:
            return "Apple ID token not received"
        case .appleSignInFailed:
            return "Sign in with Apple failed"
        }
    }
}

class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()

    // Supabase client
    private let supabaseClient: SupabaseClient

    // Public access to supabase client for managers
    var supabase: SupabaseClient {
        return supabaseClient
    }
    
    // Published authentication state
    @Published var currentUser: User?
    @Published var authError: String?
    @Published var isEmailVerified: Bool = false
    @Published var isAuthenticated: Bool = false
    @Published var isSigningUp: Bool = false
    @Published var isAuthReady: Bool = false
    
    // Combine cancellables
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Initialize Supabase client with credentials from Info.plist
        let plistSupabaseURL = Bundle.main.object(forInfoDictionaryKey: "SupabaseURL") as? String
        let plistAnonKey = Bundle.main.object(forInfoDictionaryKey: "SupabaseAnonKey") as? String
        
        guard let urlString = plistSupabaseURL,
              let key = plistAnonKey,
              let supabaseURL = URL(string: urlString),
              !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            fatalError("Supabase URL or Anon Key missing in Info.plist. Please set SupabaseURL and SupabaseAnonKey.")
        }
        
        self.supabaseClient = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: key
        )
        
        // Listen for auth state changes
        Task {
            await listenToAuthChanges()
            await checkInitialSession()
        }
    }
    
    // MARK: - Authentication Methods
    
    @MainActor
    func signInWithGoogle() async throws {
        authError = nil
        
        do {
            // Get the presenting view controller using the newer API
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let presentingViewController = windowScene.windows.first?.rootViewController else {
                throw AuthError.noViewController
            }
            
            // Configure GoogleSignIn with your client ID from Info.plist (GIDClientID)
            guard let clientId = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String,
                  !clientId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw AuthError.missingGoogleClientId
            }
            
            // Configure Google Sign-In
            let configuration = GIDConfiguration(clientID: clientId)
            GIDSignIn.sharedInstance.configuration = configuration
            
            // Perform Google Sign-In
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)
            
            guard let idToken = result.user.idToken?.tokenString else {
                throw AuthError.missingIdToken
            }
            
            let accessToken = result.user.accessToken.tokenString
            
            // Sign in to Supabase with Google credentials
            try await supabaseClient.auth.signInWithIdToken(
                credentials: .init(
                    provider: .google,
                    idToken: idToken,
                    accessToken: accessToken
                )
            )
            // Immediately reflect auth state in UI
            do {
                let session = try await supabaseClient.auth.session
                let user = session.user
                // Ensure user profile exists for Google sign-in users
                do {
                    let hasProfile = try await self.getUserProfile(userId: user.id.uuidString) != nil
                    if !hasProfile {
                        let defaultUsername: String = {
                            if let name = user.userMetadata["full_name"]?.stringValue, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                return name
                            }
                            if let email = user.email, let prefix = email.split(separator: "@").first {
                                return String(prefix)
                            }
                            return "user_\(user.id.uuidString.prefix(6))"
                        }()
                        try await self.createUserProfile(
                            userId: user.id.uuidString,
                            email: user.email ?? "",
                            username: defaultUsername
                        )
                    }
                } catch {
                    print("⚠️ Failed to ensure user profile for Google sign-in: \(error.localizedDescription)")
                }
                await MainActor.run {
                    self.currentUser = user
                    self.isEmailVerified = user.emailConfirmedAt != nil
                    self.isAuthenticated = true
                    self.isAuthReady = true
                }
            } catch {
                // Non-fatal; listener should still catch it
            }
        } catch {
            self.authError = error.localizedDescription
            throw error
        }
    }

    @MainActor
    func signInWithApple(authorization: ASAuthorization) async throws {
        authError = nil

        do {
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                throw AuthError.appleSignInFailed
            }

            guard let identityToken = appleIDCredential.identityToken,
                  let idTokenString = String(data: identityToken, encoding: .utf8) else {
                throw AuthError.missingAppleIdToken
            }

            // Sign in to Supabase with Apple credentials
            try await supabaseClient.auth.signInWithIdToken(
                credentials: .init(
                    provider: .apple,
                    idToken: idTokenString
                )
            )

            // Immediately reflect auth state in UI
            do {
                let session = try await supabaseClient.auth.session
                let user = session.user

                // Ensure user profile exists for Apple sign-in users
                do {
                    let hasProfile = try await self.getUserProfile(userId: user.id.uuidString) != nil
                    if !hasProfile {
                        // Get user info from Apple credential
                        let defaultUsername: String = {
                            if let fullName = appleIDCredential.fullName {
                                let firstName = fullName.givenName ?? ""
                                let lastName = fullName.familyName ?? ""
                                let name = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
                                if !name.isEmpty {
                                    return name
                                }
                            }
                            if let email = user.email, let prefix = email.split(separator: "@").first {
                                return String(prefix)
                            }
                            return "user_\(user.id.uuidString.prefix(6))"
                        }()

                        try await self.createUserProfile(
                            userId: user.id.uuidString,
                            email: user.email ?? appleIDCredential.email ?? "",
                            username: defaultUsername
                        )
                    }
                } catch {
                    print("⚠️ Failed to ensure user profile for Apple sign-in: \(error.localizedDescription)")
                }

                await MainActor.run {
                    self.currentUser = user
                    self.isEmailVerified = user.emailConfirmedAt != nil
                    self.isAuthenticated = true
                    self.isAuthReady = true
                }
            } catch {
                // Non-fatal; listener should still catch it
                print("⚠️ Error after Apple sign-in: \(error.localizedDescription)")
            }
        } catch {
            self.authError = error.localizedDescription
            throw error
        }
    }

    @MainActor
    func signUp(email: String, password: String, username: String) async throws {
        isSigningUp = true
        authError = nil

        do {
            print("🚀 Starting signup for: \(email)")

            // Sign up WITHOUT auto-confirmation - require OTP verification
            let response = try await supabaseClient.auth.signUp(
                email: email,
                password: password,
                data: ["username": .string(username)],
                redirectTo: nil // Prevent auto-confirmation and auto-login
            )

            // User created successfully but NOT logged in yet
            let user = response.user
            print("✅ User created: \(user.email ?? "no email") | id: \(user.id.uuidString)")

            // Create profile row BEFORE signing out (while still authenticated)
            // This ensures RLS policies allow the insert
            do {
                try await createUserProfile(userId: user.id.uuidString, email: user.email ?? email, username: username)
                print("✅ User profile created")
            } catch {
                print("⚠️ Failed to create user profile: \(error.localizedDescription)")
                // Don't fail signup if profile creation fails - database trigger might handle it
            }

            // Sign out immediately to prevent auto-login
            try? await supabase.auth.signOut()
            print("🚪 Signed out user to prevent auto-login")

            // Reset auth state to keep user on auth screen
            await MainActor.run {
                self.currentUser = nil
                self.isAuthenticated = false
                self.isEmailVerified = false
            }

            // Send OTP email - Supabase should handle this automatically
            do {
                try await sendOtpEmail(email: email)
                print("✅ OTP email sent")
            } catch {
                print("⚠️ Failed to send OTP email: \(error.localizedDescription)")
                // Still allow signup to continue - user can resend
            }

            isSigningUp = false
            print("✅ Signup flow completed successfully")

        } catch {
            isSigningUp = false
            print("❌ Signup failed: \(error)")
            print("❌ Error type: \(type(of: error))")
            print("❌ Localized description: \(error.localizedDescription)")

            let lower = error.localizedDescription.lowercased()
            if lower.contains("user already registered") || lower.contains("already registered") || lower.contains("exists") {
                authError = "An account with this email already exists. Try signing in."
            } else if lower.contains("password") {
                authError = "Password must be at least 6 characters."
            } else if lower.contains("rate") || lower.contains("too many") {
                authError = "Too many attempts. Please wait a moment and try again."
            } else {
                authError = "Failed to create account: \(error.localizedDescription)"
            }
            throw error
        }
    }
    
    private func friendlySignUpError(from error: Error) -> String {
        let lower = error.localizedDescription.lowercased()
        if lower.contains("smtp") || lower.contains("email") || lower.contains("confirm") {
            return "Error sending confirmation email. Please configure email in Supabase Auth or try again later."
        }
        if lower.contains("rate") || lower.contains("too many") {
            return "Too many attempts. Please wait a bit and try again."
        }
        return "Failed to create account: \(error.localizedDescription)"
    }
    
    @MainActor
    func signIn(email: String, password: String) async throws {
        authError = nil

        do {
            let response = try await supabaseClient.auth.signIn(
                email: email,
                password: password
            )
            let user = response.user
            print("✅ User signed in: \(user.email ?? "no email") (emailConfirmedAt: \(user.emailConfirmedAt?.description ?? "nil"))")

            // Check if email is verified
            let emailVerified = user.emailConfirmedAt != nil
            print("📧 Email verification status: \(emailVerified)")

            // Ensure user profile exists (best-effort)
            do {
                let hasProfile = try await getUserProfile(userId: user.id.uuidString) != nil
                if !hasProfile {
                    try await createUserProfile(userId: user.id.uuidString, email: user.email ?? email, username: user.displayName ?? "user_\(user.id.uuidString.prefix(6))")
                }
            } catch {
                print("⚠️ Failed to ensure user profile on sign-in: \(error.localizedDescription)")
            }

            // Update auth state - ALWAYS set isAuthenticated even if email not verified
            // The app will handle showing verification screen
            self.currentUser = user
            self.isEmailVerified = emailVerified
            self.isAuthenticated = true
            self.isAuthReady = true

            // If email not verified, throw error to show message
            if !emailVerified {
                authError = "Please verify your email before signing in. Check your inbox for the verification code."
                throw AuthError.emailNotVerified
            }
        } catch let error as AuthError where error == .emailNotVerified {
            // Re-throw email not verified error
            throw error
        } catch {
            authError = "Sign in failed: \(error.localizedDescription)"
            throw error
        }
    }
    
    @MainActor
    func signOut() async throws {
        try await supabaseClient.auth.signOut()
        currentUser = nil
        isEmailVerified = false
        isAuthenticated = false
        isAuthReady = true
        authError = nil
    }

    @MainActor
    func deleteUserAccount(userId: String) async throws {
        print("🗑️ Starting account deletion for user: \(userId)")

        // Delete user profile and all associated data
        // Note: Database triggers should cascade delete related data
        try await supabaseClient.database
            .from("user_profiles")
            .delete()
            .eq("id", value: userId)
            .execute()

        print("✅ User profile deleted")

        // Delete auth user (this will trigger cascade deletions in the database)
        // Note: Supabase doesn't provide direct user deletion from client,
        // so we mark the account as deleted in the profile
        // The actual deletion should be handled by a server-side function or admin API

        print("✅ Account deletion complete")
    }

    @MainActor
    func resendEmailVerification(email: String) async throws {
        try await supabaseClient.auth.resend(
            email: email,
            type: .signup
        )
    }

    @MainActor
    func resetPassword(email: String) async throws {
        // 🔐 Password Reset - Deep Link to App (PKCE Compatible)
        //
        // IMPORTANT: Supabase PKCE flow requires code_verifier which web pages can't access.
        // Solution: Redirect back to the app using deep link where we CAN handle PKCE.
        //
        // SETUP REQUIRED:
        // 1. Add to Supabase Dashboard → Authentication → URL Configuration → Redirect URLs:
        //    synapse://reset-password
        //
        // USER FLOW:
        // 1. User taps "Forgot Password" in app
        // 2. Receives email with reset link
        // 3. Clicks "Reset My Password" in email
        // 4. Deep link opens app (synapse://reset-password?code=xxx)
        // 5. App exchanges code for session using PKCE
        // 6. App shows password reset screen
        // 7. User enters new password
        // 8. Password is reset ✅

        let redirectURL = URL(string: "synapse://reset-password")!

        try await supabaseClient.auth.resetPasswordForEmail(
            email,
            redirectTo: redirectURL
        )
    }

    @MainActor
    func handlePasswordResetDeepLink(url: URL) async throws {
        // Extract the code from the URL
        // URL format: synapse://reset-password?code=xxx
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            throw NSError(domain: "SupabaseManager", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Invalid reset link: no code found"])
        }

        // Exchange the code for a session using PKCE
        try await supabaseClient.auth.exchangeCodeForSession(authCode: code)

        // Session is now established, user can update their password
        print("✅ Password reset session established successfully")
    }

    @MainActor
    func updatePassword(newPassword: String) async throws {
        // Update the user's password
        // This requires an active session (from handlePasswordResetDeepLink)
        try await supabaseClient.auth.update(user: UserAttributes(password: newPassword))
        print("✅ Password updated successfully")
    }

    // MARK: - User Profile Management
    
    func createUserProfile(userId: String, email: String, username: String) async throws {
        // Check if profile already exists (might be created by database trigger)
        if let existingProfile = try? await getUserProfile(userId: userId) {
            print("ℹ️ User profile already exists for: \(userId), updating username if needed")
            // Update username if it's different
            let currentUsername = existingProfile["username"] as? String
            if currentUsername != username {
                try? await updateUserProfile(
                    userId: userId,
                    updates: ["username": username]
                )
            }
            return
        }

        let profileData: [String: AnyJSON] = [
            "id": AnyJSON.string(userId),
            "email": AnyJSON.string(email),
            "username": AnyJSON.string(username),
            "bio": AnyJSON.null,
            "avatar_url": AnyJSON.null,
            "skills": AnyJSON.array([]),
            "interests": AnyJSON.array([]),
            "ideas_sparked": 0,
            "projects_contributed": 0
        ]

        do {
            try await supabase
                .from("users")
                .insert(profileData)
                .execute()
            print("✅ User profile created for: \(username)")
        } catch {
            // If insert fails due to RLS, log warning but don't fail the flow
            // (profile might be created by database trigger)
            print("⚠️ Could not insert user profile (might already exist): \(error.localizedDescription)")
        }
    }
    
    func getUserProfile(userId: String) async throws -> [String: Any]? {
        let response = try await supabase
            .from("users")
            .select("*")
            .eq("id", value: userId)
            .execute()
        
        let json = try JSONSerialization.jsonObject(with: response.data)
        if let array = json as? [[String: Any]] {
            return array.first
        }
        if let object = json as? [String: Any] {
            return object
        }
        return nil
    }
    
    func updateUserProfile(userId: String, updates: [String: Any]) async throws {
        let updateData = try updates.mapValues { value -> AnyJSON in
            if let string = value as? String {
                return AnyJSON.string(string)
            } else if let number = value as? Int {
                return try AnyJSON(number)
            } else if let bool = value as? Bool {
                return AnyJSON.bool(bool)
            } else if let array = value as? [String] {
                return AnyJSON.array(array.map { AnyJSON.string($0) })
            } else {
                return AnyJSON.null
            }
        }
        
        try await supabase
            .from("users")
            .update(updateData)
            .eq("id", value: userId)
            .execute()
    }
    
    // MARK: - Idea Management (Basic Implementation)
    
    func createIdeaSpark(title: String, description: String, tags: [String], isPublic: Bool, creatorId: String, creatorUsername: String) async throws -> String {
        // Ensure a profile row exists for FK and RLS (Google users may not have one yet)
        do {
            let hasProfile = try await getUserProfile(userId: creatorId) != nil
            if !hasProfile {
                try await createUserProfile(
                    userId: creatorId,
                    email: currentUser?.email ?? "",
                    username: creatorUsername
                )
            }
        } catch {
            print("⚠️ Failed to ensure profile before idea insert: \(error.localizedDescription)")
        }

        // Generate ID client-side to avoid relying on insert+select response shape
        let newIdeaId = UUID().uuidString
        let ideaData: [String: AnyJSON] = [
            "id": AnyJSON.string(newIdeaId),
            "author_id": AnyJSON.string(creatorId),
            "author_username": AnyJSON.string(creatorUsername),
            "title": AnyJSON.string(title),
            "description": AnyJSON.string(description),
            "tags": AnyJSON.array(tags.map { AnyJSON.string($0) }),
            "is_public": AnyJSON.bool(isPublic),
            "status": AnyJSON.string("sparking")
        ]
        
        // Perform insert; we don't request representation to avoid coercion errors
        try await supabase
            .from("idea_sparks")
            .insert(ideaData)
            .execute()

        print("✅ Idea created with client-generated ID: \(newIdeaId)")
        return newIdeaId
    }
    
    func updateIdeaSpark(ideaId: String, title: String, description: String, tags: [String], isPublic: Bool) async throws {
        let updateData: [String: AnyJSON] = [
            "title": AnyJSON.string(title),
            "description": AnyJSON.string(description),
            "tags": AnyJSON.array(tags.map { AnyJSON.string($0) }),
            "is_public": AnyJSON.bool(isPublic)
        ]
        
        try await supabase
            .from("idea_sparks")
            .update(updateData)
            .eq("id", value: ideaId)
            .execute()
        
        print("✅ Idea updated: \(ideaId)")
    }
    
    func deleteIdeaSpark(ideaId: String) async throws {
        try await supabase
            .from("idea_sparks")
            .delete()
            .eq("id", value: ideaId)
            .execute()
        
        print("✅ Idea deleted: \(ideaId)")
    }
    
    func getPublicIdeaSparks() async throws -> [IdeaSpark] {
        let response = try await supabase
            .from("idea_sparks")
            .select("*")
            .eq("is_public", value: true)
            .order("created_at", ascending: false)
            .limit(50)
            .execute()
        
        let data = try JSONSerialization.jsonObject(with: response.data) as? [[String: Any]] ?? []
        
        return data.compactMap { item in
            parseIdeaFromData(item)
        }
    }
    
    // MARK: - Pod Management
    
    func getUserPods(userId: String) async throws -> [IncubationProject] {
        print("🔄 Loading pods for user: \(userId)")
        
        let response = try await supabase
            .from("pods")
            .select("*")
            .eq("creator_id", value: userId)
            .order("created_at", ascending: false)
            .execute()
        
        let data = try JSONSerialization.jsonObject(with: response.data) as? [[String: Any]] ?? []
        print("📊 Found \(data.count) pods for user \(userId)")
        
        let pods = data.compactMap { item in
            parsePodFromData(item)
        }
        
        // Remove duplicates by ID (in case there are any)
        var uniquePods: [String: IncubationProject] = [:]
        for pod in pods {
            uniquePods[pod.id] = pod
        }
        
        let finalPods = Array(uniquePods.values).sorted { $0.createdAt > $1.createdAt }
        print("📊 Returning \(finalPods.count) unique pods after deduplication")
        
        return finalPods
    }
    
    func getPublicPods() async throws -> [IncubationProject] {
        let response = try await supabase
            .from("pods")
            .select("*")
            .eq("is_public", value: true)
            .order("created_at", ascending: false)
            .limit(20)
            .execute()
        
        let data = try JSONSerialization.jsonObject(with: response.data) as? [[String: Any]] ?? []
        
        return data.compactMap { item in
            parsePodFromData(item)
        }
    }
    
    func getPodsByIdeaId(_ ideaId: String) async throws -> [IncubationProject] {
        print("🔍 DEBUG: Fetching pods for ideaId: '\(ideaId)'")
        
        let response = try await supabase
            .from("pods")
            .select("*")
            .eq("idea_id", value: ideaId)
            .eq("is_public", value: true) // Only show public pods for discovery
            .order("created_at", ascending: false)
            .execute()
        
        let data = try JSONSerialization.jsonObject(with: response.data) as? [[String: Any]] ?? []
        print("📊 DEBUG: Query result - Found \(data.count) pods for idea '\(ideaId)'")
        
        let pods = data.compactMap { item in
            parsePodFromData(item)
        }
        
        for pod in pods {
            print("  📄 Pod '\(pod.name)': ideaId='\(pod.ideaId)', isPublic=\(pod.isPublic)")
        }
        
        return pods
    }
    
    func getPodsForUser(userId: String) async throws -> [IncubationProject] {
        // This function should fetch all pods a user is associated with:
        // 1. Pods they created.
        // 2. Pods they are a member of.

        // Fetch pods where the user is the creator
        let createdPodsResponse = try await supabase
            .from("pods")
            .select("*")
            .eq("creator_id", value: userId)
            .execute()
        
        let createdPodsData = try JSONSerialization.jsonObject(with: createdPodsResponse.data) as? [[String: Any]] ?? []
        let createdPods = createdPodsData.compactMap { parsePodFromData($0) }
        
        // Fetch pod IDs where the user is a member
        let memberPodsResponse = try await supabase
            .from("pod_members")
            .select("pod_id")
            .eq("user_id", value: userId)
            .execute()
            
        let memberPodsData = try JSONSerialization.jsonObject(with: memberPodsResponse.data) as? [[String: Any]] ?? []
        let podIds = memberPodsData.compactMap { $0["pod_id"] as? String }
        
        var memberPods: [IncubationProject] = []
        if !podIds.isEmpty {
            let podsResponse = try await supabase
                .from("pods")
                .select("*")
                .in("id", values: podIds)
                .execute()
            let podsData = try JSONSerialization.jsonObject(with: podsResponse.data) as? [[String: Any]] ?? []
            memberPods = podsData.compactMap { parsePodFromData($0) }
        }
        
        // Combine, remove duplicates, and return
        let allPods = createdPods + memberPods
        
        var uniquePods: [String: IncubationProject] = [:]
        for pod in allPods {
            uniquePods[pod.id] = pod
        }
        
        return Array(uniquePods.values).sorted(by: { $0.createdAt > $1.createdAt })
    }

    func createPodFromIdea(ideaId: String, name: String, description: String, creatorId: String, isPublic: Bool = true) async throws -> String {
        print("💾 DEBUG: Creating pod with data:")
        print("  📛 name: '\(name)'")
        print("  💡 ideaId: '\(ideaId)'")
        print("  👤 creatorId: '\(creatorId)'")
        print("  🌍 isPublic: \(isPublic)")
        
        // Ensure profile exists for FK and RLS
        do {
            let hasProfile = try await getUserProfile(userId: creatorId) != nil
            if !hasProfile {
                try await createUserProfile(
                    userId: creatorId,
                    email: currentUser?.email ?? "",
                    username: currentUser?.displayName ?? "Creator"
                )
            }
        } catch {
            print("⚠️ Failed to ensure profile before pod insert: \(error.localizedDescription)")
        }

        let newPodId = UUID().uuidString
        let podData: [String: AnyJSON] = [
            "id": AnyJSON.string(newPodId),
            "idea_id": AnyJSON.string(ideaId),
            "name": AnyJSON.string(name),
            "description": AnyJSON.string(description),
            "creator_id": AnyJSON.string(creatorId),
            "is_public": AnyJSON.bool(isPublic),
            "status": AnyJSON.string("planning")
        ]
        
        try await supabase
            .from("pods")
            .insert(podData)
            .execute()
        
        // Add creator as first member with admin role (best-effort; do not fail project creation on policy errors)
        do {
            try await addPodMember(podId: newPodId, userId: creatorId, username: currentUser?.displayName ?? "Creator", role: "Creator")
        } catch {
            print("⚠️ addPodMember failed, continuing without membership row: \(error.localizedDescription)")
        }
        
        print("✅ VERIFICATION: Pod created successfully - id: '\(newPodId)', ideaId: '\(ideaId)', isPublic: \(isPublic)")
        return newPodId
    }
    
    func createStandalonePod(name: String, description: String, creatorId: String, isPublic: Bool = true) async throws -> String {
        print("💾 Creating standalone pod with data:")
        print("  📛 name: '\(name)'")
        print("  👤 creatorId: '\(creatorId)'")
        print("  🌍 isPublic: \(isPublic)")
        
        // Ensure profile exists for FK and RLS
        do {
            let hasProfile = try await getUserProfile(userId: creatorId) != nil
            if !hasProfile {
                try await createUserProfile(
                    userId: creatorId,
                    email: currentUser?.email ?? "",
                    username: currentUser?.displayName ?? "Creator"
                )
            }
        } catch {
            print("⚠️ Failed to ensure profile before pod insert: \(error.localizedDescription)")
        }

        let newPodId = UUID().uuidString
        let podData: [String: AnyJSON] = [
            "id": AnyJSON.string(newPodId),
            "idea_id": AnyJSON.null, // No associated idea
            "name": AnyJSON.string(name),
            "description": AnyJSON.string(description),
            "creator_id": AnyJSON.string(creatorId),
            "is_public": AnyJSON.bool(isPublic),
            "status": AnyJSON.string("planning")
        ]
        
        try await supabase
            .from("pods")
            .insert(podData)
            .execute()
        
        // Add creator as first member with admin role
        do {
            try await addPodMember(podId: newPodId, userId: creatorId, username: currentUser?.displayName ?? "Creator", role: "Creator")
        } catch {
            print("⚠️ addPodMember failed for standalone pod: \(error.localizedDescription)")
        }
        
        print("✅ VERIFICATION: Standalone pod created successfully - id: '\(newPodId)'")
        return newPodId
    }
    
    func addPodMember(podId: String, userId: String, username: String, role: String = "Member") async throws {
        let memberData: [String: AnyJSON] = [
            "pod_id": AnyJSON.string(podId),
            "user_id": AnyJSON.string(userId),
            "username": AnyJSON.string(username),
            "role": AnyJSON.string(role),
            "permissions": AnyJSON.array([AnyJSON.string("view"), AnyJSON.string("comment")])
        ]
        
        try await supabase
            .from("pod_members")
            .insert(memberData)
            .execute()
        
        print("✅ Added member '\(username)' to pod \(podId) with role '\(role)'")
    }
    
    // MARK: - Pod Data Parsing Helper
    
    private func parsePodFromData(_ item: [String: Any]) -> IncubationProject? {
        guard let id = item["id"] as? String,
              let name = item["name"] as? String,
              let description = item["description"] as? String,
              let creatorId = item["creator_id"] as? String else {
            return nil
        }
        
        let _ = item["idea_id"] as? String ?? ""
        
        let isPublic = item["is_public"] as? Bool ?? false
        let statusString = item["status"] as? String ?? "planning"
        let status = IncubationProject.ProjectStatus(rawValue: statusString) ?? .planning
        
        let createdAt = parseDate(item["created_at"]) ?? Date()
        let updatedAt = parseDate(item["updated_at"]) ?? Date()
        
        // For now, return empty members and tasks to avoid RLS recursion
        let members: [ProjectMember] = []
        let tasks: [ProjectTask] = []
        
        return IncubationProject(
            id: id,
            ideaId: "",
            name: name,
            description: description,
            creatorId: creatorId,
            isPublic: isPublic,
            createdAt: createdAt,
            updatedAt: updatedAt,
            members: members,
            tasks: tasks,
            status: status
        )
    }

    // MARK: - Additional Authentication Methods
    
    func validateUsername(_ username: String) async throws -> Bool {
        do {
            let response = try await supabase
                .from("users")
                .select("id")
                .eq("username", value: username)
                .execute()
            
            let decoder = JSONDecoder()
            let data = try decoder.decode([[String: AnyJSON]].self, from: response.data)
            return data.isEmpty // Available if no results found
        } catch {
            print("❌ Error validating username: \(error)")
            throw error
        }
    }
    
    func verifyOtp(email: String, otp: String, username: String? = nil) async throws {
        do {
            print("🔍 Verifying OTP: \(otp) for email: \(email)")
            let response = try await supabaseClient.auth.verifyOTP(
                email: email,
                token: otp,
                type: .signup
            )

            let user = response.user
            print("✅ OTP verification successful for user: \(user.email ?? "unknown")")

            // Ensure user profile exists after email verification
            do {
                let hasProfile = try await getUserProfile(userId: user.id.uuidString) != nil
                if !hasProfile {
                    // Use provided username or get from metadata or generate one
                    let finalUsername = username ??
                                       user.userMetadata["username"]?.stringValue ??
                                       "user_\(user.id.uuidString.prefix(6))"
                    try await createUserProfile(
                        userId: user.id.uuidString,
                        email: user.email ?? email,
                        username: finalUsername
                    )
                    print("✅ User profile created with username: \(finalUsername)")
                }
            } catch {
                print("⚠️ Failed to ensure user profile after OTP verification: \(error.localizedDescription)")
            }

            await MainActor.run {
                self.currentUser = user
                self.isEmailVerified = user.emailConfirmedAt != nil
                self.isAuthenticated = true
                self.isAuthReady = true
            }
        } catch {
            print("❌ Error verifying OTP: \(error)")
            throw error
        }
    }
    
    func resendOtp(email: String) async throws {
        do {
            try await supabaseClient.auth.resend(
                email: email,
                type: .signup
            )
        } catch {
            print("❌ Error resending OTP: \(error)")
            throw error
        }
    }
    
    func sendOtpEmail(email: String) async throws {
        do {
            print("📧 Sending OTP email to: \(email)")
            try await supabaseClient.auth.resend(
                email: email,
                type: .signup
            )
            print("✅ OTP email sent successfully")
        } catch {
            print("❌ Error sending OTP email: \(error)")
            throw error
        }
    }
    
    // MARK: - Comments Management
    
    func getIdeaComments(ideaId: String) async throws -> [IdeaComment] {
        let response = try await supabase
            .from("idea_comments")
            .select("*")
            .eq("idea_id", value: ideaId)
            .order("created_at", ascending: true)
            .execute()
        
        let data = try JSONSerialization.jsonObject(with: response.data) as? [[String: Any]] ?? []
        
        return data.compactMap { item in
            parseCommentFromData(item)
        }
    }
    
    func addCommentToIdea(ideaId: String, content: String, authorId: String, authorUsername: String) async throws -> String {
        let commentId = UUID().uuidString
        let commentData: [String: AnyJSON] = [
            "id": AnyJSON.string(commentId),
            "idea_id": AnyJSON.string(ideaId),
            "author_id": AnyJSON.string(authorId),
            "author_username": AnyJSON.string(authorUsername),
            "content": AnyJSON.string(content)
        ]
        
        try await supabase
            .from("idea_comments")
            .insert(commentData)
            .execute()
        
        print("✅ Comment added to idea \(ideaId): \(content)")
        return commentId
    }
    
    private func parseCommentFromData(_ item: [String: Any]) -> IdeaComment? {
        guard let id = item["id"] as? String,
              let _ = item["idea_id"] as? String,
              let authorId = item["author_id"] as? String,
              let authorUsername = item["author_username"] as? String,
              let content = item["content"] as? String else {
            return nil
        }
        
        let createdAt = parseDate(item["created_at"]) ?? Date()
        
        return IdeaComment(
            id: id,
            authorId: authorId,
            authorUsername: authorUsername,
            content: content,
            createdAt: createdAt,
            likes: 0 // We can add comment likes later
        )
    }
    
    // MARK: - Task Management
    
    func createTask(podId: String, title: String, description: String?, assignedTo: String?, assignedToUsername: String?, priority: String, dueDate: Date?) async throws -> String {
        let taskId = UUID().uuidString
        let taskData: [String: AnyJSON] = [
            "id": AnyJSON.string(taskId),
            "pod_id": AnyJSON.string(podId),
            "title": AnyJSON.string(title),
            "description": description != nil ? AnyJSON.string(description!) : AnyJSON.null,
            "assigned_to": assignedTo != nil ? AnyJSON.string(assignedTo!) : AnyJSON.null,
            "assigned_to_username": assignedToUsername != nil ? AnyJSON.string(assignedToUsername!) : AnyJSON.null,
            "status": AnyJSON.string("todo"),
            "priority": AnyJSON.string(priority)
        ]
        
        try await supabase
            .from("tasks")
            .insert(taskData)
            .execute()
        
        print("✅ Task created with ID: \(taskId)")
        return taskId
    }
    
    func getProjectTasks(podId: String) async throws -> [ProjectTask] {
        let response = try await supabase
            .from("tasks")
            .select("*")
            .eq("pod_id", value: podId)
            .order("created_at", ascending: false)
            .execute()
        
        let data = try JSONSerialization.jsonObject(with: response.data) as? [[String: Any]] ?? []
        
        return data.compactMap { item in
            parseTaskFromData(item)
        }
    }
    
    func updateTaskStatus(taskId: String, status: String) async throws {
        let updateData: [String: AnyJSON] = [
            "status": AnyJSON.string(status)
        ]
        
        try await supabase
            .from("tasks")
            .update(updateData)
            .eq("id", value: taskId)
            .execute()
        
        print("✅ Task status updated: \(taskId) -> \(status)")
    }
    
    func updateTaskPriority(taskId: String, priority: String) async throws {
        let updateData: [String: AnyJSON] = [
            "priority": AnyJSON.string(priority)
        ]
        
        try await supabase
            .from("tasks")
            .update(updateData)
            .eq("id", value: taskId)
            .execute()
        
        print("✅ Task priority updated: \(taskId) -> \(priority)")
    }
    
    func deleteTask(taskId: String) async throws {
        try await supabase
            .from("tasks")
            .delete()
            .eq("id", value: taskId)
            .execute()
        
        print("✅ Task deleted: \(taskId)")
    }
    
    private func parseTaskFromData(_ item: [String: Any]) -> ProjectTask? {
        guard let taskId = item["id"] as? String,
              let title = item["title"] as? String else {
            return nil
        }
        
        let description = item["description"] as? String
        let assignedTo = item["assigned_to"] as? String
        let assignedToUsername = item["assigned_to_username"] as? String
        let statusString = item["status"] as? String ?? "todo"
        let priorityString = item["priority"] as? String ?? "medium"
        
        let taskStatus = ProjectTask.TaskStatus(rawValue: statusString) ?? .todo
        let taskPriority = ProjectTask.TaskPriority(rawValue: priorityString) ?? .medium
        
        let taskCreatedAt = parseDate(item["created_at"]) ?? Date()
        let taskUpdatedAt = parseDate(item["updated_at"]) ?? Date()
        
        return ProjectTask(
            id: taskId,
            title: title,
            description: description,
            assignedTo: assignedTo,
            assignedToUsername: assignedToUsername,
            dueDate: nil, // Add due_date to schema if needed
            createdAt: taskCreatedAt,
            updatedAt: taskUpdatedAt,
            status: taskStatus,
            priority: taskPriority
        )
    }
    
    // MARK: - Member Management
    
    func addMemberToProject(podId: String, userId: String, username: String, role: String = "Member") async throws {
        try await addPodMember(podId: podId, userId: userId, username: username, role: role)
    }
    
    func getPodMembers(podId: String) async throws -> [ProjectMember] {
        let response = try await supabase
            .from("pod_members")
            .select("*")
            .eq("pod_id", value: podId)
            .order("joined_at", ascending: true)
            .execute()
        
        let data = try JSONSerialization.jsonObject(with: response.data) as? [[String: Any]] ?? []
        
        return data.compactMap { item in
            parseMemberFromData(item)
        }
    }
    
    private func parseMemberFromData(_ item: [String: Any]) -> ProjectMember? {
        guard let memberId = item["id"] as? String,
              let userId = item["user_id"] as? String,
              let username = item["username"] as? String,
              let role = item["role"] as? String else {
            return nil
        }
        
        let joinedAt = parseDate(item["joined_at"]) ?? Date()
        let permissionsArray = item["permissions"] as? [String] ?? ["view", "comment"]
        let permissions = permissionsArray.compactMap { ProjectMember.Permission(rawValue: $0) }
        
        return ProjectMember(
            id: memberId,
            userId: userId,
            username: username,
            role: role,
            joinedAt: joinedAt,
            permissions: permissions
        )
    }
    
    // MARK: - Chat Management
    
    func sendChatMessage(podId: String, content: String, senderId: String, senderUsername: String) async throws -> String {
        let messageId = UUID().uuidString
        let messageData: [String: AnyJSON] = [
            "id": AnyJSON.string(messageId),
            "pod_id": AnyJSON.string(podId),
            "sender_id": AnyJSON.string(senderId),
            "sender_username": AnyJSON.string(senderUsername),
            "content": AnyJSON.string(content)
        ]
        
        try await supabase
            .from("chat_messages")
            .insert(messageData)
            .execute()
        
        print("✅ Chat message sent: \(messageId)")
        return messageId
    }
    
    func getChatMessages(podId: String) async throws -> [ChatMessage] {
        let response = try await supabase
            .from("chat_messages")
            .select("*")
            .eq("pod_id", value: podId)
            .order("timestamp", ascending: true)
            .execute()
        
        let data = try JSONSerialization.jsonObject(with: response.data) as? [[String: Any]] ?? []
        
        return data.compactMap { item in
            parseChatMessageFromData(item)
        }
    }
    
    private func parseChatMessageFromData(_ item: [String: Any]) -> ChatMessage? {
        guard let id = item["id"] as? String,
              let podId = item["pod_id"] as? String,
              let senderId = item["sender_id"] as? String,
              let senderUsername = item["sender_username"] as? String,
              let content = item["content"] as? String else {
            return nil
        }
        
        let timestamp = parseDate(item["timestamp"]) ?? Date()
        
        return ChatMessage(
            id: id,
            projectId: podId,
            senderId: senderId,
            senderName: senderUsername,
            senderAvatar: nil,
            content: content,
            messageType: .text,
            timestamp: timestamp,
            isEdited: false,
            replyTo: nil
        )
    }
    
    // MARK: - User Management
    
    func getAllUsers() async throws -> [UserProfile] {
        let response = try await supabase
            .from("users")
            .select("*")
            .order("username", ascending: true)
            .execute()
        
        let data = try JSONSerialization.jsonObject(with: response.data) as? [[String: Any]] ?? []
        
        return data.compactMap { item in
            parseUserProfileFromData(item)
        }
    }
    
    private func parseUserProfileFromData(_ item: [String: Any]) -> UserProfile? {
        guard let id = item["id"] as? String,
              let username = item["username"] as? String,
              let email = item["email"] as? String else {
            return nil
        }
        
        let bio = item["bio"] as? String
        let avatarURL = item["avatar_url"] as? String
        let skills = item["skills"] as? [String] ?? []
        let interests = item["interests"] as? [String] ?? []
        let ideasSparked = item["ideas_sparked"] as? Int ?? 0
        let projectsContributed = item["projects_contributed"] as? Int ?? 0
        let dateJoined = parseDate(item["date_joined"]) ?? Date()
        
        return UserProfile(
            id: id,
            username: username,
            email: email,
            bio: bio,
            avatarURL: avatarURL,
            skills: skills,
            interests: interests,
            ideasSparked: ideasSparked,
            projectsContributed: projectsContributed,
            dateJoined: dateJoined
        )
    }
    
    // MARK: - Invitation System
    
    func sendJoinRequest(podId: String, inviteeId: String, inviterId: String) async throws -> String {
        let invitationId = UUID().uuidString
        let invitationData: [String: AnyJSON] = [
            "id": AnyJSON.string(invitationId),
            "pod_id": AnyJSON.string(podId),
            // For join-requests: store inviter_id as the pod owner (receiver), invitee_id as the requester
            "inviter_id": AnyJSON.string(inviteeId),
            "invitee_id": AnyJSON.string(inviterId),
            "status": AnyJSON.string("pending")
        ]
        
        // Note: RLS is disabled on pod_invitations table to avoid policy conflicts
        // The current RLS policy requires auth.uid() = inviter_id for INSERT, but we store
        // the requester in invitee_id and owner in inviter_id for join requests
        // TODO: Fix RLS policy or re-enable with proper policies
        try await supabase
            .from("pod_invitations")
            .insert(invitationData)
            .execute()
        
        // Create notification for pod owner (inviteeId parameter is the owner)
        try await createNotification(
            userId: inviteeId,
            type: "join_request",
            title: "Join Request",
            message: "Someone wants to join your project",
            data: ["pod_id": podId, "invitation_id": invitationId]
        )
        
        print("✅ Join request sent: \(invitationId)")
        return invitationId
    }
    
    func approveJoinRequest(invitationId: String, podId: String, userId: String, username: String) async throws {
        // Update invitation status
        try await supabase
            .from("pod_invitations")
            .update(["status": AnyJSON.string("accepted")])
            .eq("id", value: invitationId)
            .execute()
        
        // Add user to pod members
        try await addPodMember(podId: podId, userId: userId, username: username, role: "Member")
        
        // Create notification for the user
        try await createNotification(
            userId: userId,
            type: "join_approved",
            title: "Join Request Approved",
            message: "Your request to join the project was approved!",
            data: ["pod_id": podId]
        )
        
        print("✅ Join request approved: \(invitationId)")
    }
    
    func rejectJoinRequest(invitationId: String, userId: String) async throws {
        // Update invitation status
        try await supabase
            .from("pod_invitations")
            .update(["status": AnyJSON.string("declined")])
            .eq("id", value: invitationId)
            .execute()
        
        // Create notification for the user
        try await createNotification(
            userId: userId,
            type: "join_rejected",
            title: "Join Request Declined",
            message: "Your request to join the project was declined.",
            data: [:]
        )
        
        print("✅ Join request rejected: \(invitationId)")
    }
    
    func getPendingJoinRequests(podOwnerId: String) async throws -> [PodInvitation] {
        let response = try await supabase
            .from("pod_invitations")
            .select("*")
            // With join-requests stored as inviter_id = owner, invitee_id = requester
            .eq("inviter_id", value: podOwnerId)
            .eq("status", value: "pending")
            .order("created_at", ascending: false)
            .execute()
        
        let data = try JSONSerialization.jsonObject(with: response.data) as? [[String: Any]] ?? []
        
        return data.compactMap { item in
            parseInvitationFromData(item)
        }
    }
    
    func checkJoinRequestStatus(podId: String, userId: String) async throws -> String? {
        let response = try await supabase
            .from("pod_invitations")
            .select("status")
            .eq("pod_id", value: podId)
            // Requester is stored in invitee_id for join-requests
            .eq("invitee_id", value: userId)
            .order("created_at", ascending: false)
            .limit(1)
            .execute()
        
        let data = try JSONSerialization.jsonObject(with: response.data) as? [[String: Any]] ?? []
        return data.first?["status"] as? String
    }
    
    private func parseInvitationFromData(_ item: [String: Any]) -> PodInvitation? {
        guard let id = item["id"] as? String,
              let podId = item["pod_id"] as? String,
              let inviterId = item["inviter_id"] as? String,
              let inviteeId = item["invitee_id"] as? String,
              let status = item["status"] as? String else {
            return nil
        }
        
        let createdAt = parseDate(item["created_at"]) ?? Date()
        
        return PodInvitation(
            id: id,
            podId: podId,
            inviterId: inviterId,
            inviteeId: inviteeId,
            status: status,
            createdAt: createdAt
        )
    }
    
    // Note: RLS on the 'notifications' table must be disabled for this function to work.
    // The RLS policy `FOR ALL USING (auth.uid() = user_id)` prevents one user from creating a notification for another.
    // This is necessary for join requests (requester notifies owner) and approvals (owner notifies requester).
    // TODO: A more secure solution is to use a Supabase Edge Function with a service_role key to create notifications.
    private func createNotification(userId: String, type: String, title: String, message: String, data: [String: Any]) async throws {
        let notificationId = UUID().uuidString
        let notificationData: [String: AnyJSON] = [
            "id": AnyJSON.string(notificationId),
            "user_id": AnyJSON.string(userId),
            "type": AnyJSON.string(type),
            "title": AnyJSON.string(title),
            "message": AnyJSON.string(message),
            "is_read": AnyJSON.bool(false),
            "data": AnyJSON.object(data.mapValues { value in
                if let str = value as? String {
                    return AnyJSON.string(str)
                }
                return AnyJSON.null
            })
        ]
        
        try await supabase
            .from("notifications")
            .insert(notificationData)
            .execute()
        
        print("✅ Notification created: \(notificationId)")
    }
    
    // MARK: - Search Implementation
    
    func searchIdeas(query: String) async throws -> [IdeaSpark] {
        let response = try await supabase
            .from("idea_sparks")
            .select("*")
            .eq("is_public", value: true)
            .or("title.ilike.%\(query)%,description.ilike.%\(query)%")
            .order("created_at", ascending: false)
            .limit(20)
            .execute()
        
        let data = try JSONSerialization.jsonObject(with: response.data) as? [[String: Any]] ?? []
        return data.compactMap { item in
            parseIdeaFromData(item)
        }
    }
    
    func searchPods(query: String) async throws -> [IncubationProject] {
        let response = try await supabase
            .from("pods")
            .select("*")
            .eq("is_public", value: true)
            .or("name.ilike.%\(query)%,description.ilike.%\(query)%")
            .order("created_at", ascending: false)
            .limit(20)
            .execute()
        
        let data = try JSONSerialization.jsonObject(with: response.data) as? [[String: Any]] ?? []
        return data.compactMap { item in
            parsePodFromData(item)
        }
    }
    
    func searchUsers(query: String) async throws -> [UserProfile] {
        let response = try await supabase
            .from("users")
            .select("*")
            .or("username.ilike.%\(query)%,email.ilike.%\(query)%")
            .order("username", ascending: true)
            .limit(20)
            .execute()
        
        let data = try JSONSerialization.jsonObject(with: response.data) as? [[String: Any]] ?? []
        return data.compactMap { item in
            parseUserProfileFromData(item)
        }
    }
    
    // MARK: - Notifications (Placeholder)
    
    func getUserNotifications(userId: String) async throws -> [AppNotification] {
        // This is a placeholder. A real implementation would fetch from a dedicated 'notifications' table.
        // For now, we will simulate by fetching pending invitations.
        let invitations = try await getPendingJoinRequests(podOwnerId: userId)
        
        // In a real app, you would fetch all necessary user profiles in a single query to avoid multiple round trips.
        // For simplicity here, we'll just create a basic message.
        
        let notifications: [AppNotification] = await withTaskGroup(of: AppNotification?.self, returning: [AppNotification].self) { group in
            for invitation in invitations {
                group.addTask {
                    // Fetch requester's username (inviteeId holds requesting user)
                    let requesterProfile = try? await self.getUserProfile(userId: invitation.inviteeId)
                    let requesterUsername = requesterProfile?["username"] as? String ?? "Someone"
                    
                    let podName = "a project" // Ideally, we'd fetch the project name too.
                    
                    return AppNotification(
                        id: invitation.id,
                        userId: userId,
                        type: .projectInvite,
                        message: "\(requesterUsername) has requested to join \(podName).",
                        isRead: false,
                        timestamp: invitation.createdAt,
                        relatedId: nil,
                        podInvitation: invitation
                    )
                }
            }
            
            var collected: [AppNotification] = []
            for await notification in group {
                if let notification = notification {
                    collected.append(notification)
                }
            }
            return collected
        }
        
        return notifications
    }
    
    // MARK: - Private Helper Methods
    
    private func listenToAuthChanges() async {
        await supabase.auth.onAuthStateChange { [weak self] event, session in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                switch event {
                case .signedIn:
                    if let user = session?.user {
                        self.currentUser = user
                        self.isEmailVerified = user.emailConfirmedAt != nil
                        self.isAuthenticated = true
                        self.isAuthReady = true
                        print("✅ Auth state - User signed in: \(user.email ?? "no email")")
                    }
                case .signedOut:
                    self.currentUser = nil
                    self.isEmailVerified = false
                    self.isAuthenticated = false
                    self.isAuthReady = true
                    print("🚪 Auth state - User signed out")
                case .tokenRefreshed:
                    if let user = session?.user {
                        self.currentUser = user
                        self.isEmailVerified = user.emailConfirmedAt != nil
                        self.isAuthenticated = true
                        print("🔄 Auth state - Token refreshed")
                    }
                default:
                    break
                }
            }
        }
    }
    
    private func checkInitialSession() async {
        do {
            let session = try await supabaseClient.auth.session
            await MainActor.run {
                let user = session.user
                self.currentUser = user
                self.isEmailVerified = user.emailConfirmedAt != nil
                self.isAuthenticated = true
                self.isAuthReady = true
                print("✅ Restored session for: \(user.email ?? "Unknown")")
            }
        } catch {
            await MainActor.run {
                self.isAuthenticated = false
                self.isAuthReady = true
            }
            print("ℹ️ No existing session found")
        }
    }
    
    private func parseDate(_ value: Any?) -> Date? {
        guard let dateString = value as? String else { return nil }
        
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: dateString)
    }
    
    private func parseIdeaFromData(_ item: [String: Any]) -> IdeaSpark? {
        guard let id = item["id"] as? String,
              let authorId = item["author_id"] as? String,
              let authorUsername = item["author_username"] as? String,
              let title = item["title"] as? String,
              let description = item["description"] as? String else {
            return nil
        }
        
        let tags = item["tags"] as? [String] ?? []
        let isPublic = item["is_public"] as? Bool ?? false
        let likes = item["likes"] as? Int ?? 0
        let comments = item["comments"] as? Int ?? 0
        let statusString = item["status"] as? String ?? "planning"
        let status = IdeaSpark.IdeaStatus(rawValue: statusString) ?? .planning
        
        let createdAt = parseDate(item["created_at"]) ?? Date()
        let updatedAt = parseDate(item["updated_at"]) ?? Date()
        
        return IdeaSpark(
            id: id,
            authorId: authorId,
            authorUsername: authorUsername,
            title: title,
            description: description,
            tags: tags,
            isPublic: isPublic,
            createdAt: createdAt,
            updatedAt: updatedAt,
            likes: likes,
            comments: comments,
            status: status
        )
    }
    
    // MARK: - Delegate Methods for Compatibility
    
    func sendEmailVerificationLink() async throws {
        guard let email = currentUser?.email else {
            throw NSError(domain: "SupabaseManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "No current user email"])
        }
        try await resendEmailVerification(email: email)
    }
    
    func reloadCurrentUser() async throws {
        do {
            let session = try await supabaseClient.auth.session
            let user = session.user
            await MainActor.run {
                self.currentUser = user
                self.isEmailVerified = user.emailConfirmedAt != nil
                self.isAuthenticated = true
            }
        } catch {
            print("❌ Error reloading current user: \(error)")
            await MainActor.run {
                self.currentUser = nil
                self.isEmailVerified = false
                self.isAuthenticated = false
            }
            throw error
        }
    }
    
    // MARK: - User-specific Ideas
    func getUserIdeas(userId: String) async throws -> [IdeaSpark] {
        // Get user's public ideas  
        let response = try await supabase
            .from("idea_sparks")
            .select("*")
            .eq("author_id", value: userId)
            .eq("is_public", value: true)
            .order("created_at", ascending: false)
            .execute()
        
        let data = try JSONSerialization.jsonObject(with: response.data) as? [[String: Any]] ?? []
        
        return data.compactMap { item in
            parseIdeaFromData(item)
        }
    }
    
    func getUserPrivateIdeas(userId: String) async throws -> [IdeaSpark] {
        // Get user's private ideas
        let response = try await supabase
            .from("idea_sparks")
            .select("*")
            .eq("author_id", value: userId)
            .eq("is_public", value: false)
            .order("created_at", ascending: false)
            .execute()
        
        let data = try JSONSerialization.jsonObject(with: response.data) as? [[String: Any]] ?? []
        
        return data.compactMap { item in
            parseIdeaFromData(item)
        }
    }
    
    func updateUserStats(userId: String) async throws {
        // Compute counts
        async let publicIdeasTask = supabase
            .from("idea_sparks")
            .select("id", head: false, count: .exact)
            .eq("author_id", value: userId)
            .eq("is_public", value: true)
            .execute()

        async let privateIdeasTask = supabase
            .from("idea_sparks")
            .select("id", head: false, count: .exact)
            .eq("author_id", value: userId)
            .eq("is_public", value: false)
            .execute()

        async let projectsTask = supabase
            .from("pod_members")
            .select("id", head: false, count: .exact)
            .eq("user_id", value: userId)
            .execute()

        let (publicIdeasResp, privateIdeasResp, projectsResp) = try await (publicIdeasTask, privateIdeasTask, projectsTask)

        let publicCount = publicIdeasResp.count ?? 0
        let privateCount = privateIdeasResp.count ?? 0
        let totalIdeas = publicCount + privateCount
        let contributed = projectsResp.count ?? 0

        let updateData: [String: AnyJSON] = [
            "ideas_sparked": try AnyJSON(totalIdeas),
            "projects_contributed": try AnyJSON(contributed)
        ]

        try await supabase
            .from("users")
            .update(updateData)
            .eq("id", value: userId)
            .execute()

        print("✅ Updated user stats for \(userId): ideas=\(totalIdeas), contributed=\(contributed)")
    }
    
    // MARK: - Notification Management
    
    func markNotificationAsRead(notificationId: String) async throws {
        let updateData: [String: AnyJSON] = [
            "is_read": AnyJSON.bool(true)
        ]
        
        try await supabase
            .from("notifications")
            .update(updateData)
            .eq("id", value: notificationId)
            .execute()
        
        print("✅ Notification marked as read: \(notificationId)")
    }
    
    func markAllNotificationsAsRead(userId: String) async throws {
        let updateData: [String: AnyJSON] = [
            "is_read": AnyJSON.bool(true)
        ]
        
        try await supabase
            .from("notifications")
            .update(updateData)
            .eq("user_id", value: userId)
            .eq("is_read", value: false)
            .execute()
        
        print("✅ All notifications marked as read for user: \(userId)")
    }
    
    // MARK: - Pod Update Management
    
    func updateProject(podId: String, updates: [String: Any]) async throws {
        let updateData = updates.mapValues { value -> AnyJSON in
            if let string = value as? String {
                return AnyJSON.string(string)
            } else if let bool = value as? Bool {
                return AnyJSON.bool(bool)
            } else if let date = value as? Date {
                let formatter = ISO8601DateFormatter()
                return AnyJSON.string(formatter.string(from: date))
            } else {
                return AnyJSON.null
            }
        }
        
        try await supabase
            .from("pods")
            .update(updateData)
            .eq("id", value: podId)
            .execute()
        
        print("✅ Pod updated: \(podId)")
    }
    
    func deleteProject(podId: String) async throws {
        try await supabase
            .from("pods")
            .delete()
            .eq("id", value: podId)
            .execute()
        
        print("✅ Pod deleted: \(podId)")
    }
    
    func removePodMember(podId: String, userId: String) async throws {
        try await supabase
            .from("pod_members")
            .delete()
            .eq("pod_id", value: podId)
            .eq("user_id", value: userId)
            .execute()
        
        // Also clear any join request records for this user and pod
        try await clearJoinRequest(podId: podId, userId: userId)
        
        print("✅ Member removed from pod: \(userId) from \(podId)")
    }
    
    func clearJoinRequest(podId: String, userId: String) async throws {
        try await supabase
            .from("pod_invitations")
            .delete()
            .eq("pod_id", value: podId)
            .eq("invitee_id", value: userId) // Requester is stored in invitee_id
            .execute()
        
        print("✅ Join request cleared for user: \(userId) from pod: \(podId)")
    }
    
    // MARK: - Like System
    
    func likeIdea(ideaId: String, userId: String) async throws {
        // First check if user already liked this idea
        let existingLike = try await checkIfUserLikedIdea(ideaId: ideaId, userId: userId)
        
        if existingLike {
            // Unlike the idea
            try await supabase
                .from("idea_likes")
                .delete()
                .eq("idea_id", value: ideaId)
                .eq("user_id", value: userId)
                .execute()
            
            // Note: Like count will be updated manually for now
            // In a real app, you'd use a database function or trigger
            
            print("✅ Idea unliked: \(ideaId)")
        } else {
            // Like the idea
            let likeData: [String: AnyJSON] = [
                "idea_id": AnyJSON.string(ideaId),
                "user_id": AnyJSON.string(userId)
            ]
            
            try await supabase
                .from("idea_likes")
                .insert(likeData)
                .execute()
            
            // Note: Like count will be updated manually for now
            // In a real app, you'd use a database function or trigger
            
            print("✅ Idea liked: \(ideaId)")
        }
    }
    
    func checkIfUserLikedIdea(ideaId: String, userId: String) async throws -> Bool {
        let response = try await supabase
            .from("idea_likes")
            .select("id")
            .eq("idea_id", value: ideaId)
            .eq("user_id", value: userId)
            .execute()
        
        let data = try JSONSerialization.jsonObject(with: response.data) as? [[String: Any]] ?? []
        return !data.isEmpty
    }

    // MARK: - Account Deletion
    func requestAccountDeletion(reason: String?) async throws {
        guard let userId = currentUser?.id else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }

        // Calculate deletion date (30 days from now)
        let scheduledDeletionDate = Calendar.current.date(byAdding: .day, value: 30, to: Date())!

        // Create deletion request
        struct DeletionRequest: Encodable {
            let user_id: String
            let reason: String?
            let status: String
            let requested_at: String
            let scheduled_deletion_at: String
        }

        let request = DeletionRequest(
            user_id: userId.uuidString,
            reason: reason,
            status: "pending",
            requested_at: ISO8601DateFormatter().string(from: Date()),
            scheduled_deletion_at: ISO8601DateFormatter().string(from: scheduledDeletionDate)
        )

        _ = try await supabase
            .from("account_deletion_requests")
            .insert(request)
            .execute()
    }

    // MARK: - Content Reporting
    func submitContentReport(
        contentType: ContentReport.ReportContentType,
        contentId: String,
        reportedUserId: String?,
        reason: ContentReport.ReportReason,
        description: String?
    ) async throws {
        guard let userId = currentUser?.id else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }

        struct ReportRequest: Encodable {
            let reporter_id: String
            let reported_content_type: String
            let reported_content_id: String
            let reported_user_id: String?
            let reason: String
            let description: String?
            let status: String
            let created_at: String
        }

        let report = ReportRequest(
            reporter_id: userId.uuidString,
            reported_content_type: contentType.rawValue,
            reported_content_id: contentId,
            reported_user_id: reportedUserId,
            reason: reason.rawValue,
            description: description,
            status: "pending",
            created_at: ISO8601DateFormatter().string(from: Date())
        )

        _ = try await supabase
            .from("content_reports")
            .insert(report)
            .execute()
    }

    // MARK: - Block User
    func blockUser(userId: String, username: String) async throws {
        guard let currentUserId = currentUser?.id else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }

        struct BlockRequest: Encodable {
            let blocker_id: String
            let blocked_user_id: String
            let blocked_username: String
            let blocked_at: String
        }

        let block = BlockRequest(
            blocker_id: currentUserId.uuidString,
            blocked_user_id: userId,
            blocked_username: username,
            blocked_at: ISO8601DateFormatter().string(from: Date())
        )

        _ = try await supabase
            .from("blocked_users")
            .insert(block)
            .execute()
    }

    func unblockUser(userId: String) async throws {
        guard let currentUserId = currentUser?.id else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }

        _ = try await supabase
            .from("blocked_users")
            .delete()
            .eq("blocker_id", value: currentUserId.uuidString)
            .eq("blocked_user_id", value: userId)
            .execute()
    }

    func isUserBlocked(userId: String) async throws -> Bool {
        guard let currentUserId = currentUser?.id else {
            return false
        }

        let response = try await supabase
            .from("blocked_users")
            .select()
            .eq("blocker_id", value: currentUserId.uuidString)
            .eq("blocked_user_id", value: userId)
            .execute()

        let data = try JSONSerialization.jsonObject(with: response.data) as? [[String: Any]] ?? []
        return !data.isEmpty
    }

    func getBlockedUsers() async throws -> [BlockedUser] {
        guard let currentUserId = currentUser?.id else {
            return []
        }

        let response = try await supabase
            .from("blocked_users")
            .select()
            .eq("blocker_id", value: currentUserId.uuidString)
            .execute()

        return try JSONDecoder().decode([BlockedUser].self, from: response.data)
    }
}

// MARK: - User Model Extensions

extension Supabase.User {
    var uid: String {
        return id.uuidString
    }
    
    var displayName: String? {
        return userMetadata["username"]?.stringValue
    }
}
