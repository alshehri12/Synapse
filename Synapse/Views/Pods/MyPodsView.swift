//
//  MyPodsView.swift
//  Synapse
//
//  Created by Abdulrahman Alshehri on 18/01/1447 AH.
//

import SwiftUI
import Supabase

struct MyPodsView: View {
    @State private var selectedTab = 0
    @State private var pods: [IncubationProject] = []
    @State private var privateIdeas: [IdeaSpark] = []
    @State private var isLoading = false
    @EnvironmentObject private var localizationManager: LocalizationManager
    @EnvironmentObject private var supabaseManager: SupabaseManager
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Elegant Header
                MyProjectsHeader(
                    onCreateProject: {
                        // Navigate to create pod view if available
                        // For now, this can be left empty or trigger a future action
                    }
                )
                .environmentObject(localizationManager)

                // Tab Selector
                HStack(spacing: 0) {
                    TabButton(
                        title: "Active".localized,
                        isSelected: selectedTab == 0,
                        action: { selectedTab = 0 }
                    )

                    TabButton(
                        title: "Completed".localized,
                        isSelected: selectedTab == 1,
                        action: { selectedTab = 1 }
                    )
                }
                .background(Color.backgroundPrimary)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                
                // Pods and Private Ideas List
                if isLoading {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color.accentGreen))
                        .scaleEffect(1.2)
                    Spacer()
                } else if filteredPods.isEmpty && privateIdeas.isEmpty {
                    EmptyStateView(
                        icon: "person.3",
                        title: "No projects or ideas found".localized,
                        message: selectedTab == 0 ? "Join a pod or create an idea to start collaborating!".localized : "No projects in this category".localized
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            // Private Ideas Section (only in Active tab)
                            if selectedTab == 0 && !privateIdeas.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("My Private Ideas".localized)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(Color.textPrimary)
                                        .padding(.horizontal, 20)
                                        .padding(.top, 8)

                                    ForEach(privateIdeas) { idea in
                                        NavigationLink(destination: IdeaDetailView(idea: idea)) {
                                            PrivateIdeaCard(idea: idea)
                                                .padding(.horizontal, 20)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }

                            // Pods Section
                            if !filteredPods.isEmpty {
                                if selectedTab == 0 && !privateIdeas.isEmpty {
                                    Text("My Projects".localized)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(Color.textPrimary)
                                        .padding(.horizontal, 20)
                                        .padding(.top, 16)
                                }

                                ForEach(filteredPods) { pod in
                                    PodCard(pod: pod)
                                        .padding(.horizontal, 20)
                                }
                            }
                        }
                        .padding(.vertical, 16)
                    }
                    .refreshable {
                        await refreshPods()
                    }
                }
            }
            .background(Color.backgroundSecondary)
            .navigationBarHidden(true)
            .onAppear {
                loadPods()
            }
            .onReceive(NotificationCenter.default.publisher(for: .podMembershipChanged)) { _ in
                loadPods()
            }
        }
    }
    
    var filteredPods: [IncubationProject] {
        switch selectedTab {
        case 0: // Active tab - show both "active" and "planning" pods (old planning pods are now considered active)
            return pods.filter { $0.status == .active || $0.status == .planning }
        case 1: // Completed tab
            return pods.filter { $0.status == .completed }
        default:
            return pods.filter { $0.status == .active || $0.status == .planning }
        }
    }
    
    private func loadPods() {
        guard let currentUser = supabaseManager.currentUser else { return }

        isLoading = true

        Task {
            do {
                // Load both pods and private ideas
                async let userPods = supabaseManager.getPodsForUser(userId: currentUser.uid)
                async let userPrivateIdeas = supabaseManager.getUserPrivateIdeas(userId: currentUser.uid)

                let (pods, ideas) = try await (userPods, userPrivateIdeas)

                await MainActor.run {
                    self.pods = pods
                    self.privateIdeas = ideas
                    self.isLoading = false
                    print("✅ Loaded \(pods.count) pods and \(ideas.count) private ideas for user.")
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    print("❌ Error loading user pods/ideas: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func refreshPods() async {
        guard let currentUser = supabaseManager.currentUser else { return }
        
        do {
            let userPods = try await supabaseManager.getPodsForUser(userId: currentUser.uid)
            await MainActor.run {
                self.pods = userPods
                print("✅ Refreshed \(userPods.count) pods for user.")
            }
        } catch {
            await MainActor.run {
                print("❌ Error refreshing user pods: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Tab Button
struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? Color.accentGreen : Color.textSecondary)
                
                Rectangle()
                    .fill(isSelected ? Color.accentGreen : Color.clear)
                    .frame(height: 2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
    }
}

// MARK: - Pod Card
struct PodCard: View {
    let pod: IncubationProject
    @State private var showingPodDetail = false
    @State private var showingChat = false
    @State private var showingTasks = false
    @State private var showingInvite = false
    
    var body: some View {
        Button(action: { showingPodDetail = true }) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(pod.name)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color.textPrimary)
                            .lineLimit(1)
                        
                        Text(pod.description)
                            .font(.system(size: 14))
                            .foregroundColor(Color.textSecondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                                            ProjectStatusBadge(status: pod.status)
                }
                
                // Progress Section
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Progress".localized)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color.textPrimary)
                        
                        Spacer()
                        
                        Text("\(completedTasksCount)/\(pod.tasks.count) \("Tasks".localized)")
                            .font(.system(size: 12))
                            .foregroundColor(Color.textSecondary)
                    }
                    
                    ProgressView(value: progressValue)
                        .progressViewStyle(LinearProgressViewStyle(tint: Color.accentGreen))
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                }
                
                // Members Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Team (\(pod.members.count) \("Members".localized))")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.textPrimary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(pod.members.prefix(5), id: \.id) { member in
                                MemberAvatar(member: member)
                            }
                            
                            if pod.members.count > 5 {
                                Text("+\(pod.members.count - 5)")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Color.textSecondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.backgroundSecondary)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                
                // Quick Actions
                HStack(spacing: 16) {
                    QuickActionButton(
                        icon: "message",
                        title: "Chat".localized,
                        action: { showingChat = true }
                    )
                    
                    QuickActionButton(
                        icon: "checklist",
                        title: "Tasks".localized,
                        action: { showingTasks = true }
                    )
                    
                    QuickActionButton(
                        icon: "person.badge.plus",
                        title: "Invite".localized,
                        action: { showingInvite = true }
                    )
                    
                    Spacer()
                }
            }
            .padding(16)
            .background(Color.backgroundPrimary)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingPodDetail) {
            NavigationView {
                PodDetailView(pod: pod)
            }
        }
        .sheet(isPresented: $showingChat) {
            PodChatView(pod: pod)
        }
        .sheet(isPresented: $showingTasks) {
            NavigationView {
                PodDetailView(pod: pod)
            }
        }
        .sheet(isPresented: $showingInvite) {
            InviteMemberView(pod: pod)
        }
    }
    
    private var completedTasksCount: Int {
        pod.tasks.filter { $0.status == .completed }.count
    }
    
    private var progressValue: Double {
        guard !pod.tasks.isEmpty else { return 0 }
        return Double(completedTasksCount) / Double(pod.tasks.count)
    }
}

