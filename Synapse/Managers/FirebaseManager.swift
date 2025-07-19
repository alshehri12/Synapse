//
//  FirebaseManager.swift
//  Synapse
//
//  Created by Abdulrahman Alshehri on 18/01/1447 AH.
//

import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn

class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    
    let auth: Auth
    let db: Firestore
    
    @Published var currentUser: FirebaseAuth.User?
    @Published var isAuthReady = false
    @Published var authError: String?
    
    private init() {
        FirebaseApp.configure()
        
        self.auth = Auth.auth()
        self.db = Firestore.firestore()
        
        // Configure Google Sign-In
        GoogleSignInManager.shared.configure()
        
        // Listen for authentication state changes
        auth.addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                if let user = user {
                    self?.currentUser = user
                    self?.isAuthReady = true
                } else {
                    self?.currentUser = nil
                    self?.isAuthReady = true
                }
            }
        }
    }
    
    // MARK: - Authentication Methods
    
    func signUp(email: String, password: String, username: String) async throws {
        do {
            let result = try await auth.createUser(withEmail: email, password: password)
            
            // Create user profile in Firestore
            try await createUserProfile(userId: result.user.uid, email: email, username: username)
            
        } catch {
            DispatchQueue.main.async {
                self.authError = self.localizedAuthError(error)
            }
            throw error
        }
    }
    
    func signIn(email: String, password: String) async throws {
        do {
            _ = try await auth.signIn(withEmail: email, password: password)
        } catch {
            DispatchQueue.main.async {
                self.authError = self.localizedAuthError(error)
            }
            throw error
        }
    }
    
    func signInAnonymously() async throws {
        do {
            let result = try await auth.signInAnonymously()
            
            // Create anonymous user profile
            try await createUserProfile(userId: result.user.uid, email: nil, username: "Anonymous User")
            
        } catch {
            DispatchQueue.main.async {
                self.authError = self.localizedAuthError(error)
            }
            throw error
        }
    }
    
    func signOut() throws {
        do {
            // Sign out from Google if user was signed in with Google
            GoogleSignInManager.shared.signOut()
            
            try auth.signOut()
        } catch {
            DispatchQueue.main.async {
                self.authError = self.localizedAuthError(error)
            }
            throw error
        }
    }
    
    // MARK: - User Profile Methods
    
    private func createUserProfile(userId: String, email: String?, username: String) async throws {
        let userProfile = [
            "id": userId,
            "username": username,
            "email": email ?? "",
            "bio": "",
            "avatarURL": "",
            "skills": [],
            "interests": [],
            "ideasSparked": 0,
            "projectsContributed": 0,
            "dateJoined": Timestamp(date: Date()),
            "createdAt": Timestamp(date: Date()),
            "updatedAt": Timestamp(date: Date())
        ] as [String: Any]
        
        try await db.collection("users").document(userId).setData(userProfile)
    }
    
    func getUserProfile(userId: String) async throws -> [String: Any]? {
        let document = try await db.collection("users").document(userId).getDocument()
        
        if document.exists {
            return document.data()
        } else {
            // Create profile if it doesn't exist
            let username = currentUser?.displayName ?? "Anonymous User"
            try await ensureUserProfileExists(userId: userId, username: username)
            
            // Get the newly created profile
            let newDocument = try await db.collection("users").document(userId).getDocument()
            return newDocument.data()
        }
    }
    
    func updateUserProfile(userId: String, data: [String: Any]) async throws {
        var updateData = data
        updateData["updatedAt"] = Timestamp(date: Date())
        
        try await db.collection("users").document(userId).updateData(updateData)
    }
    
    // MARK: - Idea Spark Methods
    
    func createIdeaSpark(title: String, description: String, tags: [String], isPublic: Bool, creatorId: String, creatorUsername: String) async throws -> String {
        let ideaSparkId = UUID().uuidString
        print("Creating idea with ID: \(ideaSparkId)")
        print("isPublic: \(isPublic)")
        
        let ideaSpark = [
            "id": ideaSparkId,
            "authorId": creatorId,
            "authorUsername": creatorUsername,
            "title": title,
            "description": description,
            "tags": tags,
            "isPublic": isPublic,
            "createdAt": Timestamp(date: Date()),
            "updatedAt": Timestamp(date: Date()),
            "likes": 0,
            "comments": 0,
            "status": "sparking"
        ] as [String: Any]
        
        print("Idea data: \(ideaSpark)")
        
        if isPublic {
            print("Saving to public collection: ideaSparks/\(ideaSparkId)")
            try await db.collection("ideaSparks").document(ideaSparkId).setData(ideaSpark)
            print("Successfully saved public idea")
        } else {
            print("Saving to private collection: users/\(creatorId)/privateIdeaSparks/\(ideaSparkId)")
            try await db.collection("users").document(creatorId).collection("privateIdeaSparks").document(ideaSparkId).setData(ideaSpark)
            print("Successfully saved private idea")
        }
        
        return ideaSparkId
    }
    
    // Helper method to ensure user profile exists
    private func ensureUserProfileExists(userId: String, username: String) async throws {
        let userDoc = try await db.collection("users").document(userId).getDocument()
        
        if !userDoc.exists {
            // Create user profile if it doesn't exist
            let userProfile = [
                "id": userId,
                "username": username,
                "email": currentUser?.email ?? "",
                "bio": "",
                "avatarURL": "",
                "skills": [],
                "interests": [],
                "ideasSparked": 0,
                "projectsContributed": 0,
                "dateJoined": Timestamp(date: Date()),
                "createdAt": Timestamp(date: Date()),
                "updatedAt": Timestamp(date: Date())
            ] as [String: Any]
            
            try await db.collection("users").document(userId).setData(userProfile)
        }
    }
    
    func getPublicIdeaSparks() async throws -> [[String: Any]] {
        print("Fetching public idea sparks from Firestore...")
        
        // First, try to get all documents to see what's in the collection
        let allSnapshot = try await db.collection("ideaSparks").getDocuments()
        print("Total documents in ideaSparks collection: \(allSnapshot.documents.count)")
        
        // Filter for public ideas
        let publicIdeas = allSnapshot.documents.compactMap { doc -> [String: Any]? in
            let data = doc.data()
            let isPublic = data["isPublic"] as? Bool ?? false
            if isPublic {
                return data
            }
            return nil
        }
        
        // Sort by creation date (newest first)
        let sortedIdeas = publicIdeas.sorted { idea1, idea2 in
            let date1 = (idea1["createdAt"] as? Timestamp)?.dateValue() ?? Date.distantPast
            let date2 = (idea2["createdAt"] as? Timestamp)?.dateValue() ?? Date.distantPast
            return date1 > date2
        }
        
        print("Found \(sortedIdeas.count) public ideas after filtering")
        
        // Debug: Print each idea's details
        for (index, idea) in sortedIdeas.enumerated() {
            print("Idea \(index + 1):")
            print("  - ID: \(idea["id"] ?? "N/A")")
            print("  - Title: \(idea["title"] ?? "N/A")")
            print("  - Author: \(idea["authorUsername"] ?? "N/A")")
            print("  - isPublic: \(idea["isPublic"] ?? "N/A")")
            print("  - Status: \(idea["status"] ?? "N/A")")
            print("  - Created At: \(idea["createdAt"] ?? "N/A")")
        }
        
        return sortedIdeas
    }
    
    // MARK: - Debug Methods
    
    func debugIdeaSparksCollection() async {
        print("=== DEBUG: IdeaSparks Collection ===")
        do {
            let snapshot = try await db.collection("ideaSparks").getDocuments()
            print("Total documents: \(snapshot.documents.count)")
            
            for (index, doc) in snapshot.documents.enumerated() {
                let data = doc.data()
                print("Document \(index + 1) - ID: \(doc.documentID)")
                print("  Data: \(data)")
                print("  isPublic field: \(data["isPublic"] ?? "MISSING")")
                print("  ---")
            }
        } catch {
            print("Error debugging collection: \(error)")
        }
        print("=== END DEBUG ===")
    }
    
    // MARK: - Helper Methods
    
    private func localizedAuthError(_ error: Error) -> String {
        if let authError = error as? AuthErrorCode {
            switch authError.code {
            case .emailAlreadyInUse:
                return "Email already in use".localized
            case .invalidEmail:
                return "Invalid email format".localized
            case .weakPassword:
                return "Password is too weak".localized
            case .wrongPassword:
                return "Incorrect password".localized
            case .userNotFound:
                return "User not found".localized
            case .networkError:
                return "Network error. Please check your connection".localized
            default:
                return "Authentication failed".localized
            }
        }
        return "An error occurred".localized
    }
    
    func clearAuthError() {
        authError = nil
    }
    
    // MARK: - Idea Interaction Methods
    
    func likeIdea(ideaId: String, userId: String) async throws {
        let ideaRef = db.collection("ideaSparks").document(ideaId)
        
        // First, get the current idea data
        let ideaDoc = try await ideaRef.getDocument()
        guard let ideaData = ideaDoc.data() else {
            throw NSError(domain: "FirebaseManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "Idea not found"])
        }
        
        var likes = ideaData["likes"] as? Int ?? 0
        var likedBy = ideaData["likedBy"] as? [String] ?? []
        
        if likedBy.contains(userId) {
            // Unlike
            likes = max(0, likes - 1)
            likedBy.removeAll { $0 == userId }
        } else {
            // Like
            likes += 1
            likedBy.append(userId)
        }
        
        // Update the document
        try await ideaRef.updateData([
            "likes": likes,
            "likedBy": likedBy,
            "updatedAt": Timestamp(date: Date())
        ])
    }
    
    func addCommentToIdea(ideaId: String, comment: String, authorId: String, authorUsername: String) async throws -> String {
        let commentId = UUID().uuidString
        let commentData = [
            "id": commentId,
            "ideaId": ideaId,
            "authorId": authorId,
            "authorUsername": authorUsername,
            "content": comment,
            "createdAt": Timestamp(date: Date()),
            "likes": 0
        ] as [String: Any]
        
        // Add comment to comments subcollection
        try await db.collection("ideaSparks").document(ideaId).collection("comments").document(commentId).setData(commentData)
        
        // Update comment count on the idea
        let ideaRef = db.collection("ideaSparks").document(ideaId)
        try await ideaRef.updateData([
            "comments": FieldValue.increment(Int64(1)),
            "updatedAt": Timestamp(date: Date())
        ])
        
        return commentId
    }
    
    func getIdeaComments(ideaId: String) async throws -> [[String: Any]] {
        let snapshot = try await db.collection("ideaSparks").document(ideaId).collection("comments")
            .order(by: "createdAt", descending: false)
            .getDocuments()
        
        return snapshot.documents.map { $0.data() }
    }
    
    func createPodFromIdea(ideaId: String, podName: String, podDescription: String, creatorId: String, creatorUsername: String) async throws -> String {
        // First, get the idea data
        let ideaDoc = try await db.collection("ideaSparks").document(ideaId).getDocument()
        guard let ideaData = ideaDoc.data() else {
            throw NSError(domain: "FirebaseManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "Idea not found"])
        }
        
        // Create the pod
        let podId = UUID().uuidString
        let pod = [
            "id": podId,
            "ideaId": ideaId,
            "name": podName,
            "description": podDescription,
            "creatorId": creatorId,
            "creatorUsername": creatorUsername,
            "isPublic": true,
            "createdAt": Timestamp(date: Date()),
            "updatedAt": Timestamp(date: Date()),
            "members": [
                [
                    "id": UUID().uuidString,
                    "userId": creatorId,
                    "username": creatorUsername,
                    "role": "Creator",
                    "joinedAt": Timestamp(date: Date()),
                    "permissions": ["admin"]
                ]
            ],
            "tasks": [],
            "status": "planning"
        ] as [String: Any]
        
        try await db.collection("pods").document(podId).setData(pod)
        
        // Update the idea status to "incubating"
        try await db.collection("ideaSparks").document(ideaId).updateData([
            "status": "incubating",
            "updatedAt": Timestamp(date: Date())
        ])
        
        return podId
    }
    
    // MARK: - Google Sign-In Methods
    
    func signInWithGoogle() async throws {
        do {
            _ = try await GoogleSignInManager.shared.signIn()
        } catch {
            DispatchQueue.main.async {
                self.authError = self.localizedAuthError(error)
            }
            throw error
        }
    }
    
    // MARK: - Pod Management Methods
    
    func createPod(name: String, description: String, ideaId: String?, isPublic: Bool) async throws -> String {
        guard let currentUser = currentUser else {
            throw NSError(domain: "FirebaseManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let podId = UUID().uuidString
        let pod = [
            "id": podId,
            "ideaId": ideaId ?? "",
            "name": name,
            "description": description,
            "creatorId": currentUser.uid,
            "isPublic": isPublic,
            "createdAt": Timestamp(date: Date()),
            "updatedAt": Timestamp(date: Date()),
            "members": [
                [
                    "id": UUID().uuidString,
                    "userId": currentUser.uid,
                    "username": currentUser.displayName ?? "Unknown",
                    "role": "Creator",
                    "joinedAt": Timestamp(date: Date()),
                    "permissions": ["admin"]
                ]
            ],
            "tasks": [],
            "status": "planning"
        ] as [String: Any]
        
        try await db.collection("pods").document(podId).setData(pod)
        return podId
    }
    
    func getUserPods(userId: String) async throws -> [[String: Any]] {
        let snapshot = try await db.collection("pods")
            .whereField("members", arrayContains: ["userId": userId])
            .order(by: "updatedAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.map { $0.data() }
    }
    
    func getPublicPods() async throws -> [[String: Any]] {
        let snapshot = try await db.collection("pods")
            .whereField("isPublic", isEqualTo: true)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.map { $0.data() }
    }
    
    func updatePod(podId: String, data: [String: Any]) async throws {
        var updateData = data
        updateData["updatedAt"] = Timestamp(date: Date())
        
        try await db.collection("pods").document(podId).updateData(updateData)
    }
    
    func deletePod(podId: String) async throws {
        try await db.collection("pods").document(podId).delete()
    }
    
    // MARK: - Task Management Methods
    
    func createTask(podId: String, title: String, description: String?, assignedTo: String?, assignedToUsername: String?, dueDate: Date?, priority: String) async throws -> String {
        let taskId = UUID().uuidString
        let task = [
            "id": taskId,
            "title": title,
            "description": description ?? "",
            "assignedTo": assignedTo ?? "",
            "assignedToUsername": assignedToUsername ?? "",
            "dueDate": dueDate != nil ? Timestamp(date: dueDate!) : nil,
            "createdAt": Timestamp(date: Date()),
            "updatedAt": Timestamp(date: Date()),
            "status": "todo",
            "priority": priority
        ] as [String: Any]
        
        try await db.collection("pods").document(podId).updateData([
            "tasks": FieldValue.arrayUnion([task]),
            "updatedAt": Timestamp(date: Date())
        ])
        
        return taskId
    }
    
    func updateTask(podId: String, taskId: String, data: [String: Any]) async throws {
        // Get current pod data
        let podDoc = try await db.collection("pods").document(podId).getDocument()
        guard let podData = podDoc.data(),
              var tasks = podData["tasks"] as? [[String: Any]] else {
            throw NSError(domain: "FirebaseManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "Pod or tasks not found"])
        }
        
        // Update the specific task
        if let taskIndex = tasks.firstIndex(where: { ($0["id"] as? String) == taskId }) {
            var updatedTask = tasks[taskIndex]
            updatedTask.merge(data) { _, new in new }
            updatedTask["updatedAt"] = Timestamp(date: Date())
            tasks[taskIndex] = updatedTask
            
            // Update the pod
            try await db.collection("pods").document(podId).updateData([
                "tasks": tasks,
                "updatedAt": Timestamp(date: Date())
            ])
        }
    }
    
    // MARK: - Notification Methods
    
    func getUserNotifications(userId: String) async throws -> [[String: Any]] {
        let snapshot = try await db.collection("notifications")
            .whereField("userId", isEqualTo: userId)
            .order(by: "timestamp", descending: true)
            .limit(to: 50)
            .getDocuments()
        
        return snapshot.documents.map { $0.data() }
    }
    
    func createNotification(userId: String, type: String, message: String, relatedId: String?) async throws {
        let notification = [
            "id": UUID().uuidString,
            "userId": userId,
            "type": type,
            "message": message,
            "relatedId": relatedId ?? "",
            "isRead": false,
            "timestamp": Timestamp(date: Date())
        ] as [String: Any]
        
        try await db.collection("notifications").addDocument(data: notification)
    }
    
    func markNotificationAsRead(notificationId: String) async throws {
        try await db.collection("notifications").document(notificationId).updateData([
            "isRead": true
        ])
    }
    
    // MARK: - Search Methods
    
    func searchIdeas(query: String) async throws -> [[String: Any]] {
        let snapshot = try await db.collection("ideaSparks")
            .whereField("isPublic", isEqualTo: true)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        let allIdeas = snapshot.documents.map { $0.data() }
        
        // Filter by query (Firestore doesn't support full-text search in free tier)
        return allIdeas.filter { idea in
            let title = idea["title"] as? String ?? ""
            let description = idea["description"] as? String ?? ""
            let tags = idea["tags"] as? [String] ?? []
            
            return title.localizedCaseInsensitiveContains(query) ||
                   description.localizedCaseInsensitiveContains(query) ||
                   tags.contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }
    
    func searchPods(query: String) async throws -> [[String: Any]] {
        let snapshot = try await db.collection("pods")
            .whereField("isPublic", isEqualTo: true)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        let allPods = snapshot.documents.map { $0.data() }
        
        return allPods.filter { pod in
            let name = pod["name"] as? String ?? ""
            let description = pod["description"] as? String ?? ""
            
            return name.localizedCaseInsensitiveContains(query) ||
                   description.localizedCaseInsensitiveContains(query)
        }
    }
    
    func searchUsers(query: String) async throws -> [[String: Any]] {
        let snapshot = try await db.collection("users")
            .order(by: "username")
            .getDocuments()
        
        let allUsers = snapshot.documents.map { $0.data() }
        
        return allUsers.filter { user in
            let username = user["username"] as? String ?? ""
            let email = user["email"] as? String ?? ""
            let skills = user["skills"] as? [String] ?? []
            
            return username.localizedCaseInsensitiveContains(query) ||
                   email.localizedCaseInsensitiveContains(query) ||
                   skills.contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }
    
    // MARK: - Activity Feed Methods
    
    func getActivityFeed() async throws -> [[String: Any]] {
        let snapshot = try await db.collection("activities")
            .order(by: "timestamp", descending: true)
            .limit(to: 50)
            .getDocuments()
        
        return snapshot.documents.map { $0.data() }
    }
    
    func createActivity(userId: String, userName: String, type: String, message: String, relatedId: String?) async throws {
        let activity = [
            "id": UUID().uuidString,
            "userId": userId,
            "userName": userName,
            "type": type,
            "message": message,
            "relatedId": relatedId ?? "",
            "timestamp": Timestamp(date: Date())
        ] as [String: Any]
        
        try await db.collection("activities").addDocument(data: activity)
    }
    
    // MARK: - User Management Methods
    
    func getAllUsers() async throws -> [[String: Any]] {
        let snapshot = try await db.collection("users")
            .order(by: "username")
            .getDocuments()
        
        return snapshot.documents.map { $0.data() }
    }
    
    func inviteUserToPod(podId: String, userId: String, role: String, message: String) async throws {
        // Create invitation
        let invitation = [
            "id": UUID().uuidString,
            "podId": podId,
            "invitedUserId": userId,
            "invitedBy": currentUser?.uid ?? "",
            "role": role,
            "message": message,
            "status": "pending",
            "createdAt": Timestamp(date: Date())
        ] as [String: Any]
        
        try await db.collection("invitations").addDocument(data: invitation)
        
        // Create notification for invited user
        try await createNotification(
            userId: userId,
            type: "pod_invite",
            message: message,
            relatedId: podId
        )
    }
    
    func acceptPodInvitation(invitationId: String) async throws {
        let invitationDoc = try await db.collection("invitations").document(invitationId).getDocument()
        guard let invitationData = invitationDoc.data() else {
            throw NSError(domain: "FirebaseManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "Invitation not found"])
        }
        
        let podId = invitationData["podId"] as? String ?? ""
        let role = invitationData["role"] as? String ?? "Member"
        let invitedUserId = invitationData["invitedUserId"] as? String ?? ""
        
        // Add user to pod
        let member = [
            "id": UUID().uuidString,
            "userId": invitedUserId,
            "username": currentUser?.displayName ?? "Unknown",
            "role": role,
            "joinedAt": Timestamp(date: Date()),
            "permissions": ["edit"]
        ] as [String: Any]
        
        try await db.collection("pods").document(podId).updateData([
            "members": FieldValue.arrayUnion([member]),
            "updatedAt": Timestamp(date: Date())
        ])
        
        // Update invitation status
        try await db.collection("invitations").document(invitationId).updateData([
            "status": "accepted"
        ])
        
        // Create activity
        try await createActivity(
            userId: invitedUserId,
            userName: currentUser?.displayName ?? "Unknown",
            type: "pod_joined",
            message: "joined the pod",
            relatedId: podId
        )
    }
} 