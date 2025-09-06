//
//  PodChatView.swift
//  Synapse
//
//  Created by Abdulrahman Alshehri on 18/01/1447 AH.
//

import SwiftUI
import Combine
import Supabase
import UIKit

struct PodChatView: View {
    let pod: IncubationProject
    @StateObject private var supabaseManager = SupabaseManager.shared
    @State private var messageText = ""
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var showingMessageOptions: ChatMessage?
    @State private var keyboardHeight: CGFloat = 0
    @FocusState private var isTextFieldFocused: Bool
    
    // Placeholder for chat functionality - to be integrated with SupabaseManager
    @State private var chatMessages: [ChatMessage] = []
    @State private var typingUsers: [TypingIndicator] = []
    
    // MARK: - Main Body
    var body: some View {
        GeometryReader { geometry in
            mainChatContent(geometry: geometry)
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
        }
        .actionSheet(item: $showingMessageOptions) { message in
            messageOptionsSheet(for: message)
        }
    }
    
    // MARK: - Main Content View
    private func mainChatContent(geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            chatHeader
            messagesScrollView(geometry: geometry)
            Spacer(minLength: 0)
            messageInputArea
        }
        .navigationBarHidden(true)
        .onAppear {
            setupKeyboardObservers()
            loadChatMessages()
        }
        .onDisappear {
            removeKeyboardObservers()
        }
    }
    
    // MARK: - Messages Scroll View
    private func messagesScrollView(geometry: GeometryProxy) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                messagesContent
            }
            .background(Color.backgroundSecondary.opacity(0.3))
            .frame(height: calculateChatHeight(screenHeight: geometry.size.height))
            .onChange(of: chatMessages.count) {
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: keyboardHeight) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    scrollToBottom(proxy: proxy)
                }
            }
        }
    }
    
    // MARK: - Messages Content
    private var messagesContent: some View {
        LazyVStack(spacing: 12) {
            if chatMessages.isEmpty {
                emptyStateView
            }
            
            ForEach(chatMessages) { message in
                MessageBubble(
                    message: message,
                    isFromCurrentUser: message.senderId == supabaseManager.currentUser?.uid,
                    onLongPress: { showingMessageOptions = message }
                )
                .id(message.id)
            }
            
            if !typingUsers.isEmpty {
                TypingIndicatorView(users: typingUsers)
                    .padding(.top, 4)
            }
            
            if keyboardHeight > 0 {
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 16)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 40))
                .foregroundColor(Color.textSecondary.opacity(0.6))
            
            Text("Start the conversation!")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color.textSecondary)
            
            Text("Send a message to get things started")
                .font(.system(size: 14))
                .foregroundColor(Color.textSecondary.opacity(0.8))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(minHeight: 200)
    }
    
    // MARK: - Message Options Sheet
    private func messageOptionsSheet(for message: ChatMessage) -> ActionSheet {
        ActionSheet(
            title: Text("Message Options"),
            buttons: [
                .destructive(Text("Delete")) {
                    // TODO: Implement message deletion
                },
                .cancel()
            ]
        )
    }
    
    // MARK: - Header
    private var chatHeader: some View {
        HStack(spacing: 16) {
            // Back button with better styling
            Button(action: {
                // Navigate back
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color.accentGreen)
                    .frame(width: 32, height: 32)
                    .background(Color.accentGreen.opacity(0.1))
                    .cornerRadius(16)
            }
            
            // Pod info with enhanced design
            HStack(spacing: 12) {
                // Pod avatar/icon
                Circle()
                    .fill(Color.accentGreen.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color.accentGreen)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(pod.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color.textPrimary)
                        .lineLimit(1)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color.accentGreen)
                        
                        Text("\(pod.members.count) members")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color.textSecondary)
                        
                        // Online indicator (example)
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                    }
                }
            }
            
            Spacer()
            
            // Info button with better styling
            Button(action: {
                // Show pod info
            }) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color.accentGreen)
                    .frame(width: 32, height: 32)
                    .background(Color.accentGreen.opacity(0.1))
                    .cornerRadius(16)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            Color.backgroundPrimary
                .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
        )
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color.border.opacity(0.3)),
            alignment: .bottom
        )
    }
    
    // MARK: - Message Input
    private var messageInputArea: some View {
        VStack(spacing: 0) {
            // Input container with enhanced styling
            HStack(spacing: 16) {
                // Attachment button with better styling
                Button(action: {
                    showingImagePicker = true
                }) {
                    Image(systemName: "paperclip")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Color.accentGreen)
                        .frame(width: 36, height: 36)
                        .background(Color.accentGreen.opacity(0.1))
                        .cornerRadius(18)
                }
                
                // Enhanced text field with better visual design
                HStack {
                    TextField("Type a message...", text: $messageText, axis: .vertical)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 16))
                        .foregroundColor(Color.textPrimary)
                        .focused($isTextFieldFocused)
                        .lineLimit(1...4)
                        .onChange(of: messageText) {
                            if !messageText.isEmpty {
                                // TODO: Implement typing indicators
                            } else {
                                // TODO: Implement typing indicators
                            }
                        }
                    
                    // Character indicator (subtle)
                    if messageText.count > 100 {
                        Text("\(messageText.count)")
                            .font(.system(size: 12))
                            .foregroundColor(Color.textSecondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.backgroundPrimary)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(isTextFieldFocused ? Color.accentGreen.opacity(0.5) : Color.border, lineWidth: 1.5)
                )
                .cornerRadius(24)
                
                // Enhanced send button
                Button(action: sendMessage) {
                    Image(systemName: messageText.isEmpty ? "arrow.up.circle" : "arrow.up.circle.fill")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(messageText.isEmpty ? Color.textSecondary : Color.accentGreen)
                        .scaleEffect(messageText.isEmpty ? 0.9 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: messageText.isEmpty)
                }
                .disabled(messageText.isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                Color.backgroundPrimary
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: -2)
            )
            .overlay(
                Rectangle()
                    .frame(height: 0.5)
                    .foregroundColor(Color.border.opacity(0.3)),
                alignment: .top
            )
        }
        .background(Color.backgroundPrimary)
    }
    
    // MARK: - Actions
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let currentUser = supabaseManager.currentUser else { return }
        
        let trimmedMessage = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        Task {
            do {
                _ = try await supabaseManager.sendChatMessage(
                    podId: pod.id,
                    content: trimmedMessage,
                    senderId: currentUser.uid,
                    senderUsername: currentUser.displayName ?? "Unknown"
                )
                
                await MainActor.run {
                    messageText = ""
                    loadChatMessages() // Refresh messages
                }
                print("✅ Message sent successfully")
            } catch {
                print("❌ Error sending message: \(error.localizedDescription)")
            }
        }
    }
    
    private func loadChatMessages() {
        Task {
            do {
                let messages = try await supabaseManager.getChatMessages(podId: pod.id)
                await MainActor.run {
                    self.chatMessages = messages
                }
            } catch {
                print("❌ Error loading chat messages: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Keyboard Handling
    private func scrollToBottom(proxy: ScrollViewProxy) {
        if let lastMessage = chatMessages.last {
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
        HStack(spacing: 0) {
            if isFromCurrentUser {
                Spacer(minLength: 80)
            }
            
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 6) {
                // Sender name for received messages
                if !isFromCurrentUser {
                    HStack {
                        Circle()
                            .fill(Color.accentGreen.opacity(0.8))
                            .frame(width: 16, height: 16)
                            .overlay(
                                Text(String(message.senderName.prefix(1)).uppercased())
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                            )
                        
                        Text(message.senderName)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color.accentGreen)
                        
                        Spacer()
                    }
                }
                
                // Message content with enhanced styling
                VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                    Text(message.content)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(isFromCurrentUser ? .white : Color.textPrimary)
                        .multilineTextAlignment(isFromCurrentUser ? .trailing : .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            Group {
                                if isFromCurrentUser {
                                    LinearGradient(
                                        colors: [Color.accentGreen, Color.accentGreen.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                } else {
                                    Color.backgroundPrimary
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(Color.border.opacity(0.3), lineWidth: 1)
                                        )
                                }
                            }
                        )
                        .cornerRadius(20)
                        .shadow(
                            color: isFromCurrentUser ? Color.accentGreen.opacity(0.2) : Color.black.opacity(0.05),
                            radius: 4,
                            x: 0,
                            y: 2
                        )
                    
                    // Timestamp with better styling
                    Text(message.timestamp, style: .time)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.textSecondary.opacity(0.8))
                        .padding(isFromCurrentUser ? .trailing : .leading, 4)
                }
            }
            
            if !isFromCurrentUser {
                Spacer(minLength: 80)
            }
        }
        .padding(.vertical, 2)
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
            HStack(spacing: 8) {
                // Typing user avatar
                Circle()
                    .fill(Color.accentGreen.opacity(0.8))
                    .frame(width: 20, height: 20)
                    .overlay(
                        Image(systemName: "ellipsis")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(typingText)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.accentGreen)
                    
                    HStack(spacing: 3) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(Color.accentGreen.opacity(0.6))
                                .frame(width: 5, height: 5)
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
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.backgroundPrimary)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.accentGreen.opacity(0.2), lineWidth: 1)
            )
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            
            Spacer(minLength: 80)
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
        .environmentObject(SupabaseManager.shared)
} 