// MARK: - Pod Status Badge
struct ProjectStatusBadge: View {
    let status: IncubationProject.ProjectStatus
    
    var statusColor: Color {
        switch status {
        case .planning: return Color.accentOrange
        case .active: return Color.accentGreen
        case .completed: return Color.success
        case .onHold: return Color.textSecondary
        }
    }
    
    var body: some View {
        Text(status.rawValue.localized.capitalized)
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(Color.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor)
            .cornerRadius(8)
    }
}

// MARK: - Member Avatar
struct MemberAvatar: View {
    let member: ProjectMember
    
    var body: some View {
        VStack(spacing: 2) {
            Circle()
                .fill(Color.accentGreen)
                .frame(width: 32, height: 32)
                .overlay(
                    Text(String(member.username.prefix(1)).uppercased())
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                )
            
            Text(member.username)
                .font(.system(size: 10))
                .foregroundColor(Color.textSecondary)
                .lineLimit(1)
        }
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(Color.accentGreen)
                
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color.textSecondary)
            }
            .frame(width: 60)
        }
    }
}





// MARK: - Mock Data
let mockPods: [IncubationProject] = [
    IncubationProject(
        id: "1",
        ideaId: "idea1",
        name: "AI Study Assistant",
        description: "Building an intelligent app that helps students create personalized study plans and track progress.",
        creatorId: "user1",
        isPublic: true,
        createdAt: Date().addingTimeInterval(-86400),
        updatedAt: Date().addingTimeInterval(-3600),
        members: [
            ProjectMember(id: "1", userId: "user1", username: "AlexChen", role: "Lead Developer", joinedAt: Date().addingTimeInterval(-86400), permissions: [.admin]),
            ProjectMember(id: "2", userId: "user2", username: "SarahKim", role: "UI Designer", joinedAt: Date().addingTimeInterval(-7200), permissions: [.edit]),
            ProjectMember(id: "3", userId: "user3", username: "MarcusRodriguez", role: "Product Manager", joinedAt: Date().addingTimeInterval(-3600), permissions: [.edit])
        ],
        tasks: [
            ProjectTask(id: "1", title: "Design user interface", description: "Create wireframes and mockups", assignedTo: "user2", assignedToUsername: "SarahKim", dueDate: Date().addingTimeInterval(86400), createdAt: Date().addingTimeInterval(-86400), updatedAt: Date().addingTimeInterval(-86400), status: .completed, priority: .high),
            ProjectTask(id: "2", title: "Set up Supabase backend", description: "Configure authentication and database", assignedTo: "user1", assignedToUsername: "AlexChen", dueDate: Date().addingTimeInterval(172800), createdAt: Date().addingTimeInterval(-7200), updatedAt: Date().addingTimeInterval(-7200), status: .inProgress, priority: .high),
            ProjectTask(id: "3", title: "Create project roadmap", description: "Define milestones and timeline", assignedTo: "user3", assignedToUsername: "MarcusRodriguez", dueDate: Date().addingTimeInterval(259200), createdAt: Date().addingTimeInterval(-3600), updatedAt: Date().addingTimeInterval(-3600), status: .todo, priority: .medium)
        ],
        status: .active
    ),
    IncubationProject(
        id: "2",
        ideaId: "idea2",
        name: "Sustainable Food Network",
        description: "Connecting local farmers with consumers to reduce food waste and support sustainable agriculture.",
        creatorId: "user2",
        isPublic: true,
        createdAt: Date().addingTimeInterval(-172800),
        updatedAt: Date().addingTimeInterval(-7200),
        members: [
            ProjectMember(id: "4", userId: "user2", username: "SarahKim", role: "Project Lead", joinedAt: Date().addingTimeInterval(-172800), permissions: [.admin]),
            ProjectMember(id: "5", userId: "user4", username: "EmmaWilson", role: "Marketing Specialist", joinedAt: Date().addingTimeInterval(-86400), permissions: [.edit])
        ],
        tasks: [
            ProjectTask(id: "4", title: "Market research", description: "Analyze target audience and competitors", assignedTo: "user4", assignedToUsername: "EmmaWilson", dueDate: Date().addingTimeInterval(432000), createdAt: Date().addingTimeInterval(-86400), updatedAt: Date().addingTimeInterval(-86400), status: .todo, priority: .high),
            ProjectTask(id: "5", title: "Partner outreach", description: "Contact local farmers and grocery stores", assignedTo: "user2", assignedToUsername: "SarahKim", dueDate: Date().addingTimeInterval(518400), createdAt: Date().addingTimeInterval(-7200), updatedAt: Date().addingTimeInterval(-7200), status: .todo, priority: .medium)
        ],
        status: .planning
    )
]

// MARK: - Private Idea Card
struct PrivateIdeaCard: View {
    let idea: IdeaSpark

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title with Private badge
            HStack(alignment: .top, spacing: 8) {
                Text(idea.title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color.textPrimary)
                    .lineLimit(2)

                Text("Private".localized)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red)
                    .cornerRadius(6)
            }

            // Description
            Text(idea.description)
                .font(.system(size: 14))
                .foregroundColor(Color.textSecondary)
                .lineLimit(3)

            // Tags
            if !idea.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(idea.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color.accentGreen)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.accentGreen.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }
            }

            // Stats
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "heart")
                        .font(.system(size: 12))
                    Text("\(idea.likes)")
                        .font(.system(size: 12))
                }
                .foregroundColor(Color.textSecondary)

                Spacer()

                // Date
                Text(idea.createdAt, style: .date)
                    .font(.system(size: 12))
                    .foregroundColor(Color.textSecondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.backgroundPrimary)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

#Preview {
    MyPodsView()
        .environmentObject(LocalizationManager.shared)
        .environmentObject(SupabaseManager.shared)
} 
