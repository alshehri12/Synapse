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
    @Published var isAuthenticated: Bool = false
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
            
            // User created successfully
            let user = response.user
            print("✅ User created: \(user.email ?? "no email") | id: \(user.id.uuidString)")
            // Create profile row (best-effort)
            do {
                try await createUserProfile(userId: user.id.uuidString, email: user.email ?? email, username: username)
            } catch {
                print("⚠️ Failed to create user profile: \(error.localizedDescription)")
            }
            
            isSigningUp = false
        } catch {
            isSigningUp = false
            let lower = error.localizedDescription.lowercased()
            if lower.contains("confirm") || lower.contains("email") || lower.contains("smtp") {
                authError = "Email confirmation is required or email sending failed. Please disable email confirmations in Supabase Auth settings for now."
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
            let response = try await supabase.auth.signIn(
                email: email,
                password: password
            )
            let user = response.user
            print("✅ User signed in: \(user.email ?? "no email") (emailConfirmedAt: \(user.emailConfirmedAt?.description ?? "nil"))")
            
            // Ensure user profile exists (best-effort)
            do {
                let hasProfile = try await getUserProfile(userId: user.id.uuidString) != nil
                if !hasProfile {
                    try await createUserProfile(userId: user.id.uuidString, email: user.email ?? email, username: user.displayName ?? "user_\(user.id.uuidString.prefix(6))")
                }
            } catch {
                print("⚠️ Failed to ensure user profile on sign-in: \(error.localizedDescription)")
            }
            
            // No verification gate: allow unverified logins per request
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
    
    // MARK: - Pod Management
    
    func getUserPods(userId: String) async throws -> [IncubationProject] {
        let response = try await supabase
            .from("pods")
            .select("""
                *,
                pod_members (
                    id,
                    user_id,
                    username,
                    role,
                    permissions,
                    joined_at
                ),
                tasks (
                    id,
                    title,
                    description,
                    assigned_to,
                    assigned_to_username,
                    status,
                    priority,
                    created_at,
                    updated_at
                )
            """)
            .eq("creator_id", value: userId)
            .order("created_at", ascending: false)
            .execute()
        
        let data = try JSONSerialization.jsonObject(with: response.data) as? [[String: Any]] ?? []
        
        return data.compactMap { item in
            parsePodFromData(item)
        }
    }
    
    func getPublicPods() async throws -> [IncubationProject] {
        let response = try await supabase
            .from("pods")
            .select("""
                *,
                pod_members (
                    id,
                    user_id,
                    username,
                    role,
                    permissions,
                    joined_at
                ),
                tasks (
                    id,
                    title,
                    description,
                    assigned_to,
                    assigned_to_username,
                    status,
                    priority,
                    created_at,
                    updated_at
                )
            """)
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
            .select("""
                *,
                pod_members (
                    id,
                    user_id,
                    username,
                    role,
                    permissions,
                    joined_at
                ),
                tasks (
                    id,
                    title,
                    description,
                    assigned_to,
                    assigned_to_username,
                    status,
                    priority,
                    created_at,
                    updated_at
                )
            """)
            .eq("idea_id", value: ideaId)
            .eq("is_public", value: true)
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
    
    func createPodFromIdea(ideaId: String, name: String, description: String, creatorId: String, isPublic: Bool = true) async throws -> String {
        print("💾 DEBUG: Creating pod with data:")
        print("  📛 name: '\(name)'")
        print("  💡 ideaId: '\(ideaId)'")
        print("  👤 creatorId: '\(creatorId)'")
        print("  🌍 isPublic: \(isPublic)")
        
        let podData: [String: AnyJSON] = [
            "idea_id": AnyJSON.string(ideaId),
            "name": AnyJSON.string(name),
            "description": AnyJSON.string(description),
            "creator_id": AnyJSON.string(creatorId),
            "is_public": AnyJSON.bool(isPublic),
            "status": AnyJSON.string("planning")
        ]
        
        let response = try await supabase
            .from("pods")
            .insert(podData)
            .select("id")
            .single()
            .execute()
        
        let data = try JSONSerialization.jsonObject(with: response.data) as? [String: Any]
        guard let podId = data?["id"] as? String else {
            throw NSError(domain: "SupabaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create pod"])
        }
        
        // Add creator as first member with admin role
        try await addPodMember(podId: podId, userId: creatorId, username: currentUser?.displayName ?? "Creator", role: "Creator")
        
        print("✅ VERIFICATION: Pod created successfully - id: '\(podId)', ideaId: '\(ideaId)', isPublic: \(isPublic)")
        return podId
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
              let ideaId = item["idea_id"] as? String,
              let name = item["name"] as? String,
              let description = item["description"] as? String,
              let creatorId = item["creator_id"] as? String else {
            return nil
        }
        
        let isPublic = item["is_public"] as? Bool ?? false
        let statusString = item["status"] as? String ?? "planning"
        let status = IncubationProject.ProjectStatus(rawValue: statusString) ?? .planning
        
        let createdAt = parseDate(item["created_at"]) ?? Date()
        let updatedAt = parseDate(item["updated_at"]) ?? Date()
        
        // Parse members
        let membersData = item["pod_members"] as? [[String: Any]] ?? []
        let members = membersData.compactMap { memberItem -> ProjectMember? in
            guard let memberId = memberItem["id"] as? String,
                  let userId = memberItem["user_id"] as? String,
                  let username = memberItem["username"] as? String,
                  let role = memberItem["role"] as? String else {
                return nil
            }
            
            let joinedAt = parseDate(memberItem["joined_at"]) ?? Date()
            let permissionsArray = memberItem["permissions"] as? [String] ?? ["view", "comment"]
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
        
        // Parse tasks
        let tasksData = item["tasks"] as? [[String: Any]] ?? []
        let tasks = tasksData.compactMap { taskItem -> ProjectTask? in
            guard let taskId = taskItem["id"] as? String,
                  let title = taskItem["title"] as? String else {
                return nil
            }
            
            let description = taskItem["description"] as? String
            let assignedTo = taskItem["assigned_to"] as? String
            let assignedToUsername = taskItem["assigned_to_username"] as? String
            let statusString = taskItem["status"] as? String ?? "todo"
            let priorityString = taskItem["priority"] as? String ?? "medium"
            
            let taskStatus = ProjectTask.TaskStatus(rawValue: statusString) ?? .todo
            let taskPriority = ProjectTask.TaskPriority(rawValue: priorityString) ?? .medium
            
            let taskCreatedAt = parseDate(taskItem["created_at"]) ?? Date()
            let taskUpdatedAt = parseDate(taskItem["updated_at"]) ?? Date()
            
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
        
        return IncubationProject(
            id: id,
            ideaId: ideaId,
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
    
    func verifyOtp(email: String, otp: String) async throws {
        do {
            let response = try await supabase.auth.verifyOTP(
                email: email,
                token: otp,
                type: .signup
            )
            
            let user = response.user
            await MainActor.run {
                self.currentUser = user
                self.isAuthenticated = true
            }
        } catch {
            print("❌ Error verifying OTP: \(error)")
            throw error
        }
    }
    
    func resendOtp(email: String) async throws {
        do {
            try await supabase.auth.resend(
                email: email,
                type: .signup
            )
        } catch {
            print("❌ Error resending OTP: \(error)")
            throw error
        }
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
        do {
            let session = try await supabase.auth.session
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