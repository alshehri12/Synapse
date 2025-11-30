//
//  PodSettingsView.swift
//  Synapse
//
//  Created by Abdulrahman Alshehri on 18/01/1447 AH.
//

import SwiftUI
import Supabase

struct PodSettingsView: View {
    let pod: IncubationProject
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var supabaseManager: SupabaseManager
    @EnvironmentObject private var localizationManager: LocalizationManager
    
    @State private var podName = ""
    @State private var podDescription = ""
    @State private var isPublic = true
    @State private var showingDeleteAlert = false
    @State private var showingLeaveAlert = false
    @State private var isLoading = false
    @State private var showingEditName = false
    @State private var showingEditDescription = false
    @State private var showingInviteMember = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(isPodCreator ? "Pod Settings".localized : "Pod Information".localized)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color.textPrimary)
                        
                        Text(isPodCreator ? "Manage \(pod.name) settings".localized : "View \(pod.name) details".localized)
                            .font(.system(size: 16))
                            .foregroundColor(Color.textSecondary)
                    }
                    .padding(.horizontal, 20)
                    
                    if isPodCreator {
                        // Pod Owner View
                        PodOwnerSettingsView(
                            pod: pod,
                            podName: $podName,
                            podDescription: $podDescription,
                            isPublic: $isPublic,
                            showingEditName: $showingEditName,
                            showingEditDescription: $showingEditDescription,
                            showingDeleteAlert: $showingDeleteAlert,
                            showingLeaveAlert: $showingLeaveAlert,
                            onInvite: {
                                showingInviteMember = true
                            }
                        )
                    } else {
                        // Regular Member View
                        ProjectMemberView(
                            pod: pod,
                            showingLeaveAlert: $showingLeaveAlert
                        )
                    }
                }
                .padding(.vertical, 20)
            }
            .background(Color.backgroundSecondary)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(isPodCreator ? "Cancel".localized : "Done".localized) {
                        dismiss()
                    }
                }
                
                if isPodCreator && hasChanges {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save".localized) {
                            saveSettings()
                        }
                        .disabled(isLoading)
                    }
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
                                                deleteProject()
                }
            } message: {
                Text("This action cannot be undone. All data, tasks, and messages will be permanently deleted.".localized)
            }
            .sheet(isPresented: $showingEditName) {
                EditTextView(
                    title: "Edit Pod Name".localized,
                    text: $podName,
                    placeholder: "Pod name".localized,
                    maxLength: 50
                )
            }
            .sheet(isPresented: $showingEditDescription) {
                EditTextView(
                    title: "Edit Description".localized,
                    text: $podDescription,
                    placeholder: "Pod description".localized,
                    maxLength: 200,
                    isMultiline: true
                )
            }
            .sheet(isPresented: $showingInviteMember) {
                InviteMemberView(pod: pod)
            }
            .onAppear {
                loadSettings()
            }
        }
    }
    
    private var isPodCreator: Bool {
        pod.creatorId == supabaseManager.currentUser?.uid
    }
    
    private var hasChanges: Bool {
        podName != pod.name || podDescription != pod.description || isPublic != pod.isPublic
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
                    "updatedAt": Date()
                ]
                
                if podName != pod.name {
                    updateData["name"] = podName
                }
                
                if podDescription != pod.description {
                    updateData["description"] = podDescription
                }
                
                if isPublic != pod.isPublic {
                    updateData["isPublic"] = isPublic
                }
                
                if !updateData.isEmpty {
                    try await supabaseManager.updateProject(podId: pod.id, updates: updateData)
                    print("✅ Pod updated successfully: \(pod.id)")
                }
                
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    print("Error saving pod settings: \(error)")
                }
            }
        }
    }
    
    private func leavePod() {
        Task {
            do {
                let currentUserId = supabaseManager.currentUser?.uid ?? ""
                let updatedMembers = pod.members.filter { $0.userId != currentUserId }

                // Remove user from pod_members table
                try await supabaseManager.removePodMember(podId: pod.id, userId: currentUserId)
                print("✅ User removed from pod: \(pod.id)")

                await MainActor.run {
                    // Notify MyPodsView to refresh
                    NotificationCenter.default.post(name: .podMembershipChanged, object: nil)
                    dismiss()
                }
            } catch {
                print("Error leaving pod: \(error)")
            }
        }
    }
    
    private func deleteProject() {
        Task {
            do {
                try await supabaseManager.deleteProject(podId: pod.id)
                print("✅ Pod deleted successfully: \(pod.id)")
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                print("❌ Error deleting pod: \(error.localizedDescription)")
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
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                if showToggle {
                    Toggle("", isOn: .constant(isToggled))
                        .toggleStyle(SwitchToggleStyle(tint: Color.accentGreen))
                        .allowsHitTesting(false)
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

// MARK: - Info Card
struct InfoCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14))
                    .foregroundColor(Color.textSecondary)
                
                Text(value)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color.textPrimary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color.backgroundPrimary)
        .cornerRadius(12)
    }
}

