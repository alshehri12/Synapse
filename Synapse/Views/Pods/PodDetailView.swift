//
//  PodDetailView.swift
//  Synapse
//
//  Created by Abdulrahman Alshehri on 18/01/1447 AH.
//

import SwiftUI
import Supabase
struct PodDetailView: View {
    @State private var currentPod: IncubationProject
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var supabaseManager: SupabaseManager
    @EnvironmentObject private var localizationManager: LocalizationManager
    
    // Placeholder for chat functionality - to be integrated with SupabaseManager
    @State private var chatMessages: [ChatMessage] = []
    @State private var typingUsers: [String] = []
    @State private var messageText = ""
    @FocusState private var isTextFieldFocused: Bool
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var showingMessageOptions: ChatMessage?
    
    @State private var selectedTab = 0
    @State private var showingTaskSheet = false
    @State private var showingMemberSheet = false
    @State private var showingSettings = false
    @State private var showingFullScreenChat = false
    @State private var isRefreshingTasks = false
    
    init(pod: IncubationProject) {
        self._currentPod = State(initialValue: pod)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 16) {
                    // Pod Info
                    VStack(alignment: .leading, spacing: 8) {
                        Text(currentPod.name)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color.textPrimary)
                        
                        Text(currentPod.description)
                            .font(.system(size: 16))
                            .foregroundColor(Color.textSecondary)
                        
                        HStack {
                            ProjectStatusBadge(status: currentPod.status)
                            
                            Spacer()
                            
                            Text("Created \(currentPod.createdAt.timeAgoDisplay())")
                                .font(.system(size: 12))
                                .foregroundColor(Color.textSecondary)
                        }
                    }
                    
