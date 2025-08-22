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

// MARK: - Custom Errors

enum AuthError: LocalizedError {
    case noViewController
    case missingGoogleClientId
    case missingIdToken
    case googleSignInNotImplemented
    
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
        }
    }
}

class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()
    
    // Supabase client
    private let supabase: SupabaseClient
    
    // Published authentication state
    @Published var currentUser: User?
    @Published var authError: String?
    @Published var isEmailVerified: Bool = false
    @Published var isSigningUp: Bool = false
    @Published var isAuthReady: Bool = false
    
    // Combine cancellables
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Initialize Supabase client with your credentials
        let supabaseURL = URL(string: "https://oocegnwdfnnjgoworrwh.supabase.co")!
        let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9vY2VnbndkZm5uamdvd29ycndoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTUzNDk1MDcsImV4cCI6MjA3MDkyNTUwN30.QA05vtt_KgQTQ_EfABuEtDnYO_2-W-L6zo_dHBLBRfw"
        
        self.supabase = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseKey
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
            
            // Configure GoogleSignIn with your client ID from GoogleService-Info.plist
            guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
                  let plist = NSDictionary(contentsOfFile: path),
                  let clientId = plist["CLIENT_ID"] as? String else {
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
            try await supabase.auth.signInWithIdToken(
                credentials: .init(
                    provider: .google,
                    idToken: idToken,
                    accessToken: accessToken
                )
            )
            
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
            let response = try await supabase.auth.signUp(
                email: email,
                password: password,
                data: ["username": .string(username)]
            )
            
            // User created successfully, they need to verify their email
            print("✅ User created: \(response.user.email ?? "no email")")
            authError = "Please check your email and click the verification link to complete registration."
            
            isSigningUp = false
        } catch {
            isSigningUp = false
            authError = "Failed to create account: \(error.localizedDescription)"
            throw error
        }
    }
    
    @MainActor
    func signIn(email: String, password: String) async throws {
        authError = nil
        
        do {
            let response = try await supabase.auth.signIn(
                email: email,
                password: password
            )
            
            let user = response.user
            
            if user.emailConfirmedAt == nil {
                // Sign out unverified user and show error
                try await signOut()
                authError = "Please verify your email via the link we sent, then sign in."
                
                // Optionally resend verification email
                try await resendEmailVerification(email: email)
            } else {
                print("✅ User signed in: \(user.email ?? "no email")")
                // User profile will be set by auth state listener
            }
        } catch {
            authError = "Sign in failed: \(error.localizedDescription)"
            throw error
        }
    }
    
    @MainActor
    func signOut() async throws {
        try await supabase.auth.signOut()
        currentUser = nil
        isEmailVerified = false
        authError = nil
    }
    
    @MainActor
    func resendEmailVerification(email: String) async throws {
        try await supabase.auth.resend(
            email: email,
            type: .signup
        )
    }
    
    // MARK: - User Profile Management
    
    func createUserProfile(userId: String, email: String, username: String) async throws {
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
        
        try await supabase
            .from("users")
            .insert(profileData)
            .execute()
        
        print("✅ User profile created for: \(username)")
    }
    
    func getUserProfile(userId: String) async throws -> [String: Any]? {
        let response = try await supabase
            .from("users")
            .select("*")
            .eq("id", value: userId)
            .single()
            .execute()
        
        return try JSONSerialization.jsonObject(with: response.data) as? [String: Any]
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
        let ideaData: [String: AnyJSON] = [
            "author_id": AnyJSON.string(creatorId),
            "author_username": AnyJSON.string(creatorUsername),
            "title": AnyJSON.string(title),
            "description": AnyJSON.string(description),
            "tags": AnyJSON.array(tags.map { AnyJSON.string($0) }),
            "is_public": AnyJSON.bool(isPublic),
            "status": AnyJSON.string("sparking")
        ]
        
        let response = try await supabase
            .from("idea_sparks")
            .insert(ideaData)
            .select("id")
            .single()
            .execute()
        
        let data = try JSONSerialization.jsonObject(with: response.data) as? [String: Any]
        guard let id = data?["id"] as? String else {
            throw NSError(domain: "SupabaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create idea"])
        }
        
        print("✅ Idea created with ID: \(id)")
        return id
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
    
    // MARK: - Pod Management (Placeholder)
    
    func getUserPods(userId: String) async throws -> [IncubationProject] {
        // Placeholder - return empty for now
        print("🚧 getUserPods - Supabase implementation needed")
        return []
    }
    
    func getPublicPods() async throws -> [IncubationProject] {
        // Placeholder - return empty for now
        print("🚧 getPublicPods - Supabase implementation needed")
        return []
    }
    
    func getPodsByIdeaId(_ ideaId: String) async throws -> [IncubationProject] {
        // Placeholder - return empty for now
        print("🚧 getPodsByIdeaId - Supabase implementation needed")
        return []
    }
    
    // MARK: - Search (Placeholder)
    
    func searchIdeas(query: String) async throws -> [IdeaSpark] {
        print("🚧 searchIdeas - Supabase implementation needed")
        return []
    }
    
    func searchPods(query: String) async throws -> [IncubationProject] {
        print("🚧 searchPods - Supabase implementation needed")
        return []
    }
    
    func searchUsers(query: String) async throws -> [UserProfile] {
        print("🚧 searchUsers - Supabase implementation needed")
        return []
    }
    
    // MARK: - Notifications (Placeholder)
    
    func getUserNotifications(userId: String) async throws -> [AppNotification] {
        print("🚧 getUserNotifications - Supabase implementation needed")
        return []
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
                        self.isAuthReady = true
                        print("✅ Auth state - User signed in: \(user.email ?? "no email")")
                    }
                case .signedOut:
                    self.currentUser = nil
                    self.isEmailVerified = false
                    self.isAuthReady = true
                    print("🚪 Auth state - User signed out")
                case .tokenRefreshed:
                    if let user = session?.user {
                        self.currentUser = user
                        self.isEmailVerified = user.emailConfirmedAt != nil
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
            let session = try await supabase.auth.session
            await MainActor.run {
                let user = session.user
                self.currentUser = user
                self.isEmailVerified = user.emailConfirmedAt != nil
                self.isAuthReady = true
                print("✅ Restored session for: \(user.email ?? "Unknown")")
            }
        } catch {
            await MainActor.run {
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
        // In Supabase, we get real-time updates via the auth state change listener
        print("User reload requested - Supabase handles this automatically")
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
        // Placeholder for updating user stats - to be implemented
        print("✅ User stats update requested for: \(userId)")
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