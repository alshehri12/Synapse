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
    
    private init() {
        self.db = Firestore.firestore()
    }
    
    // MARK: - Chat Room Management
    func joinChatRoom(podId: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        observeMessages(podId: podId)
        observeTyping(podId: podId)
        setUserOnline(userId: userId, podId: podId)
    }
    
    func leaveChatRoom(podId: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        messagesListener?.remove()
        typingListener?.remove()
        setUserOffline(userId: userId, podId: podId)
        
        messagesListener = nil
        typingListener = nil
    }
    
    // MARK: - Message Operations
    func sendMessage(_ content: String, type: ChatMessage.MessageType = .text, replyTo: String? = nil, podId: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let messageId = UUID().uuidString
        let message = ChatMessage(
            id: messageId,
            podId: podId,
            senderId: userId,
            senderName: Auth.auth().currentUser?.displayName ?? "Unknown",
            senderAvatar: Auth.auth().currentUser?.photoURL?.absoluteString,
            content: content,
            messageType: type,
            timestamp: Date(),
            isEdited: false,
            replyTo: replyTo
        )
        
        do {
            let messageData = try JSONEncoder().encode(message)
            let messageDict = try JSONSerialization.jsonObject(with: messageData) as? [String: Any] ?? [:]
            
            db.collection("chats").document(podId).collection("messages").document(messageId).setData(messageDict) { [weak self] error in
                if let error = error {
                    DispatchQueue.main.async {
                        self?.error = error.localizedDescription
                    }
                }
            }
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func deleteMessage(_ messageId: String, podId: String) {
        db.collection("chats").document(podId).collection("messages").document(messageId).delete { [weak self] error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.error = error.localizedDescription
                }
            }
        }
    }
    
    func editMessage(_ messageId: String, newContent: String, podId: String) {
        let updates: [String: Any] = [
            "content": newContent,
            "isEdited": true,
            "timestamp": Timestamp(date: Date())
        ]
        
        db.collection("chats").document(podId).collection("messages").document(messageId).updateData(updates) { [weak self] error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.error = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Typing Indicators
    func startTyping(podId: String) {
        guard let userId = Auth.auth().currentUser?.uid,
              let userName = Auth.auth().currentUser?.displayName else { return }
        
        let typingIndicator = TypingIndicator(
            userId: userId,
            userName: userName,
            timestamp: Date()
        )
        
        do {
            let typingData = try JSONEncoder().encode(typingIndicator)
            let typingDict = try JSONSerialization.jsonObject(with: typingData) as? [String: Any] ?? [:]
            
            db.collection("chats").document(podId).collection("typing").document(userId).setData(typingDict)
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func stopTyping(podId: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("chats").document(podId).collection("typing").document(userId).delete()
    }
    
    // MARK: - Real-time Observers
    private func observeMessages(podId: String) {
        messagesListener = db.collection("chats").document(podId).collection("messages")
            .order(by: "timestamp", descending: false)
            .limit(to: 100)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    DispatchQueue.main.async {
                        self.error = error.localizedDescription
                    }
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                var newMessages: [ChatMessage] = []
                
                for document in documents {
                    do {
                        let messageData = document.data()
                        let messageJson = try JSONSerialization.data(withJSONObject: messageData)
                        let message = try JSONDecoder().decode(ChatMessage.self, from: messageJson)
                        newMessages.append(message)
                    } catch {
                        print("Error decoding message: \(error)")
                    }
                }
                
                DispatchQueue.main.async {
                    self.messages = newMessages.sorted { $0.timestamp < $1.timestamp }
                }
            }
    }
    
    private func observeTyping(podId: String) {
        typingListener = db.collection("chats").document(podId).collection("typing")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    DispatchQueue.main.async {
                        self.error = error.localizedDescription
                    }
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                var typingUsers: [TypingIndicator] = []
                
                for document in documents {
                    do {
                        let typingData = document.data()
                        let typingJson = try JSONSerialization.data(withJSONObject: typingData)
                        let typingIndicator = try JSONDecoder().decode(TypingIndicator.self, from: typingJson)
                        
                        // Only show typing indicators from the last 10 seconds
                        if Date().timeIntervalSince(typingIndicator.timestamp) < 10 {
                            typingUsers.append(typingIndicator)
                        }
                    } catch {
                        print("Error decoding typing indicator: \(error)")
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
        
        db.collection("pods").document(podId).collection("onlineUsers").document(userId).setData(onlineData)
    }
    
    private func setUserOffline(userId: String, podId: String) {
        db.collection("pods").document(podId).collection("onlineUsers").document(userId).delete()
    }
} 