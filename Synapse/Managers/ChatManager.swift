//
//  ChatManager.swift
//  Synapse
//
//  Created by Abdulrahman Alshehri on 18/01/1447 AH.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

class ChatManager: ObservableObject {
    static let shared = ChatManager()
    
    @Published var messages: [ChatMessage] = []
    @Published var typingUsers: [TypingIndicator] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private var db: Firestore
    private var messagesListener: ListenerRegistration?
    private var typingListener: ListenerRegistration?
    private var cancellables = Set<AnyCancellable>()
    private var currentPodId: String?
    
    private init() {
        self.db = Firestore.firestore()
    }
    
    // MARK: - Chat Room Management
    func joinChatRoom(podId: String) {
        guard let userId = Auth.auth().currentUser?.uid else { 
            print("❌ ChatManager: No authenticated user")
            return 
        }
        
        print("🔄 ChatManager: Joining chat room for pod: \(podId)")
        
        // Clear previous messages if switching pods
        if currentPodId != podId {
            DispatchQueue.main.async {
                self.messages = []
                self.typingUsers = []
            }
        }
        
        currentPodId = podId
        observeMessages(podId: podId)
        observeTyping(podId: podId)
        setUserOnline(userId: userId, podId: podId)
    }
    
    func leaveChatRoom(podId: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        print("👋 ChatManager: Leaving chat room for pod: \(podId)")
        
        messagesListener?.remove()
        typingListener?.remove()
        setUserOffline(userId: userId, podId: podId)
        
        messagesListener = nil
        typingListener = nil
        currentPodId = nil
        
        DispatchQueue.main.async {
            self.messages = []
            self.typingUsers = []
        }
    }
    
    // MARK: - Message Operations
    func sendMessage(_ content: String, type: ChatMessage.MessageType = .text, replyTo: String? = nil, podId: String) {
        guard let userId = Auth.auth().currentUser?.uid else { 
            print("❌ ChatManager: Cannot send message - no authenticated user")
            return 
        }
        
        let messageId = UUID().uuidString
        let timestamp = Timestamp(date: Date())
        
        // Create message data directly as dictionary to avoid encoding issues
        let messageData: [String: Any] = [
            "id": messageId,
            "podId": podId,
            "senderId": userId,
            "senderName": Auth.auth().currentUser?.displayName ?? "Unknown User",
            "senderAvatar": Auth.auth().currentUser?.photoURL?.absoluteString ?? "",
            "content": content,
            "messageType": type.rawValue,
            "timestamp": timestamp,
            "isEdited": false,
            "replyTo": replyTo ?? ""
        ]
        
        print("📤 ChatManager: Sending message to pod \(podId): \(content)")
        
        db.collection("chats").document(podId).collection("messages").document(messageId).setData(messageData) { [weak self] error in
            if let error = error {
                print("❌ ChatManager: Failed to send message: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.error = "Failed to send message: \(error.localizedDescription)"
                }
            } else {
                print("✅ ChatManager: Message sent successfully")
            }
        }
    }
    
    func deleteMessage(_ messageId: String, podId: String) {
        print("🗑️ ChatManager: Deleting message \(messageId) from pod \(podId)")
        
        db.collection("chats").document(podId).collection("messages").document(messageId).delete { [weak self] error in
            if let error = error {
                print("❌ ChatManager: Failed to delete message: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.error = "Failed to delete message: \(error.localizedDescription)"
                }
            } else {
                print("✅ ChatManager: Message deleted successfully")
            }
        }
    }
    
    func editMessage(_ messageId: String, newContent: String, podId: String) {
        let updates: [String: Any] = [
            "content": newContent,
            "isEdited": true,
            "timestamp": Timestamp(date: Date())
        ]
        
        print("✏️ ChatManager: Editing message \(messageId) in pod \(podId)")
        
        db.collection("chats").document(podId).collection("messages").document(messageId).updateData(updates) { [weak self] error in
            if let error = error {
                print("❌ ChatManager: Failed to edit message: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.error = "Failed to edit message: \(error.localizedDescription)"
                }
            } else {
                print("✅ ChatManager: Message edited successfully")
            }
        }
    }
    
    // MARK: - Typing Indicators
    func startTyping(podId: String) {
        guard let userId = Auth.auth().currentUser?.uid,
              let userName = Auth.auth().currentUser?.displayName else { return }
        
        let typingData: [String: Any] = [
            "userId": userId,
            "userName": userName,
            "timestamp": Timestamp(date: Date())
        ]
        
        db.collection("chats").document(podId).collection("typing").document(userId).setData(typingData) { error in
            if let error = error {
                print("❌ ChatManager: Failed to set typing indicator: \(error.localizedDescription)")
            }
        }
    }
    