                    // Quick Stats
                    HStack(spacing: 20) {
                        StatCard(
                            title: "Members".localized,
                            value: "\(currentPod.members.count)",
                            icon: "person.3",
                            color: Color.accentGreen
                        )
                        
                        StatCard(
                            title: "Tasks".localized,
                            value: "\(currentPod.tasks.count)",
                            icon: "checklist",
                            color: Color.accentBlue
                        )
                        
                        StatCard(
                            title: "Completed".localized,
                            value: "\(completedTasksCount)",
                            icon: "checkmark.circle",
                            color: Color.success
                        )
                    }
                }
                .padding(20)
                .background(Color.backgroundPrimary)
                
                // Tab Selector
                HStack(spacing: 0) {
                    TabButton(
                        title: "Overview".localized,
                        isSelected: selectedTab == 0,
                        action: { selectedTab = 0 }
                    )
                    
                    TabButton(
                        title: "Tasks".localized,
                        isSelected: selectedTab == 1,
                        action: { selectedTab = 1 }
                    )
                    
                    TabButton(
                        title: "Members".localized,
                        isSelected: selectedTab == 2,
                        action: { selectedTab = 2 }
                    )
                    
                    TabButton(
                        title: "Chat".localized,
                        isSelected: false, // Never selected since it opens modal
                        action: { showingFullScreenChat = true }
                    )
                }
                .background(Color.backgroundPrimary)
                .padding(.horizontal, 20)
                
                // Tab Content
                TabView(selection: $selectedTab) {
                    OverviewTab(pod: currentPod)
                        .tag(0)
                    
                    TasksTab(pod: currentPod, showingTaskSheet: $showingTaskSheet, onTaskUpdated: refreshTasks)
                        .tag(1)
                    
                    MembersTab(pod: currentPod, showingMemberSheet: $showingMemberSheet)
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .background(Color.backgroundSecondary)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // Load both tasks and members when view appears
                refreshTasks()
                refreshMembers()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close".localized) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        // Debug: Always show for now, but check creator status
                        let isCreator = currentPod.creatorId.lowercased() == (supabaseManager.currentUser?.uid.lowercased() ?? "")
                        print("🔍 Debug - Creator check: podCreatorId='\(currentPod.creatorId)', currentUserId='\(supabaseManager.currentUser?.uid ?? "nil")', isCreator=\(isCreator)")
                        
                        // Show task and member options for creator
                        if isCreator {
                            Button(action: { showingTaskSheet = true }) {
                                Label("Add Task".localized, systemImage: "plus.circle")
                            }
                            
                            Button(action: { showingMemberSheet = true }) {
                                Label("Invite Member".localized, systemImage: "person.badge.plus")
                            }
                            
                            Divider()
                        }
                        
                        Button(action: { showingSettings = true }) {
                            Label("Pod Settings".localized, systemImage: "gear")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(Color.accentGreen)
                    }
                }
            }
            .sheet(isPresented: $showingTaskSheet, onDismiss: refreshTasks) {
                CreateTaskView(pod: currentPod)
            }
            .sheet(isPresented: $showingMemberSheet, onDismiss: {
                refreshMembers() // Refresh members after adding new ones
            }) {
                InviteMemberView(pod: currentPod)
            }
            .sheet(isPresented: $showingSettings) {
                PodSettingsView(pod: currentPod)
            }
            .fullScreenCover(isPresented: $showingFullScreenChat) {
                FullScreenChatView(pod: currentPod)
            }
        }
    }
    
    private var completedTasksCount: Int {
        currentPod.tasks.filter { $0.status == .completed }.count
    }
    
    private func refreshTasks() {
        isRefreshingTasks = true
        Task {
            do {
                let updatedTasks = try await supabaseManager.getProjectTasks(podId: currentPod.id)
                print("📋 Loaded \(updatedTasks.count) tasks for project \(currentPod.name)")
                
                await MainActor.run {
                    currentPod = IncubationProject(
                        id: currentPod.id,
                        ideaId: currentPod.ideaId,
                        name: currentPod.name,
                        description: currentPod.description,
                        creatorId: currentPod.creatorId,
                        isPublic: currentPod.isPublic,
                        createdAt: currentPod.createdAt,
                        updatedAt: currentPod.updatedAt,
                        members: currentPod.members,
                        tasks: updatedTasks,
                        status: currentPod.status
                    )
                    isRefreshingTasks = false
                }
            } catch {
                await MainActor.run {
                    isRefreshingTasks = false
                }
                print("❌ Failed to refresh tasks: \(error.localizedDescription)")
            }
        }
    }
    
    private func refreshMembers() {
        Task {
            do {
                let updatedMembers = try await supabaseManager.getPodMembers(podId: currentPod.id)
                print("👥 Loaded \(updatedMembers.count) members for project \(currentPod.name)")
                
                await MainActor.run {
                    currentPod = IncubationProject(
                        id: currentPod.id,
                        ideaId: currentPod.ideaId,
                        name: currentPod.name,
                        description: currentPod.description,
                        creatorId: currentPod.creatorId,
                        isPublic: currentPod.isPublic,
                        createdAt: currentPod.createdAt,
                        updatedAt: currentPod.updatedAt,
                        members: updatedMembers,
                        tasks: currentPod.tasks,
                        status: currentPod.status
                    )
                }
            } catch {
                print("❌ Failed to refresh members: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Overview Tab
struct OverviewTab: View {
    let pod: IncubationProject
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Progress Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Progress".localized)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color.textPrimary)
                    
                    VStack(spacing: 16) {
                        // Overall Progress
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Overall Progress".localized)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color.textPrimary)
                                
                                Spacer()
                                
                                Text("\(Int(overallProgress * 100))%")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color.accentGreen)
                            }
                            
                            ProgressView(value: overallProgress)
                                .progressViewStyle(LinearProgressViewStyle(tint: Color.accentGreen))
                                .scaleEffect(x: 1, y: 2, anchor: .center)
                        }
                        
                        // Task Status Breakdown
                        HStack(spacing: 20) {
                            TaskStatusCard(
                                status: "To Do".localized,
                                count: todoCount,
                                color: Color.textSecondary
                            )
                            
                            TaskStatusCard(
                                status: "In Progress".localized,
                                count: inProgressCount,
                                color: Color.accentOrange
                            )
                            
                            TaskStatusCard(
                                status: "Completed".localized,
                                count: completedCount,
                                color: Color.success
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                // Recent Activity
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Activity".localized)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color.textPrimary)
                        .padding(.horizontal, 20)
                    
                    if recentActivities.isEmpty {
                        Text("No recent activity".localized)
                            .font(.system(size: 14))
                            .foregroundColor(Color.textSecondary)
                            .padding(.horizontal, 20)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(recentActivities, id: \.id) { activity in
                                ActivityRow(activity: activity)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            .padding(.vertical, 20)
        }
    }
    
    private var overallProgress: Double {
        guard !pod.tasks.isEmpty else { return 0 }
        return Double(completedCount) / Double(pod.tasks.count)
    }
    
    private var todoCount: Int {
        pod.tasks.filter { $0.status == .todo }.count
    }
    
    private var inProgressCount: Int {
        pod.tasks.filter { $0.status == .inProgress }.count
    }
    
    private var completedCount: Int {
        pod.tasks.filter { $0.status == .completed }.count
    }
    
    private var recentActivities: [ActivityItem] {
        var activities: [ActivityItem] = []
        
        // Get recently completed tasks (last 7 days)
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recentCompletedTasks = pod.tasks
            .filter { $0.status == .completed }
            .filter { $0.updatedAt > sevenDaysAgo }
            .sorted { $0.updatedAt > $1.updatedAt }
            .prefix(3) // Show last 3 completed tasks
        
        for task in recentCompletedTasks {
            activities.append(ActivityItem(
                type: "task_completed",
                message: "Task '\(task.title)' was completed",
                timestamp: task.updatedAt,
                user: task.assignedToUsername ?? "Someone"
            ))
        }
        
        // Get recently created tasks (last 7 days)
        let recentCreatedTasks = pod.tasks
            .filter { $0.createdAt > Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date() }
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(2) // Show last 2 created tasks
        
        for task in recentCreatedTasks {
            // Only add if not already shown as completed
            if !activities.contains(where: { $0.message.contains(task.title) }) {
                activities.append(ActivityItem(
                    type: "task_created",
                    message: "New task '\(task.title)' was created",
                    timestamp: task.createdAt,
                    user: task.assignedToUsername ?? "Someone"
                ))
            }
        }
        
        // Sort all activities by timestamp (most recent first)
        return activities.sorted { $0.timestamp > $1.timestamp }
    }
}

// MARK: - Tasks Tab
struct TasksTab: View {
    let pod: IncubationProject
    @Binding var showingTaskSheet: Bool
    let onTaskUpdated: () -> Void
    @State private var selectedFilter: ProjectTask.TaskStatus? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Filter Buttons
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    FilterButton(
                        title: "All".localized,
                        isSelected: selectedFilter == nil,
                        action: { selectedFilter = nil }
                    )
                    
                    ForEach(ProjectTask.TaskStatus.allCases, id: \.self) { status in
                        FilterButton(
                            title: status.rawValue.localized.capitalized,
                            isSelected: selectedFilter == status,
                            action: { selectedFilter = status }
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 16)
            
            // Tasks List
            if filteredTasks.isEmpty {
                EmptyStateView(
                    icon: "checklist",
                    title: "No tasks".localized,
                    message: selectedFilter == nil ? "Create your first task to get started".localized : "No tasks in this status".localized
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredTasks) { task in
                            TaskRow(task: task, pod: pod, onTaskUpdated: onTaskUpdated)
                                .padding(.horizontal, 20)
                        }
                    }
                    .padding(.vertical, 16)
                }
            }
        }
        .background(Color.backgroundSecondary)
    }
    
    private var filteredTasks: [ProjectTask] {
        guard let filter = selectedFilter else { return pod.tasks }
        return pod.tasks.filter { $0.status == filter }
    }
}

// MARK: - Members Tab
struct MembersTab: View {
    let pod: IncubationProject
    @Binding var showingMemberSheet: Bool
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(pod.members) { member in
                    MemberRow(member: member)
                        .padding(.horizontal, 20)
                }
            }
            .padding(.vertical, 16)
        }
        .background(Color.backgroundSecondary)
    }
}