// MARK: - Edit Text View
struct EditTextView: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let maxLength: Int
    let isMultiline: Bool
    
    @Environment(\.dismiss) private var dismiss
    
    init(title: String, text: Binding<String>, placeholder: String, maxLength: Int, isMultiline: Bool = false) {
        self.title = title
        self._text = text
        self.placeholder = placeholder
        self.maxLength = maxLength
        self.isMultiline = isMultiline
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if isMultiline {
                    TextEditor(text: $text)
                        .padding(12)
                        .background(Color.backgroundSecondary)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.textSecondary.opacity(0.2), lineWidth: 1)
                        )
                        .frame(minHeight: 120)
                } else {
                    TextField(placeholder, text: $text)
                        .textFieldStyle(CustomTextFieldStyle())
                }
                
                HStack {
                    Spacer()
                    Text("\(text.count)/\(maxLength)")
                        .font(.system(size: 12))
                        .foregroundColor(text.count > maxLength ? Color.error : Color.textSecondary)
                }
                
                Spacer()
            }
            .padding(20)
            .background(Color.backgroundSecondary)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel".localized) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save".localized) {
                        dismiss()
                    }
                    .disabled(text.count > maxLength || text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

// MARK: - Pod Owner Settings View
struct PodOwnerSettingsView: View {
    let pod: IncubationProject
    @Binding var podName: String
    @Binding var podDescription: String
    @Binding var isPublic: Bool
    @Binding var showingEditName: Bool
    @Binding var showingEditDescription: Bool
    @Binding var showingDeleteAlert: Bool
    @Binding var showingLeaveAlert: Bool
    let onInvite: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Basic Settings
            VStack(alignment: .leading, spacing: 16) {
                Text("Pod Settings".localized)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color.textPrimary)
                    .padding(.horizontal, 20)
                
                VStack(spacing: 0) {
                    SettingRow(
                        title: "Pod Name".localized,
                        subtitle: podName.isEmpty ? pod.name : podName,
                        icon: "pencil",
                        action: { showingEditName = true }
                    )
                    
                    Divider()
                        .padding(.leading, 56)
                    
                    SettingRow(
                        title: "Description".localized,
                        subtitle: podDescription.isEmpty ? pod.description : podDescription,
                        icon: "text.quote",
                        action: { showingEditDescription = true }
                    )
                    
                    Divider()
                        .padding(.leading, 56)
                    
                    SettingRow(
                        title: "Privacy".localized,
                        subtitle: isPublic ? "Public - Anyone can find and join".localized : "Private - Invite only".localized,
                        icon: "lock",
                        action: { isPublic.toggle() },
                        showToggle: true,
                        isToggled: isPublic
                    )
                }
                .background(Color.backgroundPrimary)
                .cornerRadius(12)
                .padding(.horizontal, 20)
            }
            
            // Invite Members
            VStack(alignment: .leading, spacing: 16) {
                Text("Collaboration".localized)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color.textPrimary)
                    .padding(.horizontal, 20)
                
                VStack(spacing: 0) {
                    SettingRow(
                        title: "Invite Members".localized,
                        subtitle: "Add new members to this pod".localized,
                        icon: "person.badge.plus",
                        action: onInvite
                    )
                }
                .background(Color.backgroundPrimary)
                .cornerRadius(12)
                .padding(.horizontal, 20)
            }
            
            // Pod Information
            PodInformationSection(pod: pod)
            
            // Actions
            VStack(alignment: .leading, spacing: 16) {
                Text("Actions".localized)
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
                .background(Color.backgroundPrimary)
                .cornerRadius(12)
                .padding(.horizontal, 20)
            }
        }
    }
}

// MARK: - Pod Member View
struct ProjectMemberView: View {
    let pod: IncubationProject
    @Binding var showingLeaveAlert: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Pod Information
            PodInformationSection(pod: pod)
            
            // Member Actions
            VStack(alignment: .leading, spacing: 16) {
                Text("Actions".localized)
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
                }
                .background(Color.backgroundPrimary)
                .cornerRadius(12)
                .padding(.horizontal, 20)
            }
            
            // Additional Info for Members
            VStack(alignment: .leading, spacing: 16) {
                Text("Note".localized)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color.textPrimary)
                    .padding(.horizontal, 20)
                
                Text("Only the pod creator can modify settings. You can participate in tasks, chat, and collaborate on this pod.".localized)
                    .font(.system(size: 14))
                    .foregroundColor(Color.textSecondary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Color.backgroundPrimary)
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
            }
        }
    }
}

// MARK: - Pod Information Section
struct PodInformationSection: View {
    let pod: IncubationProject
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Pod Information".localized)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color.textPrimary)
                .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                InfoCard(
                    title: "Members".localized,
                    value: "\(pod.members.count)",
                    icon: "person.3",
                    color: Color.accentGreen
                )
                
                InfoCard(
                    title: "Tasks".localized,
                    value: "\(pod.tasks.count)",
                    icon: "checklist",
                    color: Color.accentBlue
                )
                
                InfoCard(
                    title: "Created".localized,
                    value: pod.createdAt.formatted(date: .abbreviated, time: .omitted),
                    icon: "calendar",
                    color: Color.accentOrange
                )
                
                InfoCard(
                    title: "Status".localized,
                    value: pod.status.rawValue.capitalized.localized,
                    icon: "circle.fill",
                    color: statusColor(for: pod.status)
                )
                
                InfoCard(
                    title: "Privacy".localized,
                    value: pod.isPublic ? "Public".localized : "Private".localized,
                    icon: pod.isPublic ? "globe" : "lock",
                    color: pod.isPublic ? Color.accentGreen : Color.accentOrange
                )
            }
            .padding(.horizontal, 20)
        }
    }
    
    private func statusColor(for status: IncubationProject.ProjectStatus) -> Color {
        switch status {
        case .planning: return Color.accentOrange
        case .active: return Color.accentGreen
        case .completed: return Color.accentBlue
        case .onHold: return Color.textSecondary
        }
    }
}

#Preview {
    PodSettingsView(pod: mockPods[0])
        .environmentObject(LocalizationManager.shared)
        .environmentObject(SupabaseManager.shared)
} 