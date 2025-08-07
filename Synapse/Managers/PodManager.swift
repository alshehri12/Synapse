//
//  PodManager.swift
//  Synapse
//
//  Created by Abdulrahman Alshehri on 18/01/1447 AH.
//

import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions

class PodManager: ObservableObject, PodManagerProtocol {
    static let shared = PodManager()
    
    private let firebaseService: FirebaseServiceProtocol
    
    private var auth: Auth { firebaseService.auth }
    private var db: Firestore { firebaseService.db }
    private var functions: Functions { firebaseService.functions }
    
    init(firebaseService: FirebaseServiceProtocol = FirebaseService.shared) {
        self.firebaseService = firebaseService
    }
    
    // MARK: - Pod Management Methods
    
    func createPod(name: String, description: String, ideaId: String?, isPublic: Bool) async throws -> String {
        guard let currentUser = auth.currentUser else {
            throw NSError(domain: "PodManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated".localized])
        }
        
        let podData: [String: Any] = [
            "name": name,
            "description": description,
            "ideaId": ideaId ?? "",
            "creatorId": currentUser.uid,
            "isPublic": isPublic,
            "status": "active",
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp(),
            "members": [currentUser.uid],
            "tasks": []
        ]
        
        let docRef = try await db.collection("pods").addDocument(data: podData)
        
        // Create the creator as the first member with admin permissions
        try await addProjectMemberDetails(projectId: docRef.documentID, userId: currentUser.uid, role: "Creator", permissions: [.admin, .edit, .view, .comment])
        
