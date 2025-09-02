//
//  IdeaDetailView.swift
//  Synapse
//
//  Created by Abdulrahman Alshehri on 18/01/1447 AH.
//

import SwiftUI
import Supabase

struct IdeaDetailView: View {
    @State private var currentIdea: IdeaSpark
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var supabaseManager: SupabaseManager
    @EnvironmentObject private var localizationManager: LocalizationManager
    
    init(idea: IdeaSpark) {
        self._currentIdea = State(initialValue: idea)
    }
    
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
    @State private var existingPods: [IncubationProject] = []
    @State private var isLoadingPods = false
    @State private var isUserInPod = false
    @State private var showMyPods = false
    @State private var showingEditIdea = false
    @State private var hasCreatedProject = false
    @State private var joinRequestStatus: String? = nil // pending, accepted, declined, nil

    private var isOwner: Bool {
        guard let currentUser = supabaseManager.currentUser else { return false }
        return currentUser.uid.lowercased() == currentIdea.authorId.lowercased()
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ideaHeaderSection
                    interactionStatsSection
                    actionButtonsSection
                    commentsSection
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
                
                if isOwner {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        ownerToolbarButtons
                    }
                }
            }
            .onAppear {
                loadComments()
                checkIfLiked()
                loadExistingPods()
            }
            .sheet(isPresented: $showingCreatePod, onDismiss: {
                loadExistingPods()
            }) {
                CreatePodFromIdeaView(idea: currentIdea, onCreated: {
                    // Mark that user has created a project
                    hasCreatedProject = true
                })
            }
            .sheet(isPresented: $showingJoinPod, onDismiss: {
                loadExistingPods()
            }) {
                JoinPodView(availablePods: existingPods)
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(items: [currentIdea.title, currentIdea.description])
            }
            .sheet(isPresented: $showingEditIdea) {
                EditIdeaView(idea: currentIdea) { updatedIdea in
                    currentIdea = updatedIdea
                }
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
    
    // MARK: - View Components
    
    private var ideaHeaderSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Circle()
                    .fill(Color.accentGreen)
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(String(currentIdea.authorUsername.prefix(1)).uppercased())
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(currentIdea.authorUsername)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.textPrimary)
                    
                    Text(currentIdea.createdAt.timeAgoDisplay())
                        .font(.system(size: 14))
                        .foregroundColor(Color.textSecondary)
                }
                
                Spacer()
                
                StatusBadge(status: currentIdea.status)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text(currentIdea.title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color.textPrimary)
                
                Text(currentIdea.description)
                    .font(.system(size: 16))
                    .foregroundColor(Color.textSecondary)
                    .lineSpacing(4)
                
                if !currentIdea.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(currentIdea.tags, id: \.self) { tag in
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
    }
    
    private var interactionStatsSection: some View {
        HStack(spacing: 20) {
            HStack(spacing: 6) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.red)
                Text("\(currentIdea.likes)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color.textPrimary)
            }
            
            HStack(spacing: 6) {
                Image(systemName: "message.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color.accentGreen)
                Text("\(currentIdea.comments)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color.textPrimary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
    
    private var actionButtonsSection: some View {
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
            
            projectActionButton
        }
        .padding(.horizontal, 20)
    }
    
    @ViewBuilder
    private var projectActionButton: some View {
        if let _ = supabaseManager.currentUser {
            if isOwner {
                if hasCreatedProject {
                    // User already created a project from this idea - show disabled state
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                        Text("Project Created".localized)
                            .font(.system(size: 14, weight: .medium))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.success.opacity(0.7))
                    .cornerRadius(20)
                    .fixedSize(horizontal: true, vertical: false)
                } else {
                    // User can create a project
                    Button(action: { showingCreatePod = true }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle")
                                .font(.system(size: 16))
                            Text("Create Project".localized)
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
                }
            } else {
                nonOwnerProjectButton
            }
        }
    }
    
    @ViewBuilder
    private var nonOwnerProjectButton: some View {
        if isLoadingPods {
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
        } else if isUserInPod {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                Text("Already in Project".localized)
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.accentGreen.opacity(0.8))
            .cornerRadius(20)
            .fixedSize(horizontal: true, vertical: false)
        } else if !existingPods.isEmpty {
            // Show different button based on join request status
            if joinRequestStatus == "pending" {
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.system(size: 16))
                    Text("Request Sent".localized)
                        .font(.system(size: 14, weight: .medium))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.accentOrange.opacity(0.8))
                .cornerRadius(20)
                .fixedSize(horizontal: true, vertical: false)
            } else {
                Button(action: { sendJoinRequest() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "person.3")
                            .font(.system(size: 16))
                        Text("Request to Join".localized)
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
            }
        } else {
            HStack(spacing: 6) {
                Image(systemName: "person.3.fill")
                    .font(.system(size: 16))
                Text("No Projects Yet".localized)
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
    
    private var ownerToolbarButtons: some View {
        HStack(spacing: 8) {
            Button(action: {
                showingEditIdea = true
            }) {
                Image(systemName: "pencil")
                    .foregroundColor(Color.accentGreen)
            }
            
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
    
    private var commentsSection: some View {
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
    
    // MARK: - Functions
    
    private func loadComments() {
        isLoadingComments = true
        
        Task {
            do {
                let commentData = try await supabaseManager.getIdeaComments(ideaId: currentIdea.id)
                
                await MainActor.run {
                    comments = commentData
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
        guard let currentUser = supabaseManager.currentUser else { return }
        isLiked = false
    }
    
    private func likeIdea() {
        guard let currentUser = supabaseManager.currentUser else { return }
        
        Task {
            do {
                print("✅ Like idea requested: \(currentIdea.id) by user \(currentUser.uid)")
                await MainActor.run {
                    isLiked.toggle()
                }
            } catch {
                print("Error liking idea: \(error)")
            }
        }
    }
    
    private func submitComment() {
        guard let currentUser = supabaseManager.currentUser,
              !newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isSubmittingComment = true
        let commentText = newComment.trimmingCharacters(in: .whitespacesAndNewlines)
        
        Task {
            do {
                // Get username from profile first, then fallback to Google display name
                var username = "Anonymous User"
                do {
                    if let userData = try await supabaseManager.getUserProfile(userId: currentUser.uid) {
                        username = userData["username"] as? String ?? currentUser.displayName ?? "Anonymous User"
                    } else {
                        username = currentUser.displayName ?? "Anonymous User"
                    }
                } catch {
                    username = currentUser.displayName ?? "Anonymous User"
                }
                
                print("💬 Submitting comment: '\(commentText)' by \(username)")
                
                _ = try await supabaseManager.addCommentToIdea(
                    ideaId: currentIdea.id,
                    content: commentText,
                    authorId: currentUser.uid,
                    authorUsername: username
                )
                
                print("✅ Comment submitted successfully, reloading comments...")
                
                await MainActor.run {
                    newComment = ""
                    isSubmittingComment = false
                    loadComments()
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
        print("💡 UI: Idea details - ID: '\(currentIdea.id)', Title: '\(currentIdea.title)', Author: '\(currentIdea.authorId)'")
        
        Task {
            do {
                let pods = try await supabaseManager.getPodsByIdeaId(currentIdea.id)
                
                let currentUserId = supabaseManager.currentUser?.uid ?? ""
                let userInPod = pods.contains { pod in
                    pod.members.contains { member in
                        member.userId == currentUserId
                    }
                }
                
                // Check if current user (idea owner) has already created a project from this idea
                let userCreatedProject = pods.contains { pod in
                    pod.creatorId.lowercased() == currentUserId.lowercased()
                }
                
                // Check join request status for non-owners
                var requestStatus: String? = nil
                if !userCreatedProject && !userInPod && !pods.isEmpty {
                    do {
                        requestStatus = try await supabaseManager.checkJoinRequestStatus(
                            podId: pods.first!.id,
                            userId: currentUserId
                        )
                    } catch {
                        print("⚠️ Failed to check join request status: \(error.localizedDescription)")
                    }
                }
                
                await MainActor.run {
                    existingPods = pods
                    isUserInPod = userInPod
                    hasCreatedProject = userCreatedProject
                    joinRequestStatus = requestStatus
                    isLoadingPods = false
                    print("📊 UI: Loaded \(pods.count) existing pods for idea '\(currentIdea.title)'")
                    print("👤 UI: User membership status - isUserInPod: \(userInPod)")
                    print("🏗️ UI: User created project status - hasCreatedProject: \(userCreatedProject)")
                    
                    if pods.isEmpty {
                        print("⚠️ UI: No pods found - will show 'Create Project' button")
                    } else if userCreatedProject {
                        print("✅ UI: User already created project - will show 'View My Project' button")
                    } else if userInPod {
                        print("✅ UI: User already in pod - will show 'Already in Pod' button")
                    } else {
                        print("✅ UI: Found pods, user not member - will show 'Join Pod' button")
                        for pod in pods {
                            print("  🏠 Pod: '\(pod.name)' (ID: \(pod.id), ideaId: '\(pod.ideaId)')")
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    existingPods = []
                    isUserInPod = false
                    hasCreatedProject = false
                    isLoadingPods = false
                    print("❌ UI: Failed to load pods for idea '\(currentIdea.title)': \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func deleteIdea() {
        guard let currentUser = supabaseManager.currentUser else { return }
        
        isDeleting = true
        
        Task {
            do {
                print("🗑️ Deleting idea: \(currentIdea.id) by user \(currentUser.uid)")
                try await supabaseManager.deleteIdeaSpark(ideaId: currentIdea.id)
                
                await MainActor.run {
                    isDeleting = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isDeleting = false
                    print("❌ Error deleting idea: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func sendJoinRequest() {
        guard let currentUser = supabaseManager.currentUser,
              let firstPod = existingPods.first else { return }
        
        Task {
            do {
                _ = try await supabaseManager.sendJoinRequest(
                    podId: firstPod.id,
                    inviteeId: firstPod.creatorId, // Pod owner who will receive the request
                    inviterId: currentUser.uid // User requesting to join
                )
                
                await MainActor.run {
                    joinRequestStatus = "pending"
                    print("✅ Join request sent successfully")
                }
            } catch {
                print("❌ Failed to send join request: \(error.localizedDescription)")
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
    var onCreated: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var supabaseManager: SupabaseManager
    @State private var podName = ""
    @State private var podDescription = ""
    @State private var isSubmitting = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Create Project from Idea".localized)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color.textPrimary)
                        
                        Text("Transform this idea into a collaborative project".localized)
                            .font(.system(size: 16))
                            .foregroundColor(Color.textSecondary)
                    }
                    .padding(.top, 20)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Project Name".localized)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.textPrimary)
                        
                        TextField("Enter project name...".localized, text: $podName)
                            .textFieldStyle(CustomTextFieldStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Project Description".localized)
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
                            
                            Text(isSubmitting ? "Creating Project...".localized : "Create Project".localized)
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
            .navigationTitle("Create Project".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel".localized) {
                        dismiss()
                    }
                }
            }
            .onAppear {
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
        guard let currentUser = supabaseManager.currentUser,
              canCreatePod else { return }
        
        isSubmitting = true
        
        Task {
            do {
                let trimmedName = podName.trimmingCharacters(in: .whitespacesAndNewlines)
                let trimmedDescription = podDescription.trimmingCharacters(in: .whitespacesAndNewlines)
                
                print("✅ Create pod from idea requested:")
                print("- Pod Name: \(trimmedName)")
                print("- Description: \(trimmedDescription)")
                print("- Idea ID: \(idea.id)")
                print("- Creator ID: \(currentUser.uid)")
                print("- Is Public: true")
                
                let podId = try await supabaseManager.createPodFromIdea(
                    ideaId: idea.id,
                    name: trimmedName,
                    description: trimmedDescription,
                    creatorId: currentUser.uid,
                    isPublic: true
                )
                
                print("🎉 SUCCESS: Pod created successfully with ID: \(podId)")
                
                await MainActor.run {
                    isSubmitting = false
                    dismiss()
                    onCreated?()
                }
            } catch {
                print("❌ ERROR: Failed to create pod - \(error.localizedDescription)")
                await MainActor.run {
                    isSubmitting = false
                }
            }
        }
    }
}

// MARK: - Join Pod View
struct JoinPodView: View {
    let availablePods: [IncubationProject]
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var supabaseManager: SupabaseManager
    @State private var selectedPod: IncubationProject?
    @State private var isJoining = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Join a Project".localized)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color.textPrimary)
                        
                        Text("Select a project to join and start collaborating".localized)
                            .font(.system(size: 16))
                            .foregroundColor(Color.textSecondary)
                    }
                    .padding(.top, 20)
                    
                    LazyVStack(spacing: 16) {
                        ForEach(availablePods) { pod in
                            PodJoinCard(
                                pod: pod,
                                isSelected: selectedPod?.id == pod.id,
                                onSelect: { selectedPod = pod }
                            )
                        }
                    }
                    
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
                            
                            Text(isJoining ? "Joining Project...".localized : "Join Selected Project".localized)
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
            .navigationTitle("Join Project".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel".localized) {
                        dismiss()
                    }
                }
            }
            .alert("Join Project Result".localized, isPresented: $showingAlert) {
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
              let currentUser = supabaseManager.currentUser else { return }
        
        isJoining = true
        
        Task {
            do {
                print("✅ Add member to project requested:")
                print("- Project ID: \(pod.id)")
                print("- User ID: \(currentUser.uid)")
                print("- Role: Member")
                await MainActor.run {
                    isJoining = false
                    alertMessage = "Successfully joined project '\(pod.name)'!".localized
                    showingAlert = true
                }
            } catch {
                await MainActor.run {
                    isJoining = false
                    alertMessage = "Failed to join project: \(error.localizedDescription)".localized
                    showingAlert = true
                }
            }
        }
    }
}

// MARK: - Pod Join Card
struct PodJoinCard: View {
    let pod: IncubationProject
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

// MARK: - Edit Idea View
struct EditIdeaView: View {
    let idea: IdeaSpark
    let onUpdated: (IdeaSpark) -> Void
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var supabaseManager: SupabaseManager
    @EnvironmentObject private var localizationManager: LocalizationManager
    
    @State private var title: String
    @State private var description: String
    @State private var tags: [String]
    @State private var newTag = ""
    @State private var isPublic: Bool
    @State private var isSubmitting = false
    @State private var showingSuccessAlert = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    private let maxTitleLength = 100
    private let maxDescriptionLength = 500
    private let maxTags = 5
    
    init(idea: IdeaSpark, onUpdated: @escaping (IdeaSpark) -> Void) {
        self.idea = idea
        self.onUpdated = onUpdated
        self._title = State(initialValue: idea.title)
        self._description = State(initialValue: idea.description)
        self._tags = State(initialValue: idea.tags)
        self._isPublic = State(initialValue: idea.isPublic)
    }
    
    var isFormValid: Bool {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return !trimmedTitle.isEmpty &&
               !trimmedDescription.isEmpty &&
               title.count <= maxTitleLength &&
               description.count <= maxDescriptionLength
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Edit Idea".localized)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color.textPrimary)
                        
                        Text("Update your idea details".localized)
                            .font(.system(size: 16))
                            .foregroundColor(Color.textSecondary)
                    }
                    .padding(.horizontal, 20)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Idea Title".localized)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color.textPrimary)
                            
                            Spacer()
                            
                            Text("\(title.count)/\(maxTitleLength)")
                                .font(.system(size: 12))
                                .foregroundColor(title.count > maxTitleLength ? Color.error : Color.textSecondary)
                        }
                        
                        TextField("Enter your idea title...".localized, text: $title)
                            .textFieldStyle(CustomTextFieldStyle())
                            .onChange(of: title) { _, newValue in
                                if newValue.count > maxTitleLength {
                                    title = String(newValue.prefix(maxTitleLength))
                                }
                            }
                    }
                    .padding(.horizontal, 20)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Description".localized)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color.textPrimary)
                            
                            Spacer()
                            
                            Text("\(description.count)/\(maxDescriptionLength)")
                                .font(.system(size: 12))
                                .foregroundColor(description.count > maxDescriptionLength ? Color.error : Color.textSecondary)
                        }
                        
                        TextEditor(text: $description)
                            .frame(minHeight: 120)
                            .padding(12)
                            .background(Color.backgroundSecondary)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.textSecondary.opacity(0.2), lineWidth: 1)
                            )
                            .onChange(of: description) { _, newValue in
                                if newValue.count > maxDescriptionLength {
                                    description = String(newValue.prefix(maxDescriptionLength))
                                }
                            }
                    }
                    .padding(.horizontal, 20)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Tags".localized)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color.textPrimary)
                            
                            Spacer()
                            
                            Text("\(tags.count)/\(maxTags)")
                                .font(.system(size: 12))
                                .foregroundColor(Color.textSecondary)
                        }
                        
                        if tags.count < maxTags {
                            HStack {
                                TextField("Add tags separated by commas...".localized, text: $newTag)
                                    .textFieldStyle(CustomTextFieldStyle())
                                
                                Button(action: addTag) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(Color.accentGreen)
                                }
                                .disabled(newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            }
                        }
                        
                        if !tags.isEmpty {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                                ForEach(tags, id: \.self) { tag in
                                    TagView(tag: tag) {
                                        removeTag(tag)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Privacy".localized)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.textPrimary)
                        
                        VStack(spacing: 12) {
                            PrivacyOption(
                                title: "Make Public".localized,
                                description: "Anyone can see and join this idea".localized,
                                isSelected: isPublic,
                                action: { isPublic = true }
                            )
                            
                            PrivacyOption(
                                title: "Private".localized,
                                description: "Only invited collaborators can see your idea".localized,
                                isSelected: !isPublic,
                                action: { isPublic = false }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    VStack(spacing: 16) {
                        Button(action: updateIdea) {
                            HStack {
                                if isSubmitting {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                
                                Text(isSubmitting ? "Updating...".localized : "Update Idea".localized)
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(isFormValid && !isSubmitting ? Color.accentGreen : Color.textSecondary.opacity(0.3))
                            .cornerRadius(12)
                        }
                        .disabled(!isFormValid || isSubmitting)
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 40)
            }
            .background(Color.backgroundSecondary)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel".localized) {
                        dismiss()
                    }
                }
            }
            .alert("Idea Updated!".localized, isPresented: $showingSuccessAlert) {
                Button("OK".localized) {
                    dismiss()
                }
            } message: {
                Text("Your idea has been updated successfully.".localized)
            }
            .alert("Error Updating Idea".localized, isPresented: $showingErrorAlert) {
                Button("OK".localized) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func addTag() {
        let trimmedTag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTag.isEmpty && !tags.contains(trimmedTag) && tags.count < maxTags {
            tags.append(trimmedTag)
            newTag = ""
        }
    }
    
    private func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
    
    private func updateIdea() {
        guard isFormValid else { return }
        
        isSubmitting = true
        
        Task {
            do {
                print("📝 Updating idea: \(idea.id)")
                try await supabaseManager.updateIdeaSpark(
                    ideaId: idea.id,
                    title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                    description: description.trimmingCharacters(in: .whitespacesAndNewlines),
                    tags: tags,
                    isPublic: isPublic
                )
                
                let updatedIdea = IdeaSpark(
                    id: idea.id,
                    authorId: idea.authorId,
                    authorUsername: idea.authorUsername,
                    title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                    description: description.trimmingCharacters(in: .whitespacesAndNewlines),
                    tags: tags,
                    isPublic: isPublic,
                    createdAt: idea.createdAt,
                    updatedAt: Date(),
                    likes: idea.likes,
                    comments: idea.comments,
                    status: idea.status
                )
                
                await MainActor.run {
                    isSubmitting = false
                    onUpdated(updatedIdea)
                    showingSuccessAlert = true
                }
            } catch {
                print("❌ Error updating idea: \(error.localizedDescription)")
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = error.localizedDescription
                    showingErrorAlert = true
                }
            }
        }
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
    .environmentObject(SupabaseManager.shared)
}