    func stopTyping(podId: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("chats").document(podId).collection("typing").document(userId).delete { error in
            if let error = error {
                print("❌ ChatManager: Failed to remove typing indicator: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Real-time Observers
    private func observeMessages(podId: String) {
        print("👀 ChatManager: Setting up message listener for pod: \(podId)")
        
        messagesListener = db.collection("chats").document(podId).collection("messages")
            .order(by: "timestamp", descending: false)
            .limit(to: 100)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ ChatManager: Message listener error: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self.error = "Failed to load messages: \(error.localizedDescription)"
                    }
                    return
                }
                
                guard let documents = snapshot?.documents else { 
                    print("⚠️ ChatManager: No documents in snapshot")
                    return 
                }
                
                print("📥 ChatManager: Received \(documents.count) message documents")
                
                var newMessages: [ChatMessage] = []
                
                for document in documents {
                    do {
                        let data = document.data()
                        
                        // Handle timestamp conversion properly
                        var processedData = data
                        if let timestamp = data["timestamp"] as? Timestamp {
                            processedData["timestamp"] = timestamp.dateValue()
                        }
                        
                        // Create ChatMessage manually to avoid encoding issues
                        if let id = processedData["id"] as? String,
                           let podId = processedData["podId"] as? String,
                           let senderId = processedData["senderId"] as? String,
                           let senderName = processedData["senderName"] as? String,
                           let content = processedData["content"] as? String,
                           let messageTypeRaw = processedData["messageType"] as? String,
                           let messageType = ChatMessage.MessageType(rawValue: messageTypeRaw),
                           let timestamp = processedData["timestamp"] as? Date,
                           let isEdited = processedData["isEdited"] as? Bool {
                            
                            let message = ChatMessage(
                                id: id,
                                podId: podId,
                                senderId: senderId,
                                senderName: senderName,
                                senderAvatar: processedData["senderAvatar"] as? String,
                                content: content,
                                messageType: messageType,
                                timestamp: timestamp,
                                isEdited: isEdited,
                                replyTo: (processedData["replyTo"] as? String)?.isEmpty == false ? processedData["replyTo"] as? String : nil
                            )
                            newMessages.append(message)
                        } else {
                            print("⚠️ ChatManager: Failed to parse message data for document: \(document.documentID)")
                            print("Data: \(data)")
                        }
                    } catch {
                        print("❌ ChatManager: Error processing message document \(document.documentID): \(error)")
                    }
                }
                
                print("✅ ChatManager: Successfully parsed \(newMessages.count) messages")
                
                DispatchQueue.main.async {
                    self.messages = newMessages.sorted { $0.timestamp < $1.timestamp }
                    print("📱 ChatManager: Updated UI with \(self.messages.count) messages")
                }
            }
    }
    
    private func observeTyping(podId: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        typingListener = db.collection("chats").document(podId).collection("typing")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ ChatManager: Typing listener error: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self.error = "Failed to load typing indicators: \(error.localizedDescription)"
                    }
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                var typingUsers: [TypingIndicator] = []
                
                for document in documents {
                    do {
                        let data = document.data()
                        
                        if let userId = data["userId"] as? String,
                           let userName = data["userName"] as? String,
                           userId != currentUserId { // Don't show current user's typing
                            
                            var timestamp = Date()
                            if let firestoreTimestamp = data["timestamp"] as? Timestamp {
                                timestamp = firestoreTimestamp.dateValue()
                            }
                            
                            // Only show typing indicators from the last 10 seconds
                            if Date().timeIntervalSince(timestamp) < 10 {
                                let typingIndicator = TypingIndicator(
                                    userId: userId,
                                    userName: userName,
                                    timestamp: timestamp
                                )
                                typingUsers.append(typingIndicator)
                            }
                        }
                    } catch {
                        print("❌ ChatManager: Error decoding typing indicator: \(error)")
                    }
                }
                
                DispatchQueue.main.async {
                    self.typingUsers = typingUsers
                }
            }
    }
    
    // MARK: - Online Status
    private func setUserOnline(userId: String, podId: String) {
        let onlineData: [String: Any] = [
            "timestamp": Timestamp(date: Date()),
            "status": "online"
        ]
        
        db.collection("pods").document(podId).collection("onlineUsers").document(userId).setData(onlineData) { error in
            if let error = error {
                print("❌ ChatManager: Failed to set user online: \(error.localizedDescription)")
            }
        }
    }
    
    private func setUserOffline(userId: String, podId: String) {
        db.collection("pods").document(podId).collection("onlineUsers").document(userId).delete { error in
            if let error = error {
                print("❌ ChatManager: Failed to set user offline: \(error.localizedDescription)")
            }
        }
    }
} 

