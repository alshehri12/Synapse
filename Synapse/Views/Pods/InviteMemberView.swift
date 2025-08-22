//
//  InviteMemberView.swift
//  Synapse
//
//  Created by Abdulrahman Alshehri on 18/01/1447 AH.
//

import SwiftUI
import Supabase

struct InviteMemberView: View {
    let pod: IncubationProject
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var supabaseManager: SupabaseManager
    @EnvironmentObject private var localizationManager: LocalizationManager
    
    @State private var searchText = ""
    @State private var selectedUsers: [UserProfile] = []
    @State private var selectedRole = "Member"
    @State private var customMessage = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showingError = false
    
    // Mock users for demonstration
    @State private var availableUsers: [UserProfile] = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Invite Members".localized)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color.textPrimary)
                    
                    Text("Invite people to join \(pod.name)".localized)
                        .font(.system(size: 16))
                        .foregroundColor(Color.textSecondary)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Color.textSecondary)
                    
                    TextField("Search users".localized, text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding(12)
                .background(Color.backgroundPrimary)
                .cornerRadius(12)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                
                // Selected Users
                if !selectedUsers.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Selected (\(selectedUsers.count))".localized)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.textPrimary)
                            .padding(.horizontal, 20)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(selectedUsers) { user in
                                    SelectedUserCard(
                                        user: user,
                                        onRemove: { removeUser(user) }
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, 16)
                }
                
                // Role Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Role".localized)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.textPrimary)
                        .padding(.horizontal, 20)
                    
                    HStack(spacing: 12) {
                        ForEach(["Member", "Contributor", "Admin"], id: \.self) { role in
                            RoleOption(
                                role: role,
                                isSelected: selectedRole == role,
                                action: { selectedRole = role }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 16)
                
                // Custom Message
                VStack(alignment: .leading, spacing: 8) {
                    Text("Invitation Message (Optional)".localized)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.textPrimary)
                        .padding(.horizontal, 20)
                    
                    TextEditor(text: $customMessage)
                        .frame(minHeight: 80)
                        .padding(12)
                        .background(Color.backgroundPrimary)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.border, lineWidth: 1)
                        )
                        .padding(.horizontal, 20)
                }
                .padding(.bottom, 16)
                
                // Users List
                if filteredUsers.isEmpty {
                    EmptyStateView(
                        icon: "person.3",
                        title: "No users found".localized,
                        message: searchText.isEmpty ? "No users available to invite".localized : "No users match your search".localized
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredUsers) { user in
                                UserCard(
                                    user: user,
                                    isSelected: selectedUsers.contains { $0.id == user.id },
                                    action: { toggleUser(user) }
                                )
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding(.vertical, 16)
                    }
                }
                
                Spacer()
                
                // Invite Button
                Button(action: sendInvites) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Text("Send Invites (\(selectedUsers.count))".localized)
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(selectedUsers.isEmpty ? Color.textSecondary : Color.accentGreen)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(selectedUsers.isEmpty || isLoading)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
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
            .alert("Error".localized, isPresented: $showingError) {
                Button("OK".localized) { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                loadAvailableUsers()
            }
        }
    }
    
    private var filteredUsers: [UserProfile] {
        let currentMemberIds = Set(pod.members.map { $0.userId })
        let availableUsers = availableUsers.filter { !currentMemberIds.contains($0.id) }
        
        if searchText.isEmpty {
            return availableUsers
        } else {
            return availableUsers.filter { user in
                user.username.localizedCaseInsensitiveContains(searchText) ||
                user.email.localizedCaseInsensitiveContains(searchText) ||
                user.skills.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
    }
    
    private func loadAvailableUsers() {
        Task {
            do {
                // TODO: Implement getAllUsers in SupabaseManager
                let userData: [UserProfile] = []
                
                await MainActor.run {
                    availableUsers = userData
                }
            } catch {
                // Handle error
            }
        }
    }
    
    private func toggleUser(_ user: UserProfile) {
        if let index = selectedUsers.firstIndex(where: { $0.id == user.id }) {
            selectedUsers.remove(at: index)
        } else {
            selectedUsers.append(user)
        }
    }
    
    private func removeUser(_ user: UserProfile) {
        selectedUsers.removeAll { $0.id == user.id }
    }
    
    private func sendInvites() {
        guard !selectedUsers.isEmpty else { return }
        
        isLoading = true
        
        Task {
            do {
                for user in selectedUsers {
                                    // TODO: Implement inviteUserToProject in SupabaseManager
                                    print("✅ Invite user to project requested: \(user.id) to \(pod.name)")
                }
                
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Selected User Card
struct SelectedUserCard: View {
    let user: UserProfile
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            // Avatar
            Circle()
                .fill(Color.accentGreen)
                .frame(width: 24, height: 24)
                .overlay(
                    Text(String(user.username.prefix(1)).uppercased())
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white)
                )
            
            // Username
            Text(user.username)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.textPrimary)
            
            // Remove Button
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color.textSecondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.accentGreen.opacity(0.1))
        .cornerRadius(20)
    }
}

// MARK: - User Card
struct UserCard: View {
    let user: UserProfile
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Selection Indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? Color.accentGreen : Color.textSecondary)
                
                // Avatar
                Circle()
                    .fill(Color.accentGreen)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(String(user.username.prefix(1)).uppercased())
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    )
                
                // User Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.username)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.textPrimary)
                    
                    Text(user.email)
                        .font(.system(size: 14))
                        .foregroundColor(Color.textSecondary)
                    
                    if !user.skills.isEmpty {
                        Text(user.skills.prefix(3).joined(separator: ", "))
                            .font(.system(size: 12))
                            .foregroundColor(Color.accentGreen)
                    }
                }
                
                Spacer()
            }
            .padding(16)
            .background(isSelected ? Color.accentGreen.opacity(0.1) : Color.backgroundPrimary)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentGreen : Color.border, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Role Option
struct RoleOption: View {
    let role: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(role.localized)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? Color.white : Color.textSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentGreen : Color.backgroundPrimary)
                .cornerRadius(20)
        }
    }
}

// MARK: - Mock Available Users
let mockAvailableUsers: [UserProfile] = [
    UserProfile(
        id: "user4",
        username: "EmmaWilson",
        email: "emma.wilson@example.com",
        bio: "UX Designer passionate about creating intuitive user experiences",
        avatarURL: nil,
        skills: ["UI/UX Design", "Figma", "Prototyping", "User Research"],
        interests: ["Design", "Technology", "Innovation"],
        ideasSparked: 2,
        projectsContributed: 5,
        dateJoined: Date().addingTimeInterval(-604800)
    ),
    UserProfile(
        id: "user5",
        username: "DavidLee",
        email: "david.lee@example.com",
        bio: "Backend developer with expertise in scalable systems",
        avatarURL: nil,
        skills: ["Python", "Django", "PostgreSQL", "AWS"],
        interests: ["Backend Development", "Cloud Computing", "System Architecture"],
        ideasSparked: 1,
        projectsContributed: 3,
        dateJoined: Date().addingTimeInterval(-1209600)
    ),
    UserProfile(
        id: "user6",
        username: "LisaChen",
        email: "lisa.chen@example.com",
        bio: "Marketing specialist with a focus on digital growth",
        avatarURL: nil,
        skills: ["Digital Marketing", "SEO", "Social Media", "Analytics"],
        interests: ["Marketing", "Growth", "Data Analysis"],
        ideasSparked: 4,
        projectsContributed: 8,
        dateJoined: Date().addingTimeInterval(-2592000)
    )
]

#Preview {
    InviteMemberView(pod: mockPods[0])
        .environmentObject(LocalizationManager.shared)
        .environmentObject(SupabaseManager.shared)
} 
