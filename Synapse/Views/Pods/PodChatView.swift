//
//  PodChatView.swift
//  Synapse
//
//  Created by Abdulrahman Alshehri on 18/01/1447 AH.
//

import SwiftUI
import Combine
import FirebaseAuth
import UIKit

struct PodChatView: View {
    let pod: IncubationPod
    @StateObject private var chatManager = ChatManager.shared
    @State private var messageText = ""
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var showingMessageOptions: ChatMessage?
    @State private var keyboardHeight: CGFloat = 0
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Header
                chatHeader
                
                // Messages - Adjust height based on keyboard
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(chatManager.messages) { message in
                                MessageBubble(
                                    message: message,
                                    isFromCurrentUser: message.senderId == Auth.auth().currentUser?.uid,
                                    onLongPress: { showingMessageOptions = message }
                                )
                                .id(message.id)
                            }
                            
                            // Typing indicators
                            if !chatManager.typingUsers.isEmpty {
                                TypingIndicatorView(users: chatManager.typingUsers)
                            }
                            
                            // Extra bottom padding when keyboard is shown
                            if keyboardHeight > 0 {
                                Rectangle()
                                    .fill(Color.clear)
                                    .frame(height: 20)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                    .frame(height: calculateChatHeight(screenHeight: geometry.size.height))
                    .onChange(of: chatManager.messages.count) { _ in
                        scrollToBottom(proxy: proxy)
                    }
                    .onChange(of: keyboardHeight) { _ in
                        // Scroll to bottom when keyboard appears/disappears
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            scrollToBottom(proxy: proxy)
                        }
                    }
                }
                
                Spacer(minLength: 0)
                
                // Input area - Fixed at bottom
                messageInputArea
            }
            .navigationBarHidden(true)
            .onAppear {
                chatManager.joinChatRoom(podId: pod.id)
                setupKeyboardObservers()
            }
            .onDisappear {
                chatManager.leaveChatRoom(podId: pod.id)
                removeKeyboardObservers()
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
        }

        .actionSheet(item: $showingMessageOptions) { message in
            ActionSheet(
                title: Text("Message Options"),
                buttons: [
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
                    .lineLimit(1...4) // Limit text field expansion
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
        .background(Color.backgroundPrimary) // Ensure consistent background
    }
    
    // MARK: - Actions
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        chatManager.sendMessage(
            messageText,
            podId: pod.id
        )
        
        messageText = ""
        chatManager.stopTyping(podId: pod.id)
    }
    
    // MARK: - Keyboard Handling
    private func scrollToBottom(proxy: ScrollViewProxy) {
        if let lastMessage = chatManager.messages.last {
            withAnimation(.easeInOut(duration: 0.3)) {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
    
    private func calculateChatHeight(screenHeight: CGFloat) -> CGFloat {
        // Conservative calculation to prevent negative heights
        let headerHeight: CGFloat = 80  // Chat header
        let inputHeight: CGFloat = 80   // Input area with padding
        let safetyMargin: CGFloat = 40  // Extra safety margin
        
        let availableHeight = screenHeight - headerHeight - inputHeight - keyboardHeight - safetyMargin
        let minimumHeight: CGFloat = 100 // Minimum viable chat height
        
        return max(minimumHeight, availableHeight)
    }
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                print("🔧 Keyboard will show - Height: \(keyboardFrame.height)")
                withAnimation(.easeInOut(duration: 0.3)) {
                    keyboardHeight = keyboardFrame.height
                }
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { _ in
            print("🔧 Keyboard will hide")
            withAnimation(.easeInOut(duration: 0.3)) {
                keyboardHeight = 0
            }
        }
    }
    
    private func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
}

// MARK: - Message Bubble
struct MessageBubble: View {
    let message: ChatMessage
    let isFromCurrentUser: Bool
    let onLongPress: () -> Void
    
    var body: some View {
        HStack {
            if isFromCurrentUser {
                Spacer(minLength: 60)
            }
            
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
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
                    
                    Text(message.timestamp, style: .time)
                        .font(.system(size: 11))
                        .foregroundColor(Color.textSecondary)
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



#Preview {
    PodChatView(pod: mockPods[0])
        .environmentObject(LocalizationManager.shared)
        .environmentObject(FirebaseManager.shared)
} 
