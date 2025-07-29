//
//  IdeaDetailView.swift
//  Synapse
//
//  Created by Abdulrahman Alshehri on 18/01/1447 AH.
//

import SwiftUI
import FirebaseFirestore

struct IdeaDetailView: View {
    let idea: IdeaSpark
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var firebaseManager: FirebaseManager
    @EnvironmentObject private var localizationManager: LocalizationManager
    
    @State private var comments: [IdeaComment] = []
    @State private var newComment = ""
    @State private var isLiked = false
    @State private var isLoadingComments = false
    @State private var isSubmittingComment = false
    @State private var showingCreatePod = false
    @State private var showingJoinPod = false
    @State private var showingShareSheet = false
    @State private var showingDeleteAlert = false
    @State private var isDeleting = false
    @State private var existingPods: [IncubationPod] = []
    @State private var isLoadingPods = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Idea Header
                    VStack(alignment: .leading, spacing: 16) {
                        // Author Info
                        HStack {
                            Circle()
                                .fill(Color.accentGreen)
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Text(String(idea.authorUsername.prefix(1)).uppercased())
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.white)
                                )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(idea.authorUsername)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(Color.textPrimary)
                                
                                Text(idea.createdAt.timeAgoDisplay())
                                    .font(.system(size: 14))
                                    .foregroundColor(Color.textSecondary)
                            }
                            
                            Spacer()
                            
                            StatusBadge(status: idea.status)
                        }
                        
                        // Idea Content
                        VStack(alignment: .leading, spacing: 12) {
                            Text(idea.title)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(Color.textPrimary)
                            
                            Text(idea.description)
                                .font(.system(size: 16))
                                .foregroundColor(Color.textSecondary)
                                .lineSpacing(4)
                            
                            // Tags
                            if !idea.tags.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(idea.tags, id: \.self) { tag in
                                            Text("#\(tag)")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(Color.accentGreen)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(Color.accentGreen.opacity(0.1))
                                                .cornerRadius(12)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(20)
                    .background(Color.backgroundPrimary)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    
                    // Interaction Stats
                    HStack(spacing: 20) {
                        HStack(spacing: 6) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.red)
                            Text("\(idea.likes)")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color.textPrimary)
                        }
                        
                        HStack(spacing: 6) {
                            Image(systemName: "message.fill")
                                .font(.system(size: 16))
                                .foregroundColor(Color.accentGreen)
                            Text("\(idea.comments)")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color.textPrimary)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    
                    // Action Buttons
                    HStack(spacing: 12) {
                        Button(action: likeIdea) {
                            HStack(spacing: 6) {
                                Image(systemName: isLiked ? "heart.fill" : "heart")
                                    .font(.system(size: 16))
                                Text(isLiked ? "Liked".localized : "Like".localized)
                                    .font(.system(size: 14, weight: .medium))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                            .foregroundColor(isLiked ? .red : Color.textSecondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(isLiked ? Color.red.opacity(0.1) : Color.backgroundSecondary)
                            .cornerRadius(20)
                            .fixedSize(horizontal: true, vertical: false)
                        }
                        
                        Button(action: { showingShareSheet = true }) {
                            HStack(spacing: 6) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 16))
                                Text("Share".localized)
                                    .font(.system(size: 14, weight: .medium))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                            .foregroundColor(Color.textSecondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.backgroundSecondary)
                            .cornerRadius(20)
                            .fixedSize(horizontal: true, vertical: false)
                        }
                        
                        Spacer()
                        
                        // Show different buttons based on ownership and pod existence
                        if let currentUser = firebaseManager.currentUser {
                            if currentUser.uid == idea.authorId {
                                // User is the idea owner - can create pod
                                Button(action: { showingCreatePod = true }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "plus.circle")
                                            .font(.system(size: 16))
                                        Text("Create Pod".localized)
                                            .font(.system(size: 14, weight: .medium))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.8)
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.accentGreen)
                                    .cornerRadius(20)
                                    .fixedSize(horizontal: true, vertical: false)
                                }
                            } else {
                                // User is NOT the idea owner
                                if isLoadingPods {
                                    // Show loading state
                                    HStack(spacing: 6) {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                        Text("Loading...".localized)
                                            .font(.system(size: 14, weight: .medium))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.textSecondary.opacity(0.6))
                                    .cornerRadius(20)
                                } else if !existingPods.isEmpty {
                                    // Pods exist - can join
                                    Button(action: { showingJoinPod = true }) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "person.3")
                                                .font(.system(size: 16))
                                            Text("Join Pod".localized)
                                                .font(.system(size: 14, weight: .medium))
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.8)
                                        }
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Color.accentBlue)
                                        .cornerRadius(20)
                                        .fixedSize(horizontal: true, vertical: false)
                                    }
                                } else {
                                    // No pods exist - show disabled message
                                    HStack(spacing: 6) {
                                        Image(systemName: "person.3.slash")
                                            .font(.system(size: 16))
                                        Text("No Pods Yet".localized)
                                            .font(.system(size: 14, weight: .medium))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.8)
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.textSecondary.opacity(0.6))
                                    .cornerRadius(20)
                                    .fixedSize(horizontal: true, vertical: false)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Comments Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Comments".localized)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color.textPrimary)
                            
                            Spacer()
                            
                            if isLoadingComments {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                        
                        // Add Comment
                        HStack(spacing: 12) {
                            TextField("Add a comment...".localized, text: $newComment)
                                .textFieldStyle(CustomTextFieldStyle())
                            
                            Button(action: submitComment) {
                                if isSubmittingComment {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: Color.accentGreen))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "paperplane.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(Color.accentGreen)
                                }
                            }
                            .disabled(newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmittingComment)
                        }
                        
                        // Comments List
                        if comments.isEmpty && !isLoadingComments {
                            VStack(spacing: 12) {
                                Image(systemName: "message")
                                    .font(.system(size: 32))
                                    .foregroundColor(Color.textSecondary.opacity(0.5))
                                
                                Text("No comments yet".localized)
                                    .font(.system(size: 16))
                                    .foregroundColor(Color.textSecondary)
                                
                                Text("Be the first to share your thoughts!".localized)
                                    .font(.system(size: 14))
                                    .foregroundColor(Color.textSecondary.opacity(0.7))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(comments) { comment in
                                    CommentRow(comment: comment)
                                }
                            }
                        }
                    }
                    .padding(20)
                    .background(Color.backgroundPrimary)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(Color.backgroundSecondary)
            .navigationTitle("Idea Details".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close".localized) {
                        dismiss()
                    }
                }
                
                // Show delete button only if current user is the idea author
                if let currentUser = firebaseManager.currentUser,
                   currentUser.uid == idea.authorId {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showingDeleteAlert = true
                        }) {
                            if isDeleting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .red))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                        .disabled(isDeleting)
                    }
                }
            }
            .onAppear {
                loadComments()
                checkIfLiked()
                loadExistingPods()
            }
            .sheet(isPresented: $showingCreatePod) {
                CreatePodFromIdeaView(idea: idea)
            }
            .sheet(isPresented: $showingJoinPod) {
                JoinPodView(availablePods: existingPods)
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(items: [idea.title, idea.description])
            }
            .alert("Delete Idea".localized, isPresented: $showingDeleteAlert) {
                Button("Cancel".localized, role: .cancel) { }
                Button("Delete".localized, role: .destructive) {
                    deleteIdea()
                }
            } message: {
                Text("Are you sure you want to delete this idea? This action cannot be undone.".localized)
            }
        }
    }
    
    private func loadComments() {
        isLoadingComments = true
        
        Task {
            do {
                let commentData = try await firebaseManager.getIdeaComments(ideaId: idea.id)
                
                await MainActor.run {
                    comments = commentData.compactMap { data in
                        guard let id = data["id"] as? String,
                              let authorId = data["authorId"] as? String,
                              let authorUsername = data["authorUsername"] as? String,
                              let content = data["content"] as? String,
                              let createdAt = (data["timestamp"] as? Timestamp)?.dateValue() else {
                            print("⚠️ Failed to parse comment: \(data)")
                            return nil
                        }
                        
                        return IdeaComment(
                            id: id,
                            authorId: authorId,
                            authorUsername: authorUsername,
                            content: content,
                            createdAt: createdAt,
                            likes: 0  // Default value since likes aren't implemented for comments yet
                        )
                    }
                    isLoadingComments = false
                    print("✅ Loaded \(comments.count) comments successfully")
                }
            } catch {
                print("❌ Error loading comments: \(error.localizedDescription)")
                await MainActor.run {
                    isLoadingComments = false
                }
            }
        }
    }
    
    private func checkIfLiked() {
        guard let currentUser = firebaseManager.currentUser else { return }
        
        // This would need to be implemented to check if the current user has liked this idea
        // For now, we'll assume not liked
        isLiked = false
    }
    
    private func likeIdea() {
        guard let currentUser = firebaseManager.currentUser else { return }
        
        Task {
            do {
                try await firebaseManager.likeIdea(ideaId: idea.id, userId: currentUser.uid)
                await MainActor.run {
                    isLiked.toggle()
                }
            } catch {
                print("Error liking idea: \(error)")
            }
        }
    }
    
    private func submitComment() {
        guard let currentUser = firebaseManager.currentUser,
              !newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isSubmittingComment = true
        let commentText = newComment.trimmingCharacters(in: .whitespacesAndNewlines)
        
        Task {
            do {
                let username = currentUser.displayName ?? "Anonymous User"
                print("💬 Submitting comment: '\(commentText)' by \(username)")
                _ = try await firebaseManager.addCommentToIdea(
                    ideaId: idea.id,
                    content: commentText,
                    authorId: currentUser.uid,
                    authorUsername: username
                )
                print("✅ Comment submitted successfully, reloading comments...")
                
                await MainActor.run {
                    newComment = ""
                    isSubmittingComment = false
                    loadComments() // Reload comments to show the new one
                }
            } catch {
                print("❌ Error submitting comment: \(error.localizedDescription)")
                await MainActor.run {
                    isSubmittingComment = false
                }
            }
        }
    }
    
    private func loadExistingPods() {
        isLoadingPods = true
        
        print("🔄 UI: Starting to load existing pods...")
        print("💡 UI: Idea details - ID: '\(idea.id)', Title: '\(idea.title)', Author: '\(idea.authorId)'")
        
        Task {
            do {
                let pods = try await firebaseManager.getPodsByIdeaId(ideaId: idea.id)
                await MainActor.run {
                    existingPods = pods
                    isLoadingPods = false
                    print("📊 UI: Loaded \(pods.count) existing pods for idea '\(idea.title)'")
                    
                    if pods.isEmpty {
                        print("⚠️ UI: No pods found - will show 'No Pods Yet' button")
                    } else {
                        print("✅ UI: Found pods - will show 'Join Pod' button")
                        for pod in pods {
                            print("  🏠 Pod: '\(pod.name)' (ID: \(pod.id), ideaId: '\(pod.ideaId)')")
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    existingPods = []
                    isLoadingPods = false
                    print("❌ UI: Failed to load pods for idea '\(idea.title)': \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func deleteIdea() {
        guard let currentUser = firebaseManager.currentUser else { return }
        
        isDeleting = true
        
        Task {
            do {
                try await firebaseManager.deleteIdeaSpark(ideaId: idea.id, userId: currentUser.uid)
                
                await MainActor.run {
                    isDeleting = false
                    dismiss() // Close the detail view after successful deletion
                }
            } catch {
                await MainActor.run {
                    isDeleting = false
                    // You could show an error alert here if needed
                    print("Error deleting idea: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - Comment Model
struct IdeaComment: Identifiable, Codable {
    let id: String
    let authorId: String
    let authorUsername: String
    let content: String
    let createdAt: Date
    let likes: Int
}

// MARK: - Comment Row
struct CommentRow: View {
    let comment: IdeaComment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(Color.accentGreen)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text(String(comment.authorUsername.prefix(1)).uppercased())
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(comment.authorUsername)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.textPrimary)
                    
                    Text(comment.createdAt.timeAgoDisplay())
                        .font(.system(size: 12))
                        .foregroundColor(Color.textSecondary)
                }
                
                Spacer()
            }
            
            Text(comment.content)
                .font(.system(size: 14))
                .foregroundColor(Color.textPrimary)
                .lineSpacing(2)
        }
        .padding(12)
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Create Pod From Idea View
struct CreatePodFromIdeaView: View {
    let idea: IdeaSpark
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var firebaseManager: FirebaseManager
    @State private var podName = ""
    @State private var podDescription = ""
    @State private var isSubmitting = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Create Pod from Idea".localized)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color.textPrimary)
                        
                        Text("Transform this idea into a collaborative project".localized)
                            .font(.system(size: 16))
                            .foregroundColor(Color.textSecondary)
                    }
                    .padding(.top, 20)
                    
                    // Pod Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Pod Name".localized)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.textPrimary)
                        
                        TextField("Enter pod name...".localized, text: $podName)
                            .textFieldStyle(CustomTextFieldStyle())
                    }
                    
                    // Pod Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Pod Description".localized)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.textPrimary)
                        
                        TextEditor(text: $podDescription)
                            .frame(minHeight: 100)
                            .padding(12)
                            .background(Color.backgroundSecondary)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.textSecondary.opacity(0.2), lineWidth: 1)
                            )
                    }
                    
                    // Submit Button
                    Button(action: createPod) {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "person.3")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            
                            Text(isSubmitting ? "Creating Pod...".localized : "Create Pod".localized)
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(canCreatePod && !isSubmitting ? Color.accentGreen : Color.textSecondary.opacity(0.3))
                        .cornerRadius(12)
                    }
                    .disabled(!canCreatePod || isSubmitting)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(Color.backgroundSecondary)
            .navigationTitle("Create Pod".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel".localized) {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Pre-fill with idea data
                if podName.isEmpty {
                    podName = idea.title
                }
                if podDescription.isEmpty {
                    podDescription = idea.description
                }
            }
        }
    }
    
    private var canCreatePod: Bool {
        !podName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !podDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func createPod() {
        guard let currentUser = firebaseManager.currentUser,
              canCreatePod else { return }
        
        isSubmitting = true
        
        Task {
            do {
                let username = currentUser.displayName ?? "Anonymous User"
                _ = try await firebaseManager.createPodFromIdea(
                    name: podName.trimmingCharacters(in: .whitespacesAndNewlines),
                    description: podDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                    ideaId: idea.id,
                    isPublic: true
                )
                
                await MainActor.run {
                    isSubmitting = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                }
            }
        }
    }
}

// MARK: - Join Pod View
struct JoinPodView: View {
    let availablePods: [IncubationPod]
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var firebaseManager: FirebaseManager
    @State private var selectedPod: IncubationPod?
    @State private var isJoining = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Join a Pod".localized)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color.textPrimary)
                        
                        Text("Select a pod to join and start collaborating".localized)
                            .font(.system(size: 16))
                            .foregroundColor(Color.textSecondary)
                    }
                    .padding(.top, 20)
                    
                    // Available Pods
                    LazyVStack(spacing: 16) {
                        ForEach(availablePods) { pod in
                            PodJoinCard(
                                pod: pod,
                                isSelected: selectedPod?.id == pod.id,
                                onSelect: { selectedPod = pod }
                            )
                        }
                    }
                    
                    // Join Button
                    Button(action: joinSelectedPod) {
                        HStack {
                            if isJoining {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "person.badge.plus")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            
                            Text(isJoining ? "Joining Pod...".localized : "Join Selected Pod".localized)
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(selectedPod != nil && !isJoining ? Color.accentBlue : Color.textSecondary.opacity(0.3))
                        .cornerRadius(12)
                    }
                    .disabled(selectedPod == nil || isJoining)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(Color.backgroundSecondary)
            .navigationTitle("Join Pod".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel".localized) {
                        dismiss()
                    }
                }
            }
            .alert("Join Pod Result".localized, isPresented: $showingAlert) {
                Button("OK".localized) {
                    if alertMessage.contains("successfully") {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func joinSelectedPod() {
        guard let pod = selectedPod,
              let currentUser = firebaseManager.currentUser else { return }
        
        isJoining = true
        
        Task {
            do {
                try await firebaseManager.addMemberToPod(podId: pod.id, userId: currentUser.uid, role: "Member")
                await MainActor.run {
                    isJoining = false
                    alertMessage = "Successfully joined pod '\(pod.name)'!".localized
                    showingAlert = true
                }
            } catch {
                await MainActor.run {
                    isJoining = false
                    alertMessage = "Failed to join pod: \(error.localizedDescription)".localized
                    showingAlert = true
                }
            }
        }
    }
}

// MARK: - Pod Join Card
struct PodJoinCard: View {
    let pod: IncubationPod
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(pod.name)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color.textPrimary)
                            .multilineTextAlignment(.leading)
                        
                        Text(pod.description)
                            .font(.system(size: 14))
                            .foregroundColor(Color.textSecondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24))
                        .foregroundColor(isSelected ? Color.accentBlue : Color.textSecondary)
                }
                
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "person.3")
                            .font(.system(size: 12))
                        Text("\(pod.members.count) members".localized)
                            .font(.system(size: 12))
                    }
                    
                    Spacer()
                    
                    Text("Created \(pod.createdAt.timeAgoDisplay())".localized)
                        .font(.system(size: 12))
                        .foregroundColor(Color.textSecondary)
                }
                .foregroundColor(Color.textSecondary)
            }
            .padding(16)
            .background(Color.backgroundPrimary)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentBlue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    IdeaDetailView(idea: IdeaSpark(
        id: "1",
        authorId: "user1",
        authorUsername: "John Doe",
        title: "Sample Idea",
        description: "This is a sample idea description",
        tags: ["AI", "Mobile"],
        isPublic: true,
        createdAt: Date(),
        updatedAt: Date(),
        likes: 5,
        comments: 3,
        status: .sparking
    ))
    .environmentObject(LocalizationManager.shared)
    .environmentObject(FirebaseManager.shared)
} 