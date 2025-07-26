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

class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    
    @Published var currentUser: User?
    @Published var authError: String?
    @Published var isEmailVerified = false
    @Published var otpCode: String = ""
    @Published var isOtpSent = false
    @Published var isOtpVerified = false
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    private let functions = Functions.functions()
    
    private init() {
        setupAuthStateListener()
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
        do {
            print("📝 Creating new user account...")
            let result = try await auth.createUser(withEmail: email, password: password)
            print("✅ Firebase user created: \(result.user.uid)")
            
            // Create user profile in Firestore
            try await createUserProfile(userId: result.user.uid, email: email, username: username)
            print("✅ User profile created in Firestore")
            
            print("🎉 Sign-up completed successfully - user is now signed in!")
            
        } catch {
            print("❌ Sign-up failed: \(error.localizedDescription)")
            DispatchQueue.main.async {
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
            
            // Success - user credentials are valid
            print("🎉 Sign-in successful!")
            
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
            print("🧪 DEV MODE: OTP for \(email) is: \(otp)")
            print("🧪 DEV MODE: You can also use '123456' as bypass code")
            
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
            
            // Development bypass: allow "123456" as a universal OTP for testing
            let isDevBypass = (otp == "123456")
            
            if !isDevBypass {
                print("🔍 Fetching stored OTP from Firestore...")
                let document = try await db.collection("otp_codes").document(email).getDocument()
                
                guard document.exists else {
                    print("❌ No OTP found for email: \(email)")
                    throw NSError(domain: "FirebaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "No verification code found. Please request a new one.".localized])
                }
                
                guard let data = document.data(),
                      let storedOtp = data["otp"] as? String,
                      let expiresAt = data["expiresAt"] as? Timestamp else {
                    print("❌ Invalid OTP data structure")
                    throw NSError(domain: "FirebaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid verification code. Please request a new one.".localized])
                }
                
                print("✅ Found stored OTP data")
                print("🔍 Stored OTP: \(storedOtp)")
                print("🔍 Expires at: \(expiresAt.dateValue())")
                print("🔍 Current time: \(Date())")
                
                // Check if OTP is expired
                if Date() > expiresAt.dateValue() {
                    print("❌ OTP has expired")
                    throw NSError(domain: "FirebaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Verification code has expired. Please request a new one.".localized])
                }
                
                // Verify OTP
                if otp != storedOtp {
                    print("❌ OTP mismatch: entered '\(otp)' vs stored '\(storedOtp)'")
                    throw NSError(domain: "FirebaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid verification code. Please try again.".localized])
                }
                
                print("✅ OTP verified successfully")
                
                // Delete OTP from database after successful verification
                try await db.collection("otp_codes").document(email).delete()
                print("🗑️ OTP deleted from database")
            } else {
                print("🔧 Using development bypass OTP (123456)")
            }
            
            // Mark email as verified in our custom system
            print("🔍 Finding user by email: \(email)")
            let userSnapshot = try await db.collection("users")
                .whereField("email", isEqualTo: email)
                .getDocuments()
            
            guard let userDocument = userSnapshot.documents.first else {
                print("❌ No user found with email: \(email)")
                throw NSError(domain: "FirebaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "User account not found. Please try signing up again.".localized])
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
    
    // MARK: - User Profile Methods
    
    private func createUserProfile(userId: String, email: String, username: String) async throws {
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
    
    // MARK: - User Data Methods
    
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
    
    func getUserPods(userId: String) async throws -> [IncubationPod] {
        do {
            let snapshot = try await db.collection("pods")
                .whereField("members", arrayContains: userId)
                .getDocuments()
            
            return snapshot.documents.compactMap { document in
                let data = document.data()
                return IncubationPod(
                    id: document.documentID,
                    ideaId: data["ideaId"] as? String ?? "",
                    name: data["name"] as? String ?? "",
                    description: data["description"] as? String ?? "",
                    creatorId: data["creatorId"] as? String ?? "",
                    isPublic: data["isPublic"] as? Bool ?? false,
                    createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                    updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date(),
                    members: [], // Will need to be populated separately
                    tasks: [], // Will need to be populated separately
                    status: .planning // Will need to be mapped from string
                )
            }
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
    
    // MARK: - Pod Management Methods
    
    func createPod(name: String, description: String, ideaId: String?, isPublic: Bool) async throws -> String {
        guard let currentUser = auth.currentUser else {
            throw NSError(domain: "FirebaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated".localized])
        }
        
        let podData: [String: Any] = [
            "name": name,
            "description": description,
            "ideaId": ideaId ?? "",
            "creatorId": currentUser.uid,
            "isPublic": isPublic,
            "status": "planning",
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp(),
            "members": [currentUser.uid],
            "tasks": []
        ]
        
        let docRef = try await db.collection("pods").addDocument(data: podData)
        return docRef.documentID
    }
    
    func createPodFromIdea(name: String, description: String, ideaId: String, isPublic: Bool) async throws -> String {
        guard let currentUser = auth.currentUser else {
            throw NSError(domain: "FirebaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated".localized])
        }
        
        let podData: [String: Any] = [
            "name": name,
            "description": description,
            "ideaId": ideaId,
            "creatorId": currentUser.uid,
            "isPublic": isPublic,
            "status": "planning",
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp(),
            "members": [currentUser.uid],
            "tasks": []
        ]
        
        let docRef = try await db.collection("pods").addDocument(data: podData)
        return docRef.documentID
    }
    
    func updatePod(podId: String, data: [String: Any]) async throws {
        do {
            var updateData = data
            updateData["updatedAt"] = Timestamp(date: Date())
            try await db.collection("pods").document(podId).updateData(updateData)
        } catch {
            throw error
        }
    }
    
    func deletePod(podId: String) async throws {
        do {
            try await db.collection("pods").document(podId).delete()
        } catch {
            throw error
        }
    }
    
    // MARK: - Task Management Methods
    
    func createTask(podId: String, title: String, description: String?, assignedTo: String?, assignedToUsername: String?, dueDate: Date?, priority: String) async throws -> String {
        guard let currentUser = auth.currentUser else {
            throw NSError(domain: "FirebaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated".localized])
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
        
        let docRef = try await db.collection("pods").document(podId).collection("tasks").addDocument(data: taskData)
        return docRef.documentID
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
            "status": "planning",
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
            "status": "planning",
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
    
    func getPodAnalytics(podId: String) async throws -> [String: Any] {
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
    
    func inviteUserToPod(podId: String, userId: String, role: String, message: String) async throws {
        guard let currentUser = auth.currentUser else {
            throw NSError(domain: "FirebaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated".localized])
        }
        
        do {
            let invitationData: [String: Any] = [
                "podId": podId,
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
    
    func getPublicPods() async throws -> [IncubationPod] {
        do {
            let snapshot = try await db.collection("pods")
                .whereField("isPublic", isEqualTo: true)
                .order(by: "createdAt", descending: true)
                .limit(to: 50)
                .getDocuments()
            
            return snapshot.documents.compactMap { document in
                let data = document.data()
                return IncubationPod(
                    id: document.documentID,
                    ideaId: data["ideaId"] as? String ?? "",
                    name: data["name"] as? String ?? "",
                    description: data["description"] as? String ?? "",
                    creatorId: data["creatorId"] as? String ?? "",
                    isPublic: data["isPublic"] as? Bool ?? false,
                    createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                    updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date(),
                    members: [], // Will need to be populated separately
                    tasks: [], // Will need to be populated separately
                    status: .planning // Will need to be mapped from string
                )
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
    
    // MARK: - User Profile Management Methods
    
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
    
    func updateUserProfile(userId: String, data: [String: Any]) async throws {
        do {
            var updateData = data
            updateData["updatedAt"] = Timestamp(date: Date())
            try await db.collection("users").document(userId).updateData(updateData)
        } catch {
            throw error
        }
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
    
    // MARK: - Debug Methods
    
    func testAuthenticationFlow() async {
        print("\n🧪 ===== TESTING AUTHENTICATION FLOW =====")
        print("📱 Project: synapse-4578e")
        print("🔐 Current Firebase Auth user: \(auth.currentUser?.uid ?? "None")")
        print("📧 Current local isEmailVerified: \(isEmailVerified)")
        print("📤 Current isOtpSent: \(isOtpSent)")
        print("✅ Current isOtpVerified: \(isOtpVerified)")
        
        // Test database connectivity
        do {
            let testDoc = try await db.collection("test").document("connectivity").getDocument()
            print("✅ Firestore connectivity: OK")
        } catch {
            print("❌ Firestore connectivity: FAILED - \(error)")
        }
        
        // Test functions connectivity
        do {
            let result = try await functions.httpsCallable("test").call()
            print("✅ Cloud Functions connectivity: OK")
        } catch {
            print("⚠️ Cloud Functions connectivity: Not available (expected)")
        }
        
        print("🏁 ===== AUTHENTICATION FLOW TEST COMPLETE =====\n")
    }
    
    func debugUserState(email: String) async {
        print("\n🔍 ===== DEBUGGING USER STATE FOR: \(email) =====")
        
        // Check if user exists in Firebase Auth
        print("🔍 Checking Firebase Auth...")
        if let currentUser = auth.currentUser {
            print("✅ Firebase Auth user: \(currentUser.uid)")
            print("📧 Email: \(currentUser.email ?? "N/A")")
            print("🔍 Firebase isEmailVerified: \(currentUser.isEmailVerified)")
        } else {
            print("❌ No Firebase Auth user signed in")
        }
        
        // Check if user exists in Firestore
        do {
            print("🔍 Checking Firestore user document...")
            let userSnapshot = try await db.collection("users")
                .whereField("email", isEqualTo: email)
                .getDocuments()
            
            if let userDoc = userSnapshot.documents.first {
                print("✅ Firestore user found: \(userDoc.documentID)")
                let data = userDoc.data()
                print("📧 Email: \(data["email"] ?? "N/A")")
                print("👤 Username: \(data["username"] ?? "N/A")")
                print("🔍 isEmailVerified: \(data["isEmailVerified"] ?? "N/A")")
                print("🔑 authProvider: \(data["authProvider"] ?? "N/A")")
                print("📅 createdAt: \(data["createdAt"] ?? "N/A")")
            } else {
                print("❌ No Firestore user found with email: \(email)")
            }
        } catch {
            print("❌ Error checking Firestore: \(error)")
        }
        
        // Check for existing OTP
        do {
            print("🔍 Checking for existing OTP...")
            let otpDoc = try await db.collection("otp_codes").document(email).getDocument()
            if otpDoc.exists, let data = otpDoc.data() {
                print("✅ OTP found for email")
                print("🔢 OTP: \(data["otp"] ?? "N/A")")
                print("📅 Created: \(data["createdAt"] ?? "N/A")")
                print("⏰ Expires: \(data["expiresAt"] ?? "N/A")")
                
                if let expiresAt = data["expiresAt"] as? Timestamp {
                    let isExpired = Date() > expiresAt.dateValue()
                    print("⏰ Is Expired: \(isExpired)")
                }
            } else {
                print("❌ No OTP found for email")
            }
        } catch {
            print("❌ Error checking OTP: \(error)")
        }
        
        print("🏁 ===== USER STATE DEBUG COMPLETE =====\n")
    }
    
    // MARK: - Email Verification Check
    
    func checkEmailVerificationStatus() async {
        guard let currentUser = auth.currentUser else {
            DispatchQueue.main.async {
                self.isEmailVerified = false
            }
            return
        }
        
        do {
            let userDoc = try await db.collection("users").document(currentUser.uid).getDocument()
            
            if let userData = userDoc.data() {
                let authProvider = userData["authProvider"] as? String ?? "email"
                
                if authProvider == "google" {
                    // Google users are automatically verified
                    DispatchQueue.main.async {
                        self.isEmailVerified = true
                    }
                } else {
                    // Check email verification status for email users
                    let isEmailVerified: Bool
                    if let boolValue = userData["isEmailVerified"] as? Bool {
                        isEmailVerified = boolValue
                    } else if let intValue = userData["isEmailVerified"] as? Int {
                        isEmailVerified = intValue == 1
                    } else {
                        isEmailVerified = false
                    }
                    
                    DispatchQueue.main.async {
                        self.isEmailVerified = isEmailVerified
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.isEmailVerified = false
                }
            }
        } catch {
            print("Error checking email verification status: \(error)")
            DispatchQueue.main.async {
                self.isEmailVerified = false
            }
        }
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
            try await createUserProfile(userId: result.user.uid, email: testEmail, username: testUsername)
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