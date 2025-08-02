//
//  MyPodsView.swift
//  Synapse
//
//  Created by Abdulrahman Alshehri on 18/01/1447 AH.
//

import SwiftUI
import FirebaseFirestore

struct MyPodsView: View {
    @State private var selectedTab = 0
    @State private var pods: [IncubationPod] = []
    @State private var isLoading = false
    @State private var showingCreatePod = false
    @EnvironmentObject private var localizationManager: LocalizationManager
    @EnvironmentObject private var firebaseManager: FirebaseManager
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
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
                
                // Pods List
                if isLoading {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color.accentGreen))
                        .scaleEffect(1.2)
                    Spacer()
                } else if filteredPods.isEmpty {
                    EmptyStateView(
                        icon: "person.3",
                        title: "No pods found".localized,
                        message: selectedTab == 0 ? "Join a pod to start collaborating!".localized : "No pods in this category".localized
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredPods) { pod in
                                PodCard(pod: pod)
                                    .padding(.horizontal, 20)
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
            .navigationTitle("My Pods".localized)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreatePod = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color.accentGreen)
                    }
                }
            }
            .sheet(isPresented: $showingCreatePod) {
                CreatePodView()
            }
            .onAppear {
                loadPods()
            }
        }
    }
    
    var filteredPods: [IncubationPod] {
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
        guard let currentUser = firebaseManager.currentUser else { 
            print("❌ No current user found")
            return 
        }
        
        print("🔄 Loading pods for user: \(currentUser.uid)")
        isLoading = true
        
        Task {
            do {
                let podData = try await firebaseManager.getUserPods(userId: currentUser.uid)
                print("📊 Found \(podData.count) pods in database")
                
                await MainActor.run {
                    pods = podData
                    isLoading = false
                }
            } catch {
                print("❌ Error loading pods: \(error)")
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
    
    @MainActor
    private func refreshPods() async {
        print("🔄 Manual refresh triggered")
        loadPods()
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
    let pod: IncubationPod
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
                    
                    PodStatusBadge(status: pod.status)
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
            PodDetailView(pod: pod)
        }
        .sheet(isPresented: $showingChat) {
            PodChatView(pod: pod)
        }
        .sheet(isPresented: $showingTasks) {
            PodDetailView(pod: pod)
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
struct PodStatusBadge: View {
    let status: IncubationPod.PodStatus
    
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
    let member: PodMember
    
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
let mockPods: [IncubationPod] = [
    IncubationPod(
        id: "1",
        ideaId: "idea1",
        name: "AI Study Assistant",
        description: "Building an intelligent app that helps students create personalized study plans and track progress.",
        creatorId: "user1",
        isPublic: true,
        createdAt: Date().addingTimeInterval(-86400),
        updatedAt: Date().addingTimeInterval(-3600),
        members: [
            PodMember(id: "1", userId: "user1", username: "AlexChen", role: "Lead Developer", joinedAt: Date().addingTimeInterval(-86400), permissions: [.admin]),
            PodMember(id: "2", userId: "user2", username: "SarahKim", role: "UI Designer", joinedAt: Date().addingTimeInterval(-7200), permissions: [.edit]),
            PodMember(id: "3", userId: "user3", username: "MarcusRodriguez", role: "Product Manager", joinedAt: Date().addingTimeInterval(-3600), permissions: [.edit])
        ],
        tasks: [
            PodTask(id: "1", title: "Design user interface", description: "Create wireframes and mockups", assignedTo: "user2", assignedToUsername: "SarahKim", dueDate: Date().addingTimeInterval(86400), createdAt: Date().addingTimeInterval(-86400), updatedAt: Date().addingTimeInterval(-86400), status: .completed, priority: .high),
            PodTask(id: "2", title: "Set up Firebase backend", description: "Configure authentication and database", assignedTo: "user1", assignedToUsername: "AlexChen", dueDate: Date().addingTimeInterval(172800), createdAt: Date().addingTimeInterval(-7200), updatedAt: Date().addingTimeInterval(-7200), status: .inProgress, priority: .high),
            PodTask(id: "3", title: "Create project roadmap", description: "Define milestones and timeline", assignedTo: "user3", assignedToUsername: "MarcusRodriguez", dueDate: Date().addingTimeInterval(259200), createdAt: Date().addingTimeInterval(-3600), updatedAt: Date().addingTimeInterval(-3600), status: .todo, priority: .medium)
        ],
        status: .active
    ),
    IncubationPod(
        id: "2",
        ideaId: "idea2",
        name: "Sustainable Food Network",
        description: "Connecting local farmers with consumers to reduce food waste and support sustainable agriculture.",
        creatorId: "user2",
        isPublic: true,
        createdAt: Date().addingTimeInterval(-172800),
        updatedAt: Date().addingTimeInterval(-7200),
        members: [
            PodMember(id: "4", userId: "user2", username: "SarahKim", role: "Project Lead", joinedAt: Date().addingTimeInterval(-172800), permissions: [.admin]),
            PodMember(id: "5", userId: "user4", username: "EmmaWilson", role: "Marketing Specialist", joinedAt: Date().addingTimeInterval(-86400), permissions: [.edit])
        ],
        tasks: [
            PodTask(id: "4", title: "Market research", description: "Analyze target audience and competitors", assignedTo: "user4", assignedToUsername: "EmmaWilson", dueDate: Date().addingTimeInterval(432000), createdAt: Date().addingTimeInterval(-86400), updatedAt: Date().addingTimeInterval(-86400), status: .todo, priority: .high),
            PodTask(id: "5", title: "Partner outreach", description: "Contact local farmers and grocery stores", assignedTo: "user2", assignedToUsername: "SarahKim", dueDate: Date().addingTimeInterval(518400), createdAt: Date().addingTimeInterval(-7200), updatedAt: Date().addingTimeInterval(-7200), status: .todo, priority: .medium)
        ],
        status: .planning
    )
]

#Preview {
    MyPodsView()
        .environmentObject(LocalizationManager.shared)
        .environmentObject(FirebaseManager.shared)
} 
