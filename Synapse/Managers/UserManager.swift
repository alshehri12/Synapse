//
//  UserManager.swift
//  Synapse
//
//  Created by Abdulrahman Alshehri on 18/01/1447 AH.
//

import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions

class UserManager: ObservableObject, UserManagerProtocol {
    static let shared = UserManager()
    
    private let firebaseService: FirebaseServiceProtocol
    
    private var auth: Auth { firebaseService.auth }
    private var db: Firestore { firebaseService.db }
    private var functions: Functions { firebaseService.functions }
    
    init(firebaseService: FirebaseServiceProtocol = FirebaseService.shared) {
        self.firebaseService = firebaseService
    }
    
    // MARK: - User Profile Methods
    
    func createUserProfile(userId: String, email: String, username: String) async throws {
        let userData: [String: Any] = [
            "userId": userId,
            "email": email,
            "username": username,
            "displayName": username,
            "createdAt": FieldValue.serverTimestamp(),
            "authProvider": "email",
            "profileImageUrl": "",
            "bio": "",
            "location": "",
            "website": "",
            "socialLinks": [:],
            "preferences": [
                "language": "en",
                "notifications": true,
                "privacy": "public"
            ]
        ]
        
        try await db.collection("users").document(userId).setData(userData)
        print("✅ User profile created successfully")
    }
    
    func getUserProfile(userId: String) async throws -> [String: Any]? {
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
    
    func updateUserProfile(userId: String, data: [String: Any]) async throws {
        do {
            var updateData = data
            updateData["updatedAt"] = Timestamp(date: Date())
            try await db.collection("users").document(userId).updateData(updateData)
        } catch {
            throw error
        }
    }
    
    func getUserFavorites(userId: String) async throws -> [[String: Any]] {
        do {
            let document = try await db.collection("users").document(userId).getDocument()
            if let data = document.data(),
               let favoriteIds = data["favorites"] as? [String] {
                
                // Fetch the actual idea data for each favorite
                var favorites: [[String: Any]] = []
                
                for ideaId in favoriteIds {
                    let ideaDoc = try await db.collection("ideaSparks").document(ideaId).getDocument()
                    if let ideaData = ideaDoc.data() {
                        var favoriteData: [String: Any] = ideaData
                        favoriteData["ideaId"] = ideaId
                        favorites.append(favoriteData)
                    }
                }
                
                return favorites
            }
            return []
        } catch {
            throw error
        }
    }
    
    func removeFromFavorites(userId: String, ideaId: String) async throws {
        do {
            let documentRef = db.collection("users").document(userId)
            let updateData: [String: Any] = [
                "favorites": FieldValue.arrayRemove([ideaId])
            ]
            try await documentRef.updateData(updateData)
        } catch {
            throw error
        }
    }
    
    func getUserIdeas(userId: String) async throws -> [IdeaSpark] {
        do {
            let snapshot = try await db.collection("ideaSparks")
                .whereField("authorId", isEqualTo: userId)
                .whereField("isPublic", isEqualTo: true)
                .getDocuments()
            
            return snapshot.documents.compactMap { document in
                let data = document.data()
                
                // Map status string to enum
                let statusString = data["status"] as? String ?? "planning"
                let status = IdeaSpark.IdeaStatus(rawValue: statusString) ?? .planning
                
                return IdeaSpark(
                    id: document.documentID,
                    authorId: data["authorId"] as? String ?? "",
                    authorUsername: data["authorUsername"] as? String ?? "",
                    title: data["title"] as? String ?? "",
                    description: data["description"] as? String ?? "",
                    tags: data["tags"] as? [String] ?? [],
                    isPublic: data["isPublic"] as? Bool ?? false,
                    createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                    updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date(),
                    likes: data["likes"] as? Int ?? 0,
                    comments: data["comments"] as? Int ?? 0,
                    status: status
                )
            }
        } catch {
            throw error
        }
    }
    
    func getUserPrivateIdeas(userId: String) async throws -> [IdeaSpark] {
        do {
            let snapshot = try await db.collection("ideaSparks")
                .whereField("authorId", isEqualTo: userId)
                .whereField("isPublic", isEqualTo: false)
                .getDocuments()
            
            return snapshot.documents.compactMap { document in
                let data = document.data()
                
                // Map status string to enum
                let statusString = data["status"] as? String ?? "planning"
                let status = IdeaSpark.IdeaStatus(rawValue: statusString) ?? .planning
                
                return IdeaSpark(
                    id: document.documentID,
                    authorId: data["authorId"] as? String ?? "",
                    authorUsername: data["authorUsername"] as? String ?? "",
                    title: data["title"] as? String ?? "",
                    description: data["description"] as? String ?? "",
                    tags: data["tags"] as? [String] ?? [],
                    isPublic: data["isPublic"] as? Bool ?? false,
                    createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                    updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date(),
                    likes: data["likes"] as? Int ?? 0,
                    comments: data["comments"] as? Int ?? 0,
                    status: status
                )
            }
        } catch {
            throw error
        }
    }
    
    func getUserNotifications(userId: String) async throws -> [[String: Any]] {
        do {
            let snapshot = try await db.collection("notifications")
                .whereField("userId", isEqualTo: userId)
                .order(by: "timestamp", descending: true)
                .limit(to: 50)
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
    
    func markNotificationAsRead(notificationId: String) async throws {
        do {
            try await db.collection("notifications").document(notificationId).updateData([
                "isRead": true
            ])
        } catch {
            throw error
        }
    }
    
    func getAllUsers() async throws -> [[String: Any]] {
        do {
            let snapshot = try await db.collection("users")
                .whereField("isPublic", isEqualTo: true)
                .limit(to: 100)
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
    
    func followUser(followerId: String, followingId: String) async throws {
        do {
            let followData: [String: Any] = [
                "followerId": followerId,
                "followingId": followingId,
                "createdAt": FieldValue.serverTimestamp()
            ]
            
            try await db.collection("follows").addDocument(data: followData)
        } catch {
            throw error
        }
    }
    
    func unfollowUser(followerId: String, followingId: String) async throws {
        do {
            let snapshot = try await db.collection("follows")
                .whereField("followerId", isEqualTo: followerId)
                .whereField("followingId", isEqualTo: followingId)
                .getDocuments()
            
            for document in snapshot.documents {
                try await document.reference.delete()
            }
        } catch {
            throw error
        }
    }
    
    func isFollowing(followerId: String, followingId: String) async throws -> Bool {
        do {
            let snapshot = try await db.collection("follows")
                .whereField("followerId", isEqualTo: followerId)
                .whereField("followingId", isEqualTo: followingId)
                .getDocuments()
            
            return !snapshot.documents.isEmpty
        } catch {
            throw error
        }
    }
    
    func updateUserStats(userId: String) async throws {
        do {
            // This method would typically update user statistics
            // For now, we'll just update the lastActivity timestamp
            try await db.collection("users").document(userId).updateData([
                "lastActivity": Timestamp(date: Date())
            ])
        } catch {
            throw error
        }
    }
} 