//
//  PodSettingsView.swift
//  Synapse
//
//  Created by Abdulrahman Alshehri on 18/01/1447 AH.
//

import SwiftUI
import FirebaseFirestore

struct PodSettingsView: View {
    let pod: IncubationPod
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var firebaseManager: FirebaseManager
    @EnvironmentObject private var localizationManager: LocalizationManager
    
    @State private var podName = ""
    @State private var podDescription = ""
    @State private var isPublic = true
    @State private var showingDeleteAlert = false
    @State private var showingLeaveAlert = false
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Pod Settings".localized)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color.textPrimary)
                        
                        Text("Manage \(pod.name) settings and permissions".localized)
                            .font(.system(size: 16))
                            .foregroundColor(Color.textSecondary)
                    }
                    .padding(.horizontal, 20)
                    
                    // General Settings
                    VStack(alignment: .leading, spacing: 16) {
                        Text("General".localized)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color.textPrimary)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 0) {
                            SettingRow(
                                title: "Pod Name".localized,
                                subtitle: pod.name,
                                icon: "pencil",
                                action: {}
                            )
                            
                            Divider()
                                .padding(.leading, 56)
                            
                            SettingRow(
                                title: "Description".localized,
                                subtitle: pod.description,
                                icon: "text.quote",
                                action: {}
                            )
                            
                            Divider()
                                .padding(.leading, 56)
                            
                            SettingRow(
                                title: "Privacy".localized,
                                subtitle: pod.isPublic ? "Public".localized : "Private".localized,
                                icon: "lock",
                                action: {}
                            )
                        }
                        .background(Color.backgroundPrimary)
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                    }
                    
                    // Permissions
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Permissions".localized)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color.textPrimary)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 0) {
                            SettingRow(
                                title: "Member Permissions".localized,
                                subtitle: "Manage who can edit and invite".localized,
                                icon: "person.2",
                                action: {}
                            )
                            
                            Divider()
                                .padding(.leading, 56)
                            
                            SettingRow(
                                title: "Task Management".localized,
                                subtitle: "Control task creation and assignment".localized,
                                icon: "checklist",
                                action: {}
                            )
                            
                            Divider()
                                .padding(.leading, 56)
                            
                            SettingRow(
                                title: "Chat Settings".localized,
                                subtitle: "Manage chat permissions and moderation".localized,
                                icon: "message",
                                action: {}
                            )
                        }
                        .background(Color.backgroundPrimary)
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                    }
                    
                    // Notifications
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Notifications".localized)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color.textPrimary)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 0) {
                            SettingRow(
                                title: "New Messages".localized,
                                subtitle: "Get notified of new chat messages".localized,
                                icon: "bell",
                                action: {},
                                showToggle: true,
                                isToggled: true
                            )
                            
                            Divider()
                                .padding(.leading, 56)
                            
                            SettingRow(
                                title: "Task Updates".localized,
                                subtitle: "Notifications for task changes".localized,
                                icon: "checkmark.circle",
                                action: {},
                                showToggle: true,
                                isToggled: true
                            )
                            
                            Divider()
                                .padding(.leading, 56)
                            
                            SettingRow(
                                title: "Member Activity".localized,
                                subtitle: "When members join or leave".localized,
                                icon: "person.badge.plus",
                                action: {},
                                showToggle: true,
                                isToggled: false
                            )
                        }
                        .background(Color.backgroundPrimary)
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                    }
                    
                    // Danger Zone
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Danger Zone".localized)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color.error)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 0) {
                            SettingRow(
                                title: "Leave Pod".localized,
                                subtitle: "Remove yourself from this pod".localized,
                                icon: "person.fill.xmark",
                                action: { showingLeaveAlert = true },
                                isDestructive: true
                            )
                            
                            if isPodCreator {
                                Divider()
                                    .padding(.leading, 56)
                                
                                SettingRow(
                                    title: "Delete Pod".localized,
                                    subtitle: "Permanently delete this pod and all its data".localized,
                                    icon: "trash",
                                    action: { showingDeleteAlert = true },
                                    isDestructive: true
                                )
                            }
                        }
                        .background(Color.backgroundPrimary)
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.vertical, 20)
            }
            .background(Color.backgroundSecondary)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel".localized) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save".localized) {
                        saveSettings()
                    }
                    .disabled(isLoading)
                }
            }
            .alert("Leave Pod".localized, isPresented: $showingLeaveAlert) {
                Button("Cancel".localized, role: .cancel) { }
                Button("Leave".localized, role: .destructive) {
                    leavePod()
                }
            } message: {
                Text("Are you sure you want to leave this pod? You won't be able to access it anymore unless you're invited back.".localized)
            }
            .alert("Delete Pod".localized, isPresented: $showingDeleteAlert) {
                Button("Cancel".localized, role: .cancel) { }
                Button("Delete".localized, role: .destructive) {
                    deletePod()
                }
            } message: {
                Text("This action cannot be undone. All data, tasks, and messages will be permanently deleted.".localized)
            }
            .onAppear {
                loadSettings()
            }
        }
    }
    
    private var isPodCreator: Bool {
        pod.creatorId == firebaseManager.currentUser?.uid
    }
    
    private func loadSettings() {
        podName = pod.name
        podDescription = pod.description
        isPublic = pod.isPublic
    }
    
    private func saveSettings() {
        isLoading = true
        
        Task {
            do {
                var updateData: [String: Any] = [
                    "name": podName,
                    "description": podDescription,
                    "isPublic": isPublic,
                    "updatedAt": Timestamp(date: Date())
                ]
                
                try await firebaseManager.updatePod(podId: pod.id, data: updateData)
                
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    // Handle error - you could show an alert here
                    print("Error saving pod settings: \(error)")
                }
            }
        }
    }
    
    private func leavePod() {
        Task {
            do {
                // Remove current user from pod members
                let currentUserId = firebaseManager.currentUser?.uid ?? ""
                var updatedMembers = pod.members.filter { $0.userId != currentUserId }
                
                try await firebaseManager.updatePod(podId: pod.id, data: [
                    "members": updatedMembers.map { member in
                        [
                            "id": member.id,
                            "userId": member.userId,
                            "username": member.username,
                            "role": member.role,
                            "joinedAt": Timestamp(date: member.joinedAt),
                            "permissions": member.permissions.map { $0.rawValue }
                        ]
                    }
                ])
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                // Handle error
            }
        }
    }
    
    private func deletePod() {
        Task {
            do {
                try await firebaseManager.deletePod(podId: pod.id)
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                // Handle error
            }
        }
    }
}

// MARK: - Setting Row
struct SettingRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let action: () -> Void
    var showToggle: Bool = false
    var isToggled: Bool = false
    var isDestructive: Bool = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(isDestructive ? Color.error : Color.accentGreen)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isDestructive ? Color.error : Color.textPrimary)
                    
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(Color.textSecondary)
                }
                
                Spacer()
                
                if showToggle {
                    Toggle("", isOn: .constant(isToggled))
                        .toggleStyle(SwitchToggleStyle(tint: Color.accentGreen))
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.textSecondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    PodSettingsView(pod: mockPods[0])
        .environmentObject(LocalizationManager.shared)
        .environmentObject(FirebaseManager.shared)
} 