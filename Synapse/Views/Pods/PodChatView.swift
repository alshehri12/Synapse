//
//  PodChatView.swift
//  Synapse
//
//  Created by Abdulrahman Alshehri on 18/01/1447 AH.
//

import SwiftUI
import Combine
import FirebaseAuth

struct PodChatView: View {
    let pod: IncubationPod
    @StateObject private var chatManager = ChatManager.shared
    @State private var messageText = ""
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var showingReplyTo: ChatMessage?
    @State private var showingMessageOptions: ChatMessage?
    @State private var showingEditMessage: ChatMessage?
    @State private var editingMessageText = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            chatHeader
            
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(chatManager.messages) { message in
                            MessageBubble(
                                message: message,
                                isFromCurrentUser: message.senderId == Auth.auth().currentUser?.uid,
                                onReply: { showingReplyTo = message },
                                onLongPress: { showingMessageOptions = message }
                            )
                            .id(message.id)
                        }
                        
                        // Typing indicators
                        if !chatManager.typingUsers.isEmpty {
                            TypingIndicatorView(users: chatManager.typingUsers)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .onChange(of: chatManager.messages.count) { _ in
                    if let lastMessage = chatManager.messages.last {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Reply preview
            if let replyTo = showingReplyTo {
                ReplyPreviewView(message: replyTo) {
                    showingReplyTo = nil
                }
            }
            
            // Input area
            messageInputArea
        }
        .navigationBarHidden(true)
        .onAppear {
            chatManager.joinChatRoom(podId: pod.id)
        }
        .onDisappear {
            chatManager.leaveChatRoom(podId: pod.id)
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
        }
        .sheet(item: $showingEditMessage) { message in
            EditMessageView(
                message: message,
                editedText: $editingMessageText,
                onSave: {
                    if !editingMessageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        chatManager.editMessage(message.id, newContent: editingMessageText, podId: pod.id)
                    }
                    showingEditMessage = nil
                    editingMessageText = ""
                },
                onCancel: {
                    showingEditMessage = nil
                    editingMessageText = ""
                }
            )
        }
        .actionSheet(item: $showingMessageOptions) { message in
            ActionSheet(
                title: Text("Message Options"),
                buttons: [
                    .default(Text("Reply")) {
                        showingReplyTo = message
                    },
                    .default(Text("Edit")) {
                        showingEditMessage = message
                        editingMessageText = message.content
                    },
                    .destructive(Text("Delete")) {
                        chatManager.deleteMessage(message.id, podId: pod.id)
                    },
                    .cancel()
                ]
            )
        }
    }
    
    // MARK: - Header
    private var chatHeader: some View {
        HStack {
            Button(action: {
                // Navigate back
            }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(Color.textPrimary)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(pod.name)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color.textPrimary)
                
                Text("\(pod.members.count) members")
                    .font(.system(size: 14))
                    .foregroundColor(Color.textSecondary)
            }
            
            Spacer()
            
            Button(action: {
                // Show pod info
            }) {
                Image(systemName: "info.circle")
                    .font(.title2)
                    .foregroundColor(Color.textPrimary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.backgroundPrimary)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.border),
            alignment: .bottom
        )
    }
    
    // MARK: - Message Input
    private var messageInputArea: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Attachment button
                Button(action: {
                    showingImagePicker = true
                }) {
                    Image(systemName: "paperclip")
                        .font(.title2)
                        .foregroundColor(Color.textSecondary)
                }
                
                // Text field
                TextField("Type a message...", text: $messageText, axis: .vertical)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.backgroundSecondary)
                    .cornerRadius(20)
                    .focused($isTextFieldFocused)
                    .onChange(of: messageText) { _ in
                        if !messageText.isEmpty {
                            chatManager.startTyping(podId: pod.id)
                        } else {
                            chatManager.stopTyping(podId: pod.id)
                        }
                    }
                
                // Send button
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(messageText.isEmpty ? Color.textSecondary : Color.accentGreen)
                }
                .disabled(messageText.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.backgroundPrimary)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.border),
                alignment: .top
            )
        }
    }
    
    // MARK: - Actions
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        chatManager.sendMessage(
            messageText,
            replyTo: showingReplyTo?.id,
            podId: pod.id
        )
        
        messageText = ""
        showingReplyTo = nil
        chatManager.stopTyping(podId: pod.id)
    }
}

// MARK: - Message Bubble
struct MessageBubble: View {
    let message: ChatMessage
    let isFromCurrentUser: Bool
    let onReply: () -> Void
    let onLongPress: () -> Void
    
    var body: some View {
        HStack {
            if isFromCurrentUser {
                Spacer(minLength: 60)
            }
            
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                // Reply preview
                if let replyTo = message.replyTo {
                    ReplyPreviewView(message: message) {
                        // Handle reply tap
                    }
                    .frame(maxWidth: 250)
                }
                
                // Message content
                VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 2) {
                    if !isFromCurrentUser {
                        Text(message.senderName)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.textSecondary)
                    }
                    
                    Text(message.content)
                        .font(.system(size: 16))
                        .foregroundColor(isFromCurrentUser ? .white : Color.textPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            isFromCurrentUser ? Color.accentGreen : Color.backgroundSecondary
                        )
                        .cornerRadius(16)
                    
                    HStack(spacing: 4) {
                        Text(message.timestamp, style: .time)
                            .font(.system(size: 11))
                            .foregroundColor(Color.textSecondary)
                        
                        if message.isEdited {
                            Text("edited")
                                .font(.system(size: 11))
                                .foregroundColor(Color.textSecondary)
                        }
                    }
                }
            }
            
            if !isFromCurrentUser {
                Spacer(minLength: 60)
            }
        }
        .onLongPressGesture {
            onLongPress()
        }
    }
}

// MARK: - Typing Indicator
struct TypingIndicatorView: View {
    let users: [TypingIndicator]
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(typingText)
                    .font(.system(size: 12))
                    .foregroundColor(Color.textSecondary)
                
                HStack(spacing: 4) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(Color.textSecondary)
                            .frame(width: 6, height: 6)
                            .scaleEffect(1.0)
                            .animation(
                                Animation.easeInOut(duration: 0.6)
                                    .repeatForever()
                                    .delay(Double(index) * 0.2),
                                value: UUID()
                            )
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.backgroundSecondary)
            .cornerRadius(16)
            
            Spacer()
        }
    }
    
    private var typingText: String {
        if users.count == 1 {
            return "\(users.first?.userName ?? "") is typing..."
        } else if users.count == 2 {
            return "\(users[0].userName) and \(users[1].userName) are typing..."
        } else {
            return "\(users.count) people are typing..."
        }
    }
}

// MARK: - Reply Preview
struct ReplyPreviewView: View {
    let message: ChatMessage
    let onDismiss: () -> Void
    
    var body: some View {
        HStack {
            Rectangle()
                .fill(Color.accentGreen)
                .frame(width: 3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(message.senderName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.accentGreen)
                
                Text(message.content)
                    .font(.system(size: 14))
                    .foregroundColor(Color.textSecondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(Color.textSecondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.backgroundSecondary)
        .cornerRadius(8)
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Edit Message View
struct EditMessageView: View {
    let message: ChatMessage
    @Binding var editedText: String
    let onSave: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Original message preview
                VStack(alignment: .leading, spacing: 8) {
                    Text("Original Message")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.textSecondary)
                    
                    Text(message.content)
                        .font(.system(size: 16))
                        .foregroundColor(Color.textSecondary)
                        .padding(12)
                        .background(Color.backgroundSecondary)
                        .cornerRadius(8)
                }
                .padding(.horizontal, 20)
                
                // Edit text field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Edit Message")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.textPrimary)
                    
                    TextEditor(text: $editedText)
                        .frame(minHeight: 100)
                        .padding(12)
                        .background(Color.backgroundSecondary)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.textSecondary.opacity(0.2), lineWidth: 1)
                        )
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .padding(.top, 20)
            .navigationTitle("Edit Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave()
                    }
                    .disabled(editedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

#Preview {
    PodChatView(pod: mockPods[0])
        .environmentObject(LocalizationManager.shared)
        .environmentObject(FirebaseManager.shared)
} 
