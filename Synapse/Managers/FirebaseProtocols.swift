//
//  FirebaseProtocols.swift
//  Synapse
//
//  Created by Abdulrahman Alshehri on 18/01/1447 AH.
//

import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions

// MARK: - Core Firebase Service Protocol
protocol FirebaseServiceProtocol {
    var auth: Auth { get }
    var db: Firestore { get }
    var functions: Functions { get }
}

// MARK: - Authentication Service Protocol
protocol AuthenticationServiceProtocol: ObservableObject {
    var currentUser: User? { get }
    var authError: String? { get }
    var isEmailVerified: Bool { get }
    var isOtpSent: Bool { get }
    var isOtpVerified: Bool { get }
    var isSigningUp: Bool { get }
    
    func signUp(email: String, password: String, username: String) async throws
    func signIn(email: String, password: String) async throws
    func signOut() throws
    func sendOtpEmail(email: String) async throws
    func verifyOtp(email: String, otp: String) async throws
    func resetOtpState()
    func clearAuthError()
    func checkUserExists(email: String) async throws -> Bool
    func validateUsername(_ username: String) async throws -> Bool
    func signInAnonymously() async throws
    func signInWithGoogle() async throws
}

// MARK: - User Management Service Protocol
protocol UserManagerProtocol: ObservableObject {
    func createUserProfile(userId: String, email: String, username: String) async throws
    func getUserProfile(userId: String) async throws -> [String: Any]?
    func updateUserProfile(userId: String, data: [String: Any]) async throws
    func getUserFavorites(userId: String) async throws -> [[String: Any]]
    func removeFromFavorites(userId: String, ideaId: String) async throws
    func getUserIdeas(userId: String) async throws -> [IdeaSpark]
    func getUserPrivateIdeas(userId: String) async throws -> [IdeaSpark]
    func getUserNotifications(userId: String) async throws -> [[String: Any]]
    func markNotificationAsRead(notificationId: String) async throws
    func getAllUsers() async throws -> [[String: Any]]
    func followUser(followerId: String, followingId: String) async throws
    func unfollowUser(followerId: String, followingId: String) async throws
    func isFollowing(followerId: String, followingId: String) async throws -> Bool
    func updateUserStats(userId: String) async throws
}

// MARK: - Pod Management Service Protocol
protocol PodManagerProtocol: ObservableObject {
    func createPod(name: String, description: String, ideaId: String?, isPublic: Bool) async throws -> String
    func createPodFromIdea(name: String, description: String, ideaId: String, isPublic: Bool) async throws -> String
    func updateProject(projectId: String, data: [String: Any]) async throws
    func deleteProject(projectId: String) async throws
    func getUserPods(userId: String) async throws -> [IncubationProject]
    func getPublicPods() async throws -> [IncubationProject]
    func getPodsByIdeaId(ideaId: String) async throws -> [IncubationProject]
    func addMemberToProject(projectId: String, userId: String, role: String) async throws
    func removeMemberFromProject(projectId: String, userId: String) async throws
    func inviteUserToProject(projectId: String, userId: String, role: String, message: String) async throws
    func fetchProjectMembers(projectId: String) async throws -> [ProjectMember]
}

// MARK: - Shared Firebase Service Implementation
class FirebaseService: FirebaseServiceProtocol {
    static let shared = FirebaseService()
    
    let auth = Auth.auth()
    let db = Firestore.firestore()
    let functions = Functions.functions()
    
    private init() {}
} 