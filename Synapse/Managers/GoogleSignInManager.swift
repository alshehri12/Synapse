//
//  GoogleSignInManager.swift
//  Synapse
//
//  Created by Abdulrahman Alshehri on 18/01/1447 AH.
//

import Foundation
import Firebase
import FirebaseAuth
import GoogleSignIn
import GoogleSignInSwift

class GoogleSignInManager: ObservableObject {
    static let shared = GoogleSignInManager()
    
    @Published var isSigningIn = false
    @Published var error: String?
    
    private init() {}
    
    func configure() {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            print("Error: Firebase client ID not found")
            return
        }
        
        print("Configuring Google Sign-In with client ID: \(clientID)")
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        print("Google Sign-In configured successfully")
    }
    
    func signIn() async throws -> AuthDataResult {
        print("Starting Google Sign-In process...")
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            print("Error: Could not get root view controller")
            throw GoogleSignInError.presentationError
        }
        
        await MainActor.run {
            isSigningIn = true
            error = nil
        }
        
        do {
            print("Presenting Google Sign-In...")
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            print("Google Sign-In completed successfully")
            
            guard let idToken = result.user.idToken?.tokenString else {
                print("Error: Could not get ID token")
                throw GoogleSignInError.tokenError
            }
            
            print("Creating Firebase credential...")
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )
            
            print("Signing in to Firebase...")
            let authResult = try await Auth.auth().signIn(with: credential)
            print("Firebase authentication successful")
            
            // Set the user's display name in Firebase Auth
            let username = result.user.profile?.name ?? "Google User"
            let changeRequest = authResult.user.createProfileChangeRequest()
            changeRequest.displayName = username
            try await changeRequest.commitChanges()
            print("✅ Display name set to: \(username)")
            
            // Create or update user profile
            try await createOrUpdateUserProfile(from: result.user, authResult: authResult)
            print("User profile updated successfully")
            
            await MainActor.run {
                isSigningIn = false
            }
            
            return authResult
            
        } catch {
            print("Google Sign-In error: \(error.localizedDescription)")
            await MainActor.run {
                isSigningIn = false
                self.error = error.localizedDescription
            }
            throw error
        }
    }
    
    func signOut() {
        GIDSignIn.sharedInstance.signOut()
    }
    
    private func createOrUpdateUserProfile(from googleUser: GIDGoogleUser, authResult: AuthDataResult) async throws {
        let userId = authResult.user.uid
        let email = googleUser.profile?.email ?? ""
        let username = googleUser.profile?.name ?? "Google User"
        
        let userProfile = [
            "id": userId,
            "username": username,
            "email": email,
            "bio": "",
            "avatarURL": googleUser.profile?.imageURL(withDimension: 200)?.absoluteString ?? "",
            "skills": [],
            "interests": [],
            "ideasSparked": 0,
            "projectsContributed": 0,
            "dateJoined": Timestamp(date: Date()),
            "createdAt": Timestamp(date: Date()),
            "updatedAt": Timestamp(date: Date()),
            "authProvider": "google"
        ] as [String: Any]
        
        let db = Firestore.firestore()
        
        // Check if user profile already exists
        let document = try await db.collection("users").document(userId).getDocument()
        
        if document.exists {
            // Update existing profile with Google info
            try await db.collection("users").document(userId).updateData([
                "username": username,
                "email": email,
                "avatarURL": googleUser.profile?.imageURL(withDimension: 200)?.absoluteString ?? "",
                "updatedAt": Timestamp(date: Date()),
                "authProvider": "google"
            ])
        } else {
            // Create new profile
            try await db.collection("users").document(userId).setData(userProfile)
        }
    }
}

enum GoogleSignInError: Error, LocalizedError {
    case presentationError
    case tokenError
    
    var errorDescription: String? {
        switch self {
        case .presentationError:
            return "Failed to present Google Sign-In".localized
        case .tokenError:
            return "Failed to get authentication token".localized
        }
    }
} 