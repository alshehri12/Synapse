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
import FirebaseFunctions
import Combine

class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    
    // Delegate authentication properties to AuthenticationManager
    var currentUser: User? { authManager.currentUser }
    var authError: String? { authManager.authError }
    var isEmailVerified: Bool { authManager.isEmailVerified }
    var otpCode: String { authManager.otpCode }
    var isOtpSent: Bool { authManager.isOtpSent }
    var isOtpVerified: Bool { authManager.isOtpVerified }
    var isSigningUp: Bool { authManager.isSigningUp }
    
    // Manager dependencies
    private let authManager: AuthenticationManager
    private let userManager: UserManager
    private let podManager: PodManager
    
    // Firebase services for remaining functionality
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    private let functions = Functions.functions()
    
    private init() {
        self.authManager = AuthenticationManager.shared
        self.userManager = UserManager.shared
        self.podManager = PodManager.shared
        
        // Set up dependencies between managers
        authManager.setUserManager(userManager)
        
        // Forward published changes from managers
        setupManagerObservation()
    }
    
    private func setupManagerObservation() {
        // Forward changes from AuthenticationManager to trigger UI updates
        authManager.objectWillChange.sink { [weak self] in
            DispatchQueue.main.async {
                self?.objectWillChange.send()
            }
        }.store(in: &cancellables)
        
        // Forward changes from UserManager to trigger UI updates
        userManager.objectWillChange.sink { [weak self] in
            DispatchQueue.main.async {
                self?.objectWillChange.send()
            }
        }.store(in: &cancellables)
        
        // Forward changes from PodManager to trigger UI updates
        podManager.objectWillChange.sink { [weak self] in
            DispatchQueue.main.async {
                self?.objectWillChange.send()
            }
        }.store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Authentication Methods (Delegated to AuthenticationManager)
    
    func signUp(email: String, password: String, username: String) async throws {
        try await authManager.signUp(email: email, password: password, username: username)
    }
    
    func signIn(email: String, password: String) async throws {
        try await authManager.signIn(email: email, password: password)
    }
    
    func signOut() throws {
        try authManager.signOut()
    }
    
    // MARK: - OTP Email Verification Methods (Delegated to AuthenticationManager)
    
    func sendOtpEmail(email: String) async throws {
        try await authManager.sendOtpEmail(email: email)
    }
    
    func verifyOtp(email: String, otp: String) async throws {
        try await authManager.verifyOtp(email: email, otp: otp)
    }
    
    func resendOtp(email: String) async throws {
        try await authManager.resendOtp(email: email)
    }
    
    // MARK: - OTP State Management (Delegated to AuthenticationManager)
    
    func resetOtpState() {
        authManager.resetOtpState()
    }
    
    func clearAuthError() {
        authManager.clearAuthError()
    }
    
    // User profile methods are now handled by UserManager
    
    // MARK: - User Validation Methods (Delegated to AuthenticationManager)
    
    func checkUserExists(email: String) async throws -> Bool {
        return try await authManager.checkUserExists(email: email)
    }
    
    func validateUsername(_ username: String) async throws -> Bool {
        return try await authManager.validateUsername(username)
    }
    
    // MARK: - Anonymous Authentication (Delegated to AuthenticationManager)
    
    func signInAnonymously() async throws {
        try await authManager.signInAnonymously()
    }
    
    // MARK: - Google Sign-In (Delegated to AuthenticationManager)
    
    func signInWithGoogle() async throws {
        try await authManager.signInWithGoogle()
    }
    
    // MARK: - User Data Methods (Delegated to UserManager)
    
    func getUserFavorites(userId: String) async throws -> [[String: Any]] {
        return try await userManager.getUserFavorites(userId: userId)
    }
    
    func removeFromFavorites(userId: String, ideaId: String) async throws {
        try await userManager.removeFromFavorites(userId: userId, ideaId: ideaId)
    }
    
    func getUserPods(userId: String) async throws -> [IncubationProject] {
        return try await podManager.getUserPods(userId: userId)
    }
    
    func getUserIdeas(userId: String) async throws -> [IdeaSpark] {
        return try await userManager.getUserIdeas(userId: userId)
    }
    
    func getUserPrivateIdeas(userId: String) async throws -> [IdeaSpark] {
        return try await userManager.getUserPrivateIdeas(userId: userId)
    }
    
    // MARK: - Pod Management Methods (Delegated to PodManager)
    
    func createPod(name: String, description: String, ideaId: String?, isPublic: Bool) async throws -> String {
        return try await podManager.createPod(name: name, description: description, ideaId: ideaId, isPublic: isPublic)
    }
    
    func createPodFromIdea(name: String, description: String, ideaId: String, isPublic: Bool) async throws -> String {
        return try await podManager.createPodFromIdea(name: name, description: description, ideaId: ideaId, isPublic: isPublic)
    }
    
    // Pod helper methods are now in PodManager
    
    func fetchProjectMembers(projectId: String) async throws -> [ProjectMember] {
        return try await podManager.fetchProjectMembers(projectId: projectId)
    }
    
    func updateProject(projectId: String, data: [String: Any]) async throws {
        try await podManager.updateProject(projectId: projectId, data: data)
    }
    
    func addMemberToProject(projectId: String, userId: String, role: String = "Member") async throws {
        try await podManager.addMemberToProject(projectId: projectId, userId: userId, role: role)
    }
    
    func removeMemberFromProject(projectId: String, userId: String) async throws {
        try await podManager.removeMemberFromProject(projectId: projectId, userId: userId)
    }
    
    func deleteProject(projectId: String) async throws {
        try await podManager.deleteProject(projectId: projectId)
    }
    
    // MARK: - Task Management Methods
    
    func createTask(projectId: String, title: String, description: String?, assignedTo: String?, assignedToUsername: String?, dueDate: Date?, priority: String) async throws -> String {
        guard let currentUser = auth.currentUser else {
            throw NSError(domain: "FirebaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated".localized])
        }
        
        // Verify current user is pod admin/creator
        let podDoc = try await db.collection("pods").document(projectId).getDocument()
        guard podDoc.exists,
              let podData = podDoc.data(),
              let creatorId = podData["creatorId"] as? String,
              creatorId == currentUser.uid else {
            throw NSError(domain: "FirebaseManager", code: -2, userInfo: [NSLocalizedDescriptionKey: "Only pod administrators can create tasks".localized])
        }
        
        let taskData: [String: Any] = [
            "title": title,
            "description": description ?? "",
            "assignedTo": assignedTo ?? "",
            "assignedToUsername": assignedToUsername ?? "",
            "dueDate": dueDate != nil ? Timestamp(date: dueDate!) : nil,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp(),
            "status": "todo",
            "priority": priority,
            "createdBy": currentUser.uid
        ]
        
        let docRef = try await db.collection("pods").document(projectId).collection("tasks").addDocument(data: taskData)
        return docRef.documentID
    }
    
    // Update task status
    func updateTaskStatus(projectId: String, taskId: String, status: String) async throws {
        guard currentUser != nil else {
            throw NSError(domain: "FirebaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated".localized])
        }
        
        print("🔄 Updating task \(taskId) status to: \(status)")
        
        try await db.collection("pods").document(projectId).collection("tasks").document(taskId).updateData([
            "status": status,
            "updatedAt": FieldValue.serverTimestamp()
        ])
        
        print("✅ Task status updated successfully")
    }
    
    // Update task priority
    func updateTaskPriority(projectId: String, taskId: String, priority: String) async throws {
        guard currentUser != nil else {
            throw NSError(domain: "FirebaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated".localized])
        }
        
        print("🔄 Updating task \(taskId) priority to: \(priority)")
        
        try await db.collection("pods").document(projectId).collection("tasks").document(taskId).updateData([
            "priority": priority,
            "updatedAt": FieldValue.serverTimestamp()
        ])
        
        print("✅ Task priority updated successfully")
    }
    
    // Delete task
    func deleteTask(projectId: String, taskId: String) async throws {
        guard currentUser != nil else {
            throw NSError(domain: "FirebaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated".localized])
        }
        
        print("🗑️ Deleting task: \(taskId)")
        
        try await db.collection("pods").document(projectId).collection("tasks").document(taskId).delete()
        
        print("✅ Task deleted successfully")
    }
    
    // Fetch tasks for a specific pod
    func getProjectTasks(projectId: String) async throws -> [ProjectTask] {
        print("📋 Fetching tasks for pod: \(projectId)")
        
        let snapshot = try await db.collection("pods").document(projectId).collection("tasks")
            .order(by: "createdAt", descending: false)
            .getDocuments()
        
        var tasks: [ProjectTask] = []
        
        for document in snapshot.documents {
            let data = document.data()
            let taskId = document.documentID
            
            // Parse task status
            let statusString = data["status"] as? String ?? "todo"
            let status = ProjectTask.TaskStatus(rawValue: statusString) ?? .todo
            
            // Parse task priority  
            let priorityString = data["priority"] as? String ?? "medium"
            let priority = ProjectTask.TaskPriority(rawValue: priorityString) ?? .medium
            
            let task = ProjectTask(
                id: taskId,
                title: data["title"] as? String ?? "",
                description: data["description"] as? String,
                assignedTo: data["assignedTo"] as? String,
                assignedToUsername: data["assignedToUsername"] as? String,
                dueDate: (data["dueDate"] as? Timestamp)?.dateValue(),
                createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date(),
                status: status,
                priority: priority
            )
            
            tasks.append(task)
        }
        
        print("✅ Fetched \(tasks.count) tasks for pod \(projectId)")
        return tasks
    }
    
    // MARK: - Idea Management Methods
    
    // Delete an idea spark
    func deleteIdeaSpark(ideaId: String, userId: String) async throws {
        print("🗑️ Attempting to delete idea: \(ideaId) by user: \(userId)")
        
        // First, verify that the user owns this idea
        let ideaDoc = try await db.collection("ideaSparks").document(ideaId).getDocument()
        
        guard ideaDoc.exists,
              let data = ideaDoc.data(),
              let authorId = data["authorId"] as? String else {
            throw NSError(domain: "FirebaseManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "Idea not found"])
        }
        
        // Check if the current user is the author
        guard authorId == userId else {
            throw NSError(domain: "FirebaseManager", code: 403, userInfo: [NSLocalizedDescriptionKey: "You can only delete your own ideas"])
        }
        
        // Delete all comments for this idea first
        let commentsSnapshot = try await db.collection("ideaSparks").document(ideaId).collection("comments").getDocuments()
        
        // Delete comments in batch
        let batch = db.batch()
        for commentDoc in commentsSnapshot.documents {
            batch.deleteDocument(commentDoc.reference)
        }
        
        // Delete the idea document itself
        batch.deleteDocument(db.collection("ideaSparks").document(ideaId))
        
        // Commit the batch delete
        try await batch.commit()
        
        print("✅ Successfully deleted idea: \(ideaId)")
    }
    
    // Test function to create a simple test idea
    func createTestIdea() async throws {
        print("🧪 Creating test idea...")
        
        let testData: [String: Any] = [
            "authorId": "test-user-123",
            "authorUsername": "Test User",
            "title": "Test Idea - \(Date().timeIntervalSince1970)",
            "description": "This is a test idea to verify Firebase connectivity",
            "tags": ["test", "firebase"],
            "isPublic": true,
            "status": "sparking",
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp(),
            "likes": 0,
            "comments": 0
        ]
        
        do {
            let docRef = try await db.collection("ideaSparks").addDocument(data: testData)
            print("✅ Test idea created with ID: \(docRef.documentID)")
        } catch {
            print("❌ Failed to create test idea: \(error)")
            throw error
        }
    }
    
    // Debug function to dump all database contents
    func debugDumpAllCollections() async {
        print("\n🔍 ===== FIREBASE DATABASE DEBUG DUMP =====")
        print("📱 Project: synapse-4578e")
        print("🔐 User authenticated: \(auth.currentUser != nil)")
        if let user = auth.currentUser {
            print("👤 Current user ID: \(user.uid)")
            print("📧 Current user email: \(user.email ?? "N/A")")
        }
        
        // Check ideaSparks collection
        print("\n📊 Checking 'ideaSparks' collection...")
        do {
            let snapshot = try await db.collection("ideaSparks").getDocuments()
            print("📈 Total documents in 'ideaSparks': \(snapshot.documents.count)")
            
            if snapshot.documents.isEmpty {
                print("📭 No documents found in 'ideaSparks' collection")
            } else {
                print("\n📋 Documents in 'ideaSparks':")
                print("===============================")
                
                for (index, document) in snapshot.documents.enumerated() {
                    let data = document.data()
                    print("\n📄 Document #\(index + 1) (ID: \(document.documentID)):")
                    print("   Title: \(data["title"] ?? "N/A")")
                    print("   Description: \(data["description"] ?? "N/A")")
                    print("   Author: \(data["authorUsername"] ?? "N/A") (ID: \(data["authorId"] ?? "N/A"))")
                    print("   Is Public: \(data["isPublic"] ?? "N/A")")
                    print("   Status: \(data["status"] ?? "N/A")")
                    print("   Tags: \(data["tags"] ?? "N/A")")
                    print("   Created At: \(data["createdAt"] ?? "N/A")")
                    print("   Updated At: \(data["updatedAt"] ?? "N/A")")
                    print("   Likes: \(data["likes"] ?? "N/A")")
                    print("   Comments: \(data["comments"] ?? "N/A")")
                    print("   Raw Data: \(data)")
                    print("   ---")
                }
            }
        } catch {
            print("❌ Error reading 'ideaSparks' collection: \(error)")
        }
        
        // Check ideas collection (old one)
        print("\n📊 Checking 'ideas' collection (old)...")
        do {
            let snapshot = try await db.collection("ideas").getDocuments()
            print("📈 Total documents in 'ideas': \(snapshot.documents.count)")
            
            if snapshot.documents.isEmpty {
                print("📭 No documents found in 'ideas' collection")
            } else {
                print("\n📋 Documents in 'ideas':")
                print("=========================")
                
                for (index, document) in snapshot.documents.enumerated() {
                    let data = document.data()
                    print("\n📄 Document #\(index + 1) (ID: \(document.documentID)):")
                    print("   Title: \(data["title"] ?? "N/A")")
                    print("   Author: \(data["authorUsername"] ?? "N/A") (ID: \(data["authorId"] ?? "N/A"))")
                    print("   Is Public: \(data["isPublic"] ?? "N/A")")
                    print("   Status: \(data["status"] ?? "N/A")")
                    print("   Raw Data: \(data)")
                    print("   ---")
                }
            }
        } catch {
            print("❌ Error reading 'ideas' collection: \(error)")
        }
        
        // Check users collection
        print("\n📊 Checking 'users' collection...")
        do {
            let snapshot = try await db.collection("users").getDocuments()
            print("📈 Total documents in 'users': \(snapshot.documents.count)")
            
            if !snapshot.documents.isEmpty {
                print("\n👥 Users found:")
                print("================")
                
                for (index, document) in snapshot.documents.enumerated() {
                    let data = document.data()
                    print("\n👤 User #\(index + 1) (ID: \(document.documentID)):")
                    print("   Username: \(data["username"] ?? "N/A")")
                    print("   Email: \(data["email"] ?? "N/A")")
                    print("   Ideas Sparked: \(data["ideasSparked"] ?? "N/A")")
                    print("   ---")
                }
            }
        } catch {
            print("❌ Error reading 'users' collection: \(error)")
        }
        
        print("\n🏁 ===== END DATABASE DEBUG DUMP =====\n")
    }
    
    func createIdeaSpark(title: String, description: String, tags: [String], isPublic: Bool, creatorId: String, creatorUsername: String) async throws -> String {
        print("🚀 Creating new idea spark: \(title)")
        print("📝 Details: Public=\(isPublic), Creator=\(creatorUsername), Tags=\(tags)")
        print("🔐 Current user authenticated: \(auth.currentUser != nil)")
        print("📍 Using collection: ideaSparks")
        
        let ideaData: [String: Any] = [
            "authorId": creatorId,
            "authorUsername": creatorUsername,
            "title": title,
            "description": description,
            "tags": tags,
            "isPublic": isPublic as Bool,  // Ensure it's stored as boolean
            "status": "sparking",  // Start as "Fresh" (sparking) when created
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp(),
            "likes": 0,
            "comments": 0
        ]
        
        print("📊 Data to be saved: \(ideaData)")
        
        do {
            let docRef = try await db.collection("ideaSparks").addDocument(data: ideaData)
            print("✅ Idea created successfully with ID: \(docRef.documentID)")
            
            // Immediately try to fetch it back to verify it was saved
            let savedDoc = try await db.collection("ideaSparks").document(docRef.documentID).getDocument()
            if savedDoc.exists {
                print("✅ Verification: Document exists in Firestore")
                if let savedData = savedDoc.data() {
                    print("📄 Saved data: \(savedData)")
                }
            } else {
                print("❌ Verification: Document NOT found in Firestore")
            }
            
            return docRef.documentID
        } catch {
            print("❌ Error creating idea: \(error)")
            throw error
        }
    }
    
    func getPublicIdeaSparks() async throws -> [IdeaSpark] {
        do {
            print("🔄 Fetching public idea sparks...")
            print("🔐 User authenticated: \(auth.currentUser != nil)")
            print("📍 Querying collection: ideaSparks")
            
            // First, let's check if there are ANY documents in the ideaSparks collection
            let allSnapshot = try await db.collection("ideaSparks").getDocuments()
            print("📊 Total documents in 'ideaSparks' collection: \(allSnapshot.documents.count)")
            
            // Print all documents for debugging
            for doc in allSnapshot.documents {
                let data = doc.data()
                print("📄 Document ID: \(doc.documentID)")
                print("   Title: \(data["title"] ?? "N/A")")
                print("   isPublic: \(data["isPublic"] ?? "N/A")")
                print("   authorId: \(data["authorId"] ?? "N/A")")
                print("   status: \(data["status"] ?? "N/A")")
                print("   createdAt: \(data["createdAt"] ?? "N/A")")
                print("   ---")
            }
            
            // Now query for public ideas specifically
            print("🔍 Querying for public ideas...")
            let snapshot = try await db.collection("ideaSparks")
                .order(by: "createdAt", descending: true)
                .limit(to: 50)
                .getDocuments()
            
            print("📊 Found \(snapshot.documents.count) public ideas after filtering")
            
            let ideas: [IdeaSpark] = snapshot.documents.compactMap { document in
                let data = document.data()
                
                // Handle isPublic as both boolean and integer
                let isPublicValue = data["isPublic"]
                let isPublic: Bool
                if let boolValue = isPublicValue as? Bool {
                    isPublic = boolValue
                } else if let intValue = isPublicValue as? Int {
                    isPublic = intValue == 1
                } else {
                    isPublic = false
                }
                
                // Only include public ideas
                guard isPublic else {
                    print("🔒 Skipping private idea: '\(data["title"] ?? "Unknown")'")
                    return nil
                }
                
                // Map status string to enum
                let statusString = data["status"] as? String ?? "planning"
                let status = IdeaSpark.IdeaStatus(rawValue: statusString) ?? .planning
                
                let idea = IdeaSpark(
                    id: document.documentID,
                    authorId: data["authorId"] as? String ?? "",
                    authorUsername: data["authorUsername"] as? String ?? "",
                    title: data["title"] as? String ?? "",
                    description: data["description"] as? String ?? "",
                    tags: data["tags"] as? [String] ?? [],
                    isPublic: isPublic,
                    createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                    updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date(),
                    likes: data["likes"] as? Int ?? 0,
                    comments: data["comments"] as? Int ?? 0,
                    status: status
                )
                
                print("💡 Mapped Idea: '\(idea.title)' (Status: \(idea.status.rawValue), Public: \(idea.isPublic))")
                return idea
            }
            
            print("🎯 Returning \(ideas.count) ideas to ExploreView")
            return ideas
        } catch {
            print("❌ Error fetching public ideas: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            throw error
        }
    }
    
    func getActivityFeed() async throws -> [[String: Any]] {
        do {
            let snapshot = try await db.collection("activities")
                .order(by: "timestamp", descending: true)
                .limit(to: 20)
                .getDocuments()
            
            return snapshot.documents.map { document in
                var data = document.data()
                data["id"] = document.documentID
                return data
            }
        } catch {
            throw error
        }
    }
    
    func getIdeaComments(ideaId: String) async throws -> [[String: Any]] {
        do {
            let snapshot = try await db.collection("ideaSparks").document(ideaId).collection("comments")
                .order(by: "timestamp", descending: false)
                .getDocuments()
            
            return snapshot.documents.map { document in
                var data = document.data()
                data["id"] = document.documentID
                return data
            }
        } catch {
            throw error
        }
    }
    
    func likeIdea(ideaId: String, userId: String) async throws {
        do {
            let ideaRef = db.collection("ideaSparks").document(ideaId)
            try await ideaRef.updateData([
                "likes": FieldValue.increment(Int64(1))
            ])
        } catch {
            throw error
        }
    }
    
    func addCommentToIdea(ideaId: String, content: String, authorId: String, authorUsername: String) async throws -> String {
        do {
            let commentData: [String: Any] = [
                "content": content,
                "authorId": authorId,
                "authorUsername": authorUsername,
                "timestamp": FieldValue.serverTimestamp()
            ]
            
            let docRef = try await db.collection("ideaSparks").document(ideaId).collection("comments").addDocument(data: commentData)
            
            // Update comment count
            try await db.collection("ideaSparks").document(ideaId).updateData([
                "comments": FieldValue.increment(Int64(1))
            ])
            
            return docRef.documentID
        } catch {
            throw error
        }
    }
    
    func getProjectAnalytics(projectId: String) async throws -> [String: Any] {
        do {
            // For now, return mock data structure
            // In a real implementation, you would aggregate data from various collections
            let mockAnalytics: [String: Any] = [
                "completionRate": 85,
                "activeMembers": 6,
                "tasksCompleted": 24,
                "totalTasks": 28,
                "avgResponseTime": 4,
                "taskProgress": [
                    ["date": Date().addingTimeInterval(-6 * 24 * 3600), "value": 5],
                    ["date": Date().addingTimeInterval(-5 * 24 * 3600), "value": 8],
                    ["date": Date().addingTimeInterval(-4 * 24 * 3600), "value": 12],
                    ["date": Date().addingTimeInterval(-3 * 24 * 3600), "value": 15],
                    ["date": Date().addingTimeInterval(-2 * 24 * 3600), "value": 18],
                    ["date": Date().addingTimeInterval(-1 * 24 * 3600), "value": 22],
                    ["date": Date(), "value": 24]
                ],
                "memberActivity": [
                    ["member": "Alex Chen", "tasksCompleted": 8],
                    ["member": "Sarah Kim", "tasksCompleted": 6],
                    ["member": "Mike Johnson", "tasksCompleted": 5],
                    ["member": "Emily Davis", "tasksCompleted": 3],
                    ["member": "David Wilson", "tasksCompleted": 2]
                ],
                "topContributors": [
                    ["username": "Alex Chen", "tasksCompleted": 8, "contributionPercentage": 33.3],
                    ["username": "Sarah Kim", "tasksCompleted": 6, "contributionPercentage": 25.0],
                    ["username": "Mike Johnson", "tasksCompleted": 5, "contributionPercentage": 20.8]
                ]
            ]
            
            return mockAnalytics
        } catch {
            throw error
        }
    }
    
    func getUserNotifications(userId: String) async throws -> [[String: Any]] {
        return try await userManager.getUserNotifications(userId: userId)
    }
    
    func markNotificationAsRead(notificationId: String) async throws {
        try await userManager.markNotificationAsRead(notificationId: notificationId)
    }
    
    func getAllUsers() async throws -> [[String: Any]] {
        return try await userManager.getAllUsers()
    }
    
    func inviteUserToProject(projectId: String, userId: String, role: String, message: String) async throws {
        try await podManager.inviteUserToProject(projectId: projectId, userId: userId, role: role, message: message)
    }
    
    func getPublicPods() async throws -> [IncubationProject] {
        return try await podManager.getPublicPods()
    }
    
    func getPodsByIdeaId(ideaId: String) async throws -> [IncubationProject] {
        return try await podManager.getPodsByIdeaId(ideaId: ideaId)
    }
    
    func followUser(followerId: String, followingId: String) async throws {
        try await userManager.followUser(followerId: followerId, followingId: followingId)
    }
    
    func unfollowUser(followerId: String, followingId: String) async throws {
        try await userManager.unfollowUser(followerId: followerId, followingId: followingId)
    }
    
    func isFollowing(followerId: String, followingId: String) async throws -> Bool {
        return try await userManager.isFollowing(followerId: followerId, followingId: followingId)
    }
    
    // MARK: - User Profile Management Methods (Delegated to UserManager)
    
    func updateUserStats(userId: String) async throws {
        try await userManager.updateUserStats(userId: userId)
    }
    
    func updateUserProfile(userId: String, data: [String: Any]) async throws {
        try await userManager.updateUserProfile(userId: userId, data: data)
    }
    
    func getUserProfile(userId: String) async throws -> [String: Any]? {
        return try await userManager.getUserProfile(userId: userId)
    }
    
    // MARK: - Debug Methods
    
    func testProjectMemberFunctionality(projectId: String) async {
        print("\n🧪 ===== TESTING POD MEMBER FUNCTIONALITY =====")
        print("📱 Testing pod: \(projectId)")
        
        do {
            // Test fetching pod members
            print("🔍 Fetching pod members...")
            let members = try await fetchProjectMembers(projectId: projectId)
            print("✅ Found \(members.count) members:")
            
            for member in members {
                print("  👤 \(member.username) (\(member.role)) - \(member.permissions.map { $0.rawValue }.joined(separator: ", "))")
            }
            
            // Test pod document structure
            print("\n🔍 Checking pod document structure...")
            let podDoc = try await db.collection("pods").document(projectId).getDocument()
            if let data = podDoc.data() {
                let memberIds = data["members"] as? [String] ?? []
                print("✅ Pod document has \(memberIds.count) member IDs: \(memberIds)")
                
                // Check if members subcollection exists
                let membersSnapshot = try await db.collection("pods").document(projectId).collection("members").getDocuments()
                print("✅ Members subcollection has \(membersSnapshot.documents.count) documents")
                
                if memberIds.count == membersSnapshot.documents.count {
                    print("✅ Member arrays are synchronized!")
                } else {
                    print("⚠️ Member arrays are NOT synchronized!")
                    print("   - Pod.members array: \(memberIds.count) members")
                    print("   - Members subcollection: \(membersSnapshot.documents.count) documents")
                }
            } else {
                print("❌ Pod document not found!")
            }
            
        } catch {
            print("❌ Error testing pod members: \(error.localizedDescription)")
        }
        
        print("🏁 ===== POD MEMBER TEST COMPLETE =====\n")
    }
    
    // MARK: - Debug Test Method
    
    func testBasicAuthentication() async {
        print("\n🧪 ===== TESTING BASIC AUTHENTICATION =====")
        print("🔐 Current Firebase Auth user: \(auth.currentUser?.uid ?? "None")")
        print("📧 Current auth error: \(authError ?? "None")")
        print("👤 Current local user: \(currentUser?.uid ?? "None")")
        
        // Test a simple Firebase operation
        do {
            print("🔍 Testing Firestore connectivity...")
            let testDoc = try await db.collection("test").document("connectivity").setData([
                "timestamp": FieldValue.serverTimestamp(),
                "test": "auth-debug"
            ])
            print("✅ Firestore connectivity: OK")
        } catch {
            print("❌ Firestore connectivity: FAILED - \(error)")
        }
        
        print("🏁 ===== BASIC AUTH TEST COMPLETE =====\n")
    }
    
    // MARK: - Simple Test Authentication
    
    func testSignInWithKnownCredentials() async {
        print("\n🧪 ===== TESTING SIGN-IN WITH TEST CREDENTIALS =====")
        
        let testEmail = "test@synapse.com"
        let testPassword = "test123456"
        
        print("📧 Testing with: \(testEmail)")
        print("🔑 Testing with password: \(testPassword)")
        
        do {
            print("🔐 Attempting Firebase sign-in...")
            let result = try await auth.signIn(withEmail: testEmail, password: testPassword)
            print("✅ TEST SIGN-IN SUCCESSFUL!")
            print("👤 User ID: \(result.user.uid)")
            print("📧 User email: \(result.user.email ?? "N/A")")
            print("🔍 Email verified: \(result.user.isEmailVerified)")
            
            // Test sign-out
            print("🚪 Testing sign-out...")
            try auth.signOut()
            print("✅ TEST SIGN-OUT SUCCESSFUL!")
            
        } catch {
            print("❌ TEST SIGN-IN FAILED:")
            print("   Error: \(error.localizedDescription)")
            print("   Full error: \(error)")
            
            if let authError = error as NSError? {
                print("   Error domain: \(authError.domain)")
                print("   Error code: \(authError.code)")
                print("   Error userInfo: \(authError.userInfo)")
            }
        }
        
        print("🏁 ===== TEST SIGN-IN COMPLETE =====\n")
    }
    
    func createTestUserIfNeeded() async {
        print("\n🔧 ===== CREATING TEST USER IF NEEDED =====")
        
        let testEmail = "test@synapse.com"
        let testPassword = "test123456"
        let testUsername = "TestUser"
        
        do {
            print("📝 Attempting to create test user...")
            let result = try await auth.createUser(withEmail: testEmail, password: testPassword)
            print("✅ Test user created successfully!")
            print("👤 User ID: \(result.user.uid)")
            
            // Create profile
            try await userManager.createUserProfile(userId: result.user.uid, email: testEmail, username: testUsername)
            print("✅ Test user profile created!")
            
            // Sign out
            try auth.signOut()
            print("🚪 Signed out test user")
            
        } catch {
            print("⚠️ Test user creation failed (might already exist): \(error.localizedDescription)")
        }
        
        print("🏁 ===== TEST USER CREATION COMPLETE =====\n")
    }
    
    // MARK: - Authentication State Verification
    
    func verifyAuthenticationState() async {
        print("\n🔍 ===== COMPREHENSIVE AUTH STATE VERIFICATION =====")
        
        // Check Firebase Auth state
        print("🔥 Firebase Auth:")
        print("   Current user: \(auth.currentUser?.uid ?? "None")")
        print("   User email: \(auth.currentUser?.email ?? "N/A")")
        print("   User verified: \(auth.currentUser?.isEmailVerified ?? false)")
        
        // Check local state
        print("📱 Local State:")
        print("   Current user: \(currentUser?.uid ?? "None")")
        print("   Email verified: \(isEmailVerified)")
        print("   Auth error: \(authError ?? "None")")
        print("   OTP sent: \(isOtpSent)")
        print("   OTP verified: \(isOtpVerified)")
        
        // Check app navigation state
        print("🧭 Navigation State:")
        if currentUser != nil {
            print("   Should show: Main App (ContentView)")
        } else {
            print("   Should show: Authentication View")
        }
        
        // Test basic Firebase operations
        print("🔧 Firebase Operations:")
        do {
            let timestamp = Date()
            try await db.collection("auth_test").document("state_check").setData([
                "timestamp": timestamp,
                "user_id": auth.currentUser?.uid ?? "anonymous",
                "check_time": FieldValue.serverTimestamp()
            ])
            print("   ✅ Firestore write: OK")
            
            let doc = try await db.collection("auth_test").document("state_check").getDocument()
            if doc.exists {
                print("   ✅ Firestore read: OK")
            } else {
                print("   ❌ Firestore read: FAILED")
            }
        } catch {
            print("   ❌ Firestore operations: FAILED - \(error)")
        }
        
        print("🏁 ===== AUTH STATE VERIFICATION COMPLETE =====\n")
    }
    
    // MARK: - Test Wrong Credentials
    
    func testWrongCredentials() async {
        print("\n🧪 ===== TESTING WRONG CREDENTIALS =====")
        
        let wrongEmail = "wrong@email.com"
        let wrongPassword = "wrongpassword"
        
        print("📧 Testing with wrong email: \(wrongEmail)")
        print("🔑 Testing with wrong password: \(wrongPassword)")
        
        do {
            try await signIn(email: wrongEmail, password: wrongPassword)
            print("❌ ERROR: Sign-in should have failed but didn't!")
        } catch {
            print("✅ Sign-in correctly failed as expected")
            print("📝 Error message set: \(authError ?? "No error message")")
        }
        
        print("🏁 ===== WRONG CREDENTIALS TEST COMPLETE =====\n")
    }
    
    func testCompleteSignInFlow() async {
        print("\n🧪 ===== TESTING COMPLETE SIGN-IN FLOW =====")
        
        // Test 1: Wrong credentials (should show error popup)
        print("\n1️⃣ Testing wrong credentials...")
        await testWrongCredentials()
        
        // Clear error before next test
        clearAuthError()
        
        // Test 2: Correct credentials (should sign in successfully) 
        print("\n2️⃣ Testing correct credentials...")
        do {
            try await signIn(email: "test@synapse.com", password: "test123456")
            print("✅ Correct credentials test: SUCCESS")
        } catch {
            print("❌ Correct credentials test: FAILED - \(error)")
        }
        
        print("\n🏁 ===== COMPLETE SIGN-IN FLOW TEST DONE =====\n")
    }
    
    // MARK: - Debug Existing Users
    
    func checkExistingUser(email: String) async {
        print("\n🔍 ===== CHECKING EXISTING USER: \(email) =====")
        
        // Check if user exists in Firestore
        do {
            let userSnapshot = try await db.collection("users")
                .whereField("email", isEqualTo: email)
                .getDocuments()
            
            if let userDoc = userSnapshot.documents.first {
                print("✅ User found in Firestore:")
                let data = userDoc.data()
                print("   📄 Document ID: \(userDoc.documentID)")
                print("   📧 Email: \(data["email"] ?? "N/A")")
                print("   👤 Username: \(data["username"] ?? "N/A")")
                print("   🔑 Auth Provider: \(data["authProvider"] ?? "N/A")")
                print("   📅 Created: \(data["createdAt"] ?? "N/A")")
                
                // Now check if this user exists in Firebase Auth
                print("\n🔍 Checking if user exists in Firebase Auth...")
                
                // Try to sign in with a dummy password to see what error we get
                do {
                    let _ = try await auth.signIn(withEmail: email, password: "dummypassword")
                    print("❌ Unexpected: Dummy password worked!")
                } catch {
                    if let authError = error as NSError? {
                        switch AuthErrorCode(rawValue: authError.code) {
                        case .userNotFound:
                            print("❌ PROBLEM FOUND: User exists in Firestore but NOT in Firebase Auth!")
                            print("   📝 Solution: User needs to be recreated in Firebase Auth")
                        case .wrongPassword:
                            print("✅ User exists in Firebase Auth (wrong password is expected)")
                            print("   📝 This user should be able to sign in with correct password")
                        case .tooManyRequests:
                            print("⚠️ Too many requests - but user likely exists in Firebase Auth")
                        default:
                            print("❓ Other auth error: \(authError.code) - \(error.localizedDescription)")
                        }
                    }
                }
                
            } else {
                print("❌ User NOT found in Firestore database")
            }
            
        } catch {
            print("❌ Error checking Firestore: \(error)")
        }
        
        print("🏁 ===== USER CHECK COMPLETE =====\n")
    }
    
    func checkAllProblematicUsers() async {
        print("\n🔍 ===== CHECKING ALL PROBLEMATIC USERS =====")
        
        let problematicEmails = [
            "djjjjnd@gmail.com",  // Ali
            "beveca8705@luxpolar.com"  // Masuadozel
        ]
        
        for email in problematicEmails {
            await checkExistingUser(email: email)
            
            // Small delay between checks
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        }
        
        print("🏁 ===== ALL USER CHECKS COMPLETE =====\n")
    }
    
    // MARK: - Test Login Error Flow
    
    func testLoginErrorFlow() async {
        print("\n🧪 ===== TESTING LOGIN ERROR FLOW =====")
        print("📋 Testing that user stays on login page after error...")
        
        // Test wrong credentials
        do {
            try await signIn(email: "wrong@test.com", password: "wrongpass")
            print("❌ ERROR: Should have failed!")
        } catch {
            print("✅ Correctly failed with wrong credentials")
            print("📱 Error message set: '\(authError ?? "No error")'")
            print("👤 User state after error: \(currentUser?.uid ?? "None (correct)")")
            print("📝 User should now see popup and stay on login page")
        }
        
        print("🏁 ===== LOGIN ERROR FLOW TEST COMPLETE =====\n")
    }
} 