        return docRef.documentID
    }
    
    func createPodFromIdea(name: String, description: String, ideaId: String, isPublic: Bool) async throws -> String {
        guard let currentUser = auth.currentUser else {
            throw NSError(domain: "PodManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated".localized])
        }
        
        // SECURITY CHECK: Verify that the current user is the owner of the idea
        print("🔒 SECURITY: Checking if user \(currentUser.uid) can create pod from idea \(ideaId)")
        let ideaDoc = try await db.collection("ideaSparks").document(ideaId).getDocument()
        
        guard let ideaData = ideaDoc.data(),
              let ideaAuthorId = ideaData["authorId"] as? String,
              ideaAuthorId == currentUser.uid else {
            print("❌ SECURITY: User \(currentUser.uid) is NOT the owner of idea \(ideaId)")
            throw NSError(domain: "PodManager", code: -2, userInfo: [NSLocalizedDescriptionKey: "Only the idea owner can create pods from this idea".localized])
        }
        
        print("✅ SECURITY: User \(currentUser.uid) is confirmed owner of idea \(ideaId)")
        
        let podData: [String: Any] = [
            "name": name,
            "description": description,
            "ideaId": ideaId,
            "creatorId": currentUser.uid,
            "isPublic": isPublic,
            "status": "active",
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp(),
            "members": [currentUser.uid],
            "tasks": []
        ]
        
        print("💾 DEBUG: Storing pod with data:")
        print("  📛 name: '\(name)'")
        print("  💡 ideaId: '\(ideaId)'")
        print("  👤 creatorId: '\(currentUser.uid)'")
        print("  🌍 isPublic: \(isPublic)")
        
        let docRef = try await db.collection("pods").addDocument(data: podData)
        print("📝 DEBUG: Pod document created with ID: \(docRef.documentID)")
        
        // Create the creator as the first member with admin permissions
        try await addProjectMemberDetails(projectId: docRef.documentID, userId: currentUser.uid, role: "Creator", permissions: [.admin, .edit, .view, .comment])
        
        // Verify the pod was stored correctly
        let verifyDoc = try await db.collection("pods").document(docRef.documentID).getDocument()
        if let verifyData = verifyDoc.data() {
            let storedIdeaId = verifyData["ideaId"] as? String ?? "NO_IDEA_ID"
            let storedIsPublic = verifyData["isPublic"] as? Bool ?? false
            print("✅ VERIFICATION: Pod stored correctly - ideaId: '\(storedIdeaId)', isPublic: \(storedIsPublic)")
            
            if storedIdeaId != ideaId {
                print("🚨 CRITICAL: ideaId mismatch! Expected: '\(ideaId)', Stored: '\(storedIdeaId)'")
            }
        } else {
            print("❌ VERIFICATION: Could not read back the created pod!")
        }
        
        // Update the idea status to "incubating" (Active) now that a pod has been created
        try await db.collection("ideaSparks").document(ideaId).updateData([
            "status": "incubating",
            "updatedAt": FieldValue.serverTimestamp()
        ])
        print("✅ Updated idea status to 'incubating' (Active)")
        
        print("🎉 SUCCESS: Pod created from idea by authorized user")
        return docRef.documentID
    }
    
    func updateProject(projectId: String, data: [String: Any]) async throws {
        do {
            var updateData = data
            updateData["updatedAt"] = Timestamp(date: Date())
            try await db.collection("pods").document(projectId).updateData(updateData)
        } catch {
            throw error
        }
    }
    
    func deleteProject(projectId: String) async throws {
        do {
            try await db.collection("pods").document(projectId).delete()
        } catch {
            throw error
        }
    }
    
    func getUserPods(userId: String) async throws -> [IncubationProject] {
        do {
            let snapshot = try await db.collection("pods")
                .whereField("members", arrayContains: userId)
                .getDocuments()
            
            var pods: [IncubationProject] = []
            
            for document in snapshot.documents {
                let data = document.data()
                let projectId = document.documentID
                
                // Fetch members with full details
                print("🔍 DEBUG: Processing pod '\(data["name"] as? String ?? "Unknown")' (ID: \(projectId))")
                let members = try await fetchProjectMembers(projectId: projectId)
                print("👥 DEBUG: Fetched \(members.count) members for pod '\(data["name"] as? String ?? "Unknown")'")
                
                // Fetch tasks for this pod
                let tasks = try await getProjectTasks(projectId: projectId)
                print("📋 DEBUG: Fetched \(tasks.count) tasks for pod '\(data["name"] as? String ?? "Unknown")'")
                
                // Map status string to enum
                let statusString = data["status"] as? String ?? "planning"
                let status = IncubationProject.ProjectStatus(rawValue: statusString) ?? .planning
                
                let pod = IncubationProject(
                    id: projectId,
                    ideaId: data["ideaId"] as? String ?? "",
                    name: data["name"] as? String ?? "",
                    description: data["description"] as? String ?? "",
                    creatorId: data["creatorId"] as? String ?? "",
                    isPublic: data["isPublic"] as? Bool ?? false,
                    createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                    updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date(),
                    members: members, // Now properly populated!
                    tasks: tasks, // ✅ Now properly loaded from Firebase!
                    status: status
                )
                pods.append(pod)
                print("✅ Loaded pod '\(pod.name)' with \(members.count) members")
                
                // Debug: Print member details
                for member in members {
                    print("  👤 Member: \(member.username) (\(member.role)) - \(member.permissions.map { $0.rawValue }.joined(separator: ", "))")
                }
            }
            
            return pods
        } catch {
            throw error
        }
    }
    
    func getPublicPods() async throws -> [IncubationProject] {
        do {
            let snapshot = try await db.collection("pods")
                .whereField("isPublic", isEqualTo: true)
                .order(by: "createdAt", descending: true)
                .limit(to: 50)
                .getDocuments()
            
            var pods: [IncubationProject] = []
            
            for document in snapshot.documents {
                let data = document.data()
                let podId = document.documentID
                
                // Fetch members with full details
                let members = try await fetchProjectMembers(projectId: podId)
                
                // Fetch tasks for this pod
                let tasks = try await getProjectTasks(projectId: podId)
                
                // Map status string to enum
                let statusString = data["status"] as? String ?? "planning"
                let status = IncubationProject.ProjectStatus(rawValue: statusString) ?? .planning
                
                let pod = IncubationProject(
                    id: podId,
                    ideaId: data["ideaId"] as? String ?? "",
                    name: data["name"] as? String ?? "",
                    description: data["description"] as? String ?? "",
                    creatorId: data["creatorId"] as? String ?? "",
                    isPublic: data["isPublic"] as? Bool ?? false,
                    createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                    updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date(),
                    members: members, // Now properly populated!
                    tasks: tasks, // ✅ Now properly loaded from Firebase!
                    status: status
                )
                pods.append(pod)
                print("✅ Loaded public pod '\(pod.name)' with \(members.count) members")
            }
            
            return pods
        } catch {
            throw error
        }
    }
    
    // Method to get pods for a specific idea
    func getPodsByIdeaId(ideaId: String) async throws -> [IncubationProject] {
        do {
            print("🔍 DEBUG: Fetching pods for ideaId: '\(ideaId)'")
            print("🔍 DEBUG: Query conditions - ideaId: '\(ideaId)', isPublic: true")
            
            // First, let's check ALL pods to see what's in the collection
            let allPodsSnapshot = try await db.collection("pods").getDocuments()
            print("📊 DEBUG: Total pods in collection: \(allPodsSnapshot.documents.count)")
            
            for doc in allPodsSnapshot.documents {
                let data = doc.data()
                let storedIdeaId = data["ideaId"] as? String ?? "NO_IDEA_ID"
                let isPublic = data["isPublic"] as? Bool ?? false
                let podName = data["name"] as? String ?? "NO_NAME"
                print("  📄 Pod '\(podName)': ideaId='\(storedIdeaId)', isPublic=\(isPublic), match=\(storedIdeaId == ideaId)")
            }
            
            // Now do the actual query (simplified to avoid composite index requirement)
            let snapshot = try await db.collection("pods")
                .whereField("ideaId", isEqualTo: ideaId)
                .whereField("isPublic", isEqualTo: true)
                .getDocuments()
            
            print("📊 DEBUG: Query result - Found \(snapshot.documents.count) pods for idea '\(ideaId)'")
            
            if snapshot.documents.isEmpty {
                print("⚠️ DEBUG: No pods found! Possible reasons:")
                print("  1. ideaId mismatch during creation/query")
                print("  2. Pod created with isPublic=false")
                print("  3. Firestore indexing delay")
                print("  4. Query conditions too restrictive")
            }
            
            var pods: [IncubationProject] = []
            
            for document in snapshot.documents {
                let data = document.data()
                let projectId = document.documentID
                
                print("🔄 DEBUG: Processing found pod '\(data["name"] as? String ?? "Unknown")' (ID: \(projectId))")
                
                // Fetch members with full details
                let members = try await fetchProjectMembers(projectId: projectId)
                
                // Map status string to enum
                let statusString = data["status"] as? String ?? "planning"
                let status = IncubationProject.ProjectStatus(rawValue: statusString) ?? .planning
                
                let pod = IncubationProject(
                    id: projectId,
                    ideaId: data["ideaId"] as? String ?? "",
                    name: data["name"] as? String ?? "",
                    description: data["description"] as? String ?? "",
                    creatorId: data["creatorId"] as? String ?? "",
                    isPublic: data["isPublic"] as? Bool ?? false,
                    createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                    updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date(),
                    members: members,
                    tasks: [], // TODO: Implement task fetching
                    status: status
                )
                pods.append(pod)
                print("✅ Loaded pod '\(pod.name)' for idea '\(ideaId)'")
            }
            
            // Sort by creation date (newest first) since we removed the order clause
            pods.sort { $0.createdAt > $1.createdAt }
            
            print("📝 DEBUG: Returning \(pods.count) pods to UI")
            return pods
        } catch {
            print("❌ ERROR: Failed to fetch pods for idea '\(ideaId)': \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Pod Member Management
    
    func addMemberToProject(projectId: String, userId: String, role: String = "Member") async throws {
        do {
            // First, add the user ID to the pod's members array
            try await db.collection("pods").document(projectId).updateData([
                "members": FieldValue.arrayUnion([userId]),
                "updatedAt": Timestamp(date: Date())
            ])
            
            // Then add detailed member information to the subcollection
            let permissions: [ProjectMember.Permission] = [.view, .comment] // Default permissions for new members
            try await addProjectMemberDetails(projectId: projectId, userId: userId, role: role, permissions: permissions)
            
            print("✅ Successfully added member \(userId) to pod \(projectId)")
        } catch {
            print("❌ Failed to add member to pod: \(error.localizedDescription)")
            throw error
        }
    }
    
    func removeMemberFromProject(projectId: String, userId: String) async throws {
        do {
            // Remove from the pod's members array
            try await db.collection("pods").document(projectId).updateData([
                "members": FieldValue.arrayRemove([userId]),
                "updatedAt": Timestamp(date: Date())
            ])
            
            // Remove from the members subcollection
            try await db.collection("pods").document(projectId).collection("members").document(userId).delete()
            
            print("✅ Successfully removed member \(userId) from pod \(projectId)")
        } catch {
            print("❌ Failed to remove member from pod: \(error.localizedDescription)")
            throw error
        }
    }
    
    func inviteUserToProject(projectId: String, userId: String, role: String, message: String) async throws {
        guard let currentUser = auth.currentUser else {
            throw NSError(domain: "PodManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated".localized])
        }
        
        do {
            let invitationData: [String: Any] = [
                "projectId": projectId,
                "userId": userId,
                "invitedBy": currentUser.uid,
                "role": role,
                "message": message,
                "status": "pending",
                "createdAt": FieldValue.serverTimestamp()
            ]
            
            try await db.collection("pod_invitations").addDocument(data: invitationData)
        } catch {
            throw error
        }
    }
    
    // MARK: - Helper Methods
    
    // Helper method to add member details to pod's members subcollection
    private func addProjectMemberDetails(projectId: String, userId: String, role: String, permissions: [ProjectMember.Permission]) async throws {
        // Get user profile
        guard let userProfileData = try await getUserProfile(userId: userId) else {
            throw NSError(domain: "PodManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "User profile not found"])
        }
        
        let username = userProfileData["username"] as? String ?? "Unknown User"
        
        let memberData: [String: Any] = [
            "userId": userId,
            "username": username,
            "role": role,
            "joinedAt": Timestamp(date: Date()),
            "permissions": permissions.map { $0.rawValue }
        ]
        
        try await db.collection("pods").document(projectId).collection("members").document(userId).setData(memberData)
        print("✅ Added member details for user \(username) to pod \(projectId)")
    }
    
    // Method to fetch pod members from subcollection
    func fetchProjectMembers(projectId: String) async throws -> [ProjectMember] {
        do {
            print("🔍 DEBUG: Fetching members for pod: \(projectId)")
            let snapshot = try await db.collection("pods").document(projectId).collection("members").getDocuments()
            
            print("📊 DEBUG: Found \(snapshot.documents.count) member documents in subcollection")
            
            if snapshot.documents.isEmpty {
                print("⚠️ DEBUG: No members found in subcollection for pod \(projectId)")
                // Fallback: try to get members from main pod document
                return try await fetchMembersFromMainDocument(projectId: projectId)
            }
            
            let members = snapshot.documents.compactMap { document in
                let data = document.data()
                print("👤 DEBUG: Processing member document \(document.documentID): \(data)")
                
                let permissionsArray = data["permissions"] as? [String] ?? []
                let permissions = permissionsArray.compactMap { ProjectMember.Permission(rawValue: $0) }
                
                let member = ProjectMember(
                    id: document.documentID,
                    userId: data["userId"] as? String ?? "",
                    username: data["username"] as? String ?? "",
                    role: data["role"] as? String ?? "",
                    joinedAt: (data["joinedAt"] as? Timestamp)?.dateValue() ?? Date(),
                    permissions: permissions
                )
                
                print("✅ DEBUG: Created member object: \(member.username) (\(member.role))")
                return member
            }
            
            print("📝 DEBUG: Returning \(members.count) members for pod \(projectId)")
            return members
        } catch {
            print("❌ Failed to fetch pod members: \(error.localizedDescription)")
            return []
        }
    }
    
    // Fallback method to create members from main pod document
    private func fetchMembersFromMainDocument(projectId: String) async throws -> [ProjectMember] {
        do {
            print("🔄 DEBUG: Falling back to main document for pod \(projectId)")
            let podDoc = try await db.collection("pods").document(projectId).getDocument()
            
            guard let data = podDoc.data(),
                  let memberIds = data["members"] as? [String] else {
                print("❌ DEBUG: No members array found in main pod document")
                return []
            }
            
            print("👥 DEBUG: Found \(memberIds.count) member IDs in main document: \(memberIds)")
            
            var members: [ProjectMember] = []
            
            for userId in memberIds {
                do {
                    // Get user profile to create member
                    let userProfileData = try await getUserProfile(userId: userId)
                    
                    // Determine role based on whether user is the creator
                    let creatorId = data["creatorId"] as? String ?? ""
                    let role = (userId == creatorId) ? "Creator" : "Member"
                    let permissions: [ProjectMember.Permission] = (userId == creatorId) ? [.admin, .edit, .view, .comment] : [.view, .comment]
                    
                    let member = ProjectMember(
                        id: userId,
                        userId: userId,
                        username: userProfileData?["username"] as? String ?? "Unknown User",
                        role: role,
                        joinedAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                        permissions: permissions
                    )
                    
                    members.append(member)
                    print("✅ DEBUG: Created fallback member: \(member.username) (\(member.role))")
                    
                    // Optionally, create the subcollection entry for future use
                    try await addProjectMemberDetails(projectId: projectId, userId: userId, role: role, permissions: permissions)
                    
                } catch {
                    print("❌ DEBUG: Failed to create member for userId \(userId): \(error.localizedDescription)")
                }
            }
            
            print("📝 DEBUG: Created \(members.count) fallback members")
            return members
        } catch {
            print("❌ DEBUG: Failed to fetch members from main document: \(error.localizedDescription)")
            return []
        }
    }
    
    private func getUserProfile(userId: String) async throws -> [String: Any]? {
        do {
            let document = try await db.collection("users").document(userId).getDocument()
            if document.exists {
                return document.data()
            } else {
                return nil
            }
        } catch {
            throw error
        }
    }
    
    // MARK: - Task Management (placeholder for now)
    private func getProjectTasks(projectId: String) async throws -> [ProjectTask] {
        // This will be moved to TaskManager later
        return []
    }
} 