// MARK: - Full Screen Chat
struct FullScreenChatView: View {
    let pod: IncubationProject
    @Environment(\.dismiss) private var dismiss
    @StateObject private var supabaseManager = SupabaseManager.shared
    @State private var messageText = ""
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var showingMessageOptions: ChatMessage?
    @FocusState private var isTextFieldFocused: Bool
    
    // Placeholder for chat functionality - to be integrated with SupabaseManager
    @State private var chatMessages: [ChatMessage] = []
    @State private var typingUsers: [TypingIndicator] = []
    
    var body: some View {
        NavigationView {
            mainChatView
        }
        .onAppear {
            loadChatMessages()
        }
        .actionSheet(item: $showingMessageOptions) { message in
            messageOptionsActionSheet(for: message)
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
        }
    }
    
    // MARK: - Main Chat View
    private var mainChatView: some View {
            VStack(spacing: 0) {
                // Messages Area
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            // Welcome message for empty chat
                            if chatMessages.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "bubble.left.and.bubble.right")
                                        .font(.system(size: 50))
                                        .foregroundColor(Color.textSecondary.opacity(0.6))
                                    
                                    Text("Start the conversation!")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(Color.textPrimary)
                                    
                                    Text("Send a message to get things started")
                                        .font(.system(size: 16))
                                        .foregroundColor(Color.textSecondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.top, 100)
                            }
                            
                            ForEach(chatMessages) { message in
                                MessageBubble(
                                    message: message,
                                    isFromCurrentUser: message.senderId == supabaseManager.currentUser?.uid,
                                    onLongPress: { showingMessageOptions = message }
                                )
                                .id(message.id)
                            }
                            
                            // Typing indicators
                            if !typingUsers.isEmpty {
                                TypingIndicatorView(users: typingUsers)
                                    .padding(.top, 4)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                    .onChange(of: chatMessages.count) { _ in
                        scrollToBottom(proxy: proxy)
                    }
                }
                
                // Input Area - Simplified without complex keyboard handling
                VStack(spacing: 0) {
                    HStack(spacing: 16) {
                        // Attachment button
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
                        
                        // Text field
                        HStack {
                            TextField("Type a message...", text: $messageText, axis: .vertical)
                                .textFieldStyle(PlainTextFieldStyle())
                                .font(.system(size: 16))
                                .foregroundColor(Color.textPrimary)
                                .focused($isTextFieldFocused)
                                .lineLimit(1...4)
                                .onChange(of: messageText) { _ in
                                    if !messageText.isEmpty {
                                        // TODO: Implement typing indicators
                                    } else {
                                        // TODO: Implement typing indicators
                                    }
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
                        
                        // Send button
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
                    .background(Color.backgroundPrimary)
                    .overlay(
                        Rectangle()
                            .frame(height: 0.5)
                            .foregroundColor(Color.border.opacity(0.3)),
                        alignment: .top
                    )
                }
            }
            .navigationTitle(pod.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(Color.accentGreen)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        Text("\(pod.members.count)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color.textSecondary)
                    }
                }
            }
            .onAppear {
                // TODO: Implement chat room joining
            }
            .onDisappear {
                // TODO: Implement chat room leaving  
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedImage: $selectedImage)
            }
            .actionSheet(item: $showingMessageOptions) { message in
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
        }
    }

// MARK: - FullScreenChatView Functions
extension FullScreenChatView {
    private func loadChatMessages() {
        Task {
            do {
                let messages = try await supabaseManager.getChatMessages(podId: pod.id)
                await MainActor.run {
                    chatMessages = messages
                    print("💬 Loaded \(messages.count) chat messages")
                }
            } catch {
                print("❌ Failed to load chat messages: \(error.localizedDescription)")
            }
        }
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let currentUser = supabaseManager.currentUser else { return }
        
        let messageContent = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        messageText = ""
        
        Task {
            do {
                let username = currentUser.displayName ?? "Anonymous User"
                _ = try await supabaseManager.sendChatMessage(
                    podId: pod.id,
                    content: messageContent,
                    senderId: currentUser.uid,
                    senderUsername: username
                )
                print("💬 Message sent successfully")
                loadChatMessages() // Reload to show new message
            } catch {
                print("❌ Failed to send message: \(error.localizedDescription)")
            }
        }
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        if let lastMessage = chatMessages.last {
            withAnimation(.easeInOut(duration: 0.3)) {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
    
    // MARK: - Message Options Action Sheet
    private func messageOptionsActionSheet(for message: ChatMessage) -> ActionSheet {
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
}

// MARK: - Supporting Views
struct TaskStatusCard: View {
    let status: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text("\(count)")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(color)
            
            Text(status)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.backgroundPrimary)
        .cornerRadius(12)
    }
}

// MARK: - Badge Components
struct TaskStatusBadge: View {
    let status: ProjectTask.TaskStatus
    
    var body: some View {
        Text(status.displayName)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor)
            .cornerRadius(8)
    }
    
    private var statusColor: Color {
        switch status {
        case .todo: return Color.textSecondary
        case .inProgress: return Color.accentOrange
        case .completed: return Color.success
        case .cancelled: return Color.error
        }
    }
}

struct PriorityBadge: View {
    let priority: ProjectTask.TaskPriority
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(priorityColor)
                .frame(width: 8, height: 8)
            
            Text(priority.displayName)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(priorityColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(priorityColor.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var priorityColor: Color {
        switch priority {
        case .low: return Color.accentGreen
        case .medium: return Color.accentBlue
        case .high: return Color.accentOrange
        case .urgent: return Color.error
        }
    }
}

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? Color.white : Color.textSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentGreen : Color.backgroundPrimary)
                .cornerRadius(20)
        }
    }
}

struct TaskRow: View {
    let task: ProjectTask
    let pod: IncubationProject
    let onTaskUpdated: () -> Void
    @EnvironmentObject private var supabaseManager: SupabaseManager
    @State private var showingStatusPicker = false
    @State private var showingPriorityPicker = false
    @State private var showingDeleteAlert = false
    @State private var isUpdating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Completion checkbox
                Button(action: toggleTaskCompletion) {
                    Image(systemName: task.status == .completed ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24))
                        .foregroundColor(task.status == .completed ? Color.success : Color.textSecondary)
                        .animation(.easeInOut(duration: 0.2), value: task.status == .completed)
                }
                .disabled(isUpdating)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(task.status == .completed ? Color.textSecondary : Color.textPrimary)
                        .strikethrough(task.status == .completed, color: Color.textSecondary)
                    
                    if let description = task.description, !description.isEmpty {
                        Text(description)
                            .font(.system(size: 14))
                            .foregroundColor(Color.textSecondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    // Interactive Priority Badge
                    Button(action: { showingPriorityPicker = true }) {
                        PriorityBadge(priority: task.priority)
                    }
                    .disabled(isUpdating)
                    
                    // Interactive Status Badge
                    Button(action: { showingStatusPicker = true }) {
                        TaskStatusBadge(status: task.status)
                    }
                    .disabled(isUpdating)
                }
            }
            
            HStack {
                if let assignedTo = task.assignedToUsername, !assignedTo.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "person")
                            .font(.system(size: 12))
                            .foregroundColor(Color.textSecondary)
                        
                        Text(assignedTo)
                            .font(.system(size: 12))
                            .foregroundColor(Color.textSecondary)
                    }
                }
                
                Spacer()
                
                if let dueDate = task.dueDate {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 12))
                            .foregroundColor(isOverdue ? Color.error : Color.textSecondary)
                        
                        Text(dueDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.system(size: 12))
                            .foregroundColor(isOverdue ? Color.error : Color.textSecondary)
                    }
                }
                
                // Delete button (only show for task creators or pod admins)
                Button(action: { showingDeleteAlert = true }) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundColor(Color.error.opacity(0.7))
                }
                .disabled(isUpdating)
            }
        }
        .padding(16)
        .background(Color.backgroundPrimary)
        .cornerRadius(12)
        .opacity(isUpdating ? 0.6 : 1.0)
        .overlay(
            isUpdating ? 
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color.accentGreen))
                .scaleEffect(0.8)
            : nil
        )
        .confirmationDialog("Change Status", isPresented: $showingStatusPicker) {
                                        ForEach(ProjectTask.TaskStatus.allCases, id: \.self) { status in
                Button(status.displayName) {
                    updateTaskStatus(status)
                }
            }
            Button("Cancel", role: .cancel) { }
        }
        .confirmationDialog("Change Priority", isPresented: $showingPriorityPicker) {
                                        ForEach(ProjectTask.TaskPriority.allCases, id: \.self) { priority in
                Button(priority.displayName) {
                    updateTaskPriority(priority)
                }
            }
            Button("Cancel", role: .cancel) { }
        }
        .alert("Delete Task", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteTask()
            }
        } message: {
            Text("Are you sure you want to delete this task? This action cannot be undone.")
        }
    }
    
    private var isOverdue: Bool {
        guard let dueDate = task.dueDate else { return false }
        return dueDate < Date() && task.status != .completed
    }
    
    private func toggleTaskCompletion() {
        let newStatus: ProjectTask.TaskStatus = task.status == .completed ? .todo : .completed
        updateTaskStatus(newStatus)
    }
    
    private func updateTaskStatus(_ status: ProjectTask.TaskStatus) {
        isUpdating = true
        Task {
            do {
                try await supabaseManager.updateTaskStatus(taskId: task.id, status: status.rawValue)
                print("✅ Task status updated: \(task.id) -> \(status.rawValue)")
                await MainActor.run {
                    isUpdating = false
                    onTaskUpdated() // Refresh tasks in parent view
                }
            } catch {
                await MainActor.run {
                    isUpdating = false
                }
                print("❌ Failed to update task status: \(error.localizedDescription)")
            }
        }
    }
    
    private func updateTaskPriority(_ priority: ProjectTask.TaskPriority) {
        isUpdating = true
        Task {
            do {
                try await supabaseManager.updateTaskPriority(taskId: task.id, priority: priority.rawValue)
                print("✅ Task priority updated: \(task.id) -> \(priority.rawValue)")
                await MainActor.run {
                    isUpdating = false
                    onTaskUpdated() // Refresh tasks in parent view
                }
            } catch {
                await MainActor.run {
                    isUpdating = false
                }
                print("❌ Failed to update task priority: \(error.localizedDescription)")
            }
        }
    }
    
    private func deleteTask() {
        isUpdating = true
        Task {
            do {
                try await supabaseManager.deleteTask(taskId: task.id)
                print("✅ Task deleted: \(task.id)")
                await MainActor.run {
                    isUpdating = false
                    onTaskUpdated() // Refresh tasks in parent view
                }
            } catch {
                await MainActor.run {
                    isUpdating = false
                }
                print("❌ Failed to delete task: \(error.localizedDescription)")
            }
        }
    }
}

struct MemberRow: View {
    let member: ProjectMember
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(Color.accentGreen)
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(member.username.prefix(1)).uppercased())
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                )
            
            // Member Info
            VStack(alignment: .leading, spacing: 4) {
                Text(member.username)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.textPrimary)
                
                Text(member.role)
                    .font(.system(size: 14))
                    .foregroundColor(Color.textSecondary)
            }
            
            Spacer()
            
            // Role Badge
            Text(member.permissions.contains(.admin) ? "Admin".localized : "Member".localized)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(member.permissions.contains(.admin) ? Color.accentGreen : Color.textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(member.permissions.contains(.admin) ? Color.accentGreen.opacity(0.1) : Color.backgroundSecondary)
                .cornerRadius(8)
        }
        .padding(16)
        .background(Color.backgroundPrimary)
        .cornerRadius(12)
    }
}

// MARK: - Activity Row
struct ActivityRow: View {
    let activity: ActivityItem
    
    var body: some View {
        HStack(spacing: 12) {
            // Activity Icon
            Circle()
                .fill(Color.accentGreen.opacity(0.1))
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: activityIcon)
                        .font(.system(size: 14))
                        .foregroundColor(Color.accentGreen)
                )
            
            // Activity Content
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.message)
                    .font(.system(size: 14))
                    .foregroundColor(Color.textPrimary)
                
                HStack(spacing: 8) {
                    Text(activity.user)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.accentGreen)
                    
                    Text("•")
                        .font(.system(size: 12))
                        .foregroundColor(Color.textSecondary)
                    
                    Text(activity.timestamp.timeAgoDisplay())
                        .font(.system(size: 12))
                        .foregroundColor(Color.textSecondary)
                }
            }
            
            Spacer()
        }
        .padding(12)
        .background(Color.backgroundPrimary)
        .cornerRadius(8)
    }
    
    private var activityIcon: String {
        switch activity.type {
        case "task_created": return "plus.circle"
        case "task_completed": return "checkmark.circle"
        case "member_joined": return "person.badge.plus"
        case "message": return "message"
        default: return "circle"
        }
    }
}

// MARK: - Activity Item
struct ActivityItem: Identifiable {
    let id = UUID()
    let type: String
    let message: String
    let timestamp: Date
    let user: String
}

#Preview {
    PodDetailView(pod: mockPods[0])
        .environmentObject(LocalizationManager.shared)
        .environmentObject(SupabaseManager.shared)
} 
