//
//  ProfileView.swift
//  Synapse
//
//  Created by Abdulrahman Alshehri on 18/01/1447 AH.
//

import SwiftUI
import Supabase

struct ProfileView: View {
    @State private var user: UserProfile?
    @State private var isLoading = false
    @State private var showingEditProfile = false
    @State private var showingSettings = false
    @EnvironmentObject private var localizationManager: LocalizationManager
    @EnvironmentObject private var supabaseManager: SupabaseManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color.accentGreen))
                            .scaleEffect(1.2)
                            .frame(height: 200)
                    } else if let user = user {
                        ProfileHeader(user: user) {
                            showingEditProfile = true
                        }
                    }
                    
                    // Stats Section
                    if let user = user {
                        StatsSection(user: user)
                    }
                    
                    // Skills & Interests
                    if let user = user {
                        SkillsInterestsSection(user: user)
                    }
                    
                    // Menu Items
                    MenuSection()
                }
                .padding(.vertical, 20)
            }
            .background(Color.backgroundSecondary)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 18))
                            .foregroundColor(Color.accentGreen)
                    }
                }
            }
            .onAppear {
                loadUserProfile()
            }
            .onChange(of: supabaseManager.currentUser) { _, user in
                if user != nil {
                    loadUserProfile()
                }
            }
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView(user: user ?? mockUser)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }
    
    private func signOut() async {
        do {
            try await supabaseManager.signOut()
        } catch {
            // Error is handled by SupabaseManager
        }
    }
    
    private func loadUserProfile() {
        guard let currentUser = supabaseManager.currentUser else { return }
        
        isLoading = true
        
        Task {
            do {
                // First, update user stats with real data
                try await supabaseManager.updateUserStats(userId: currentUser.id.uuidString)
                
                if let userData = try await supabaseManager.getUserProfile(userId: currentUser.id.uuidString) {
                    // Convert Firestore data to User model
                    let username = userData["username"] as? String ?? ""
                    let email = userData["email"] as? String ?? ""
                    let bio = userData["bio"] as? String
                    let avatarURL = userData["avatarURL"] as? String
                    let skills = userData["skills"] as? [String] ?? []
                    let interests = userData["interests"] as? [String] ?? []
                    let ideasSparked = userData["ideasSparked"] as? Int ?? 0
                    let projectsContributed = userData["projectsContributed"] as? Int ?? 0
                    let dateJoined = userData["dateJoined"] as? Date ?? Date()
                    
                    await MainActor.run {
                        user = UserProfile(
                            id: currentUser.id.uuidString,
                            username: username,
                            email: email,
                            bio: bio,
                            avatarURL: avatarURL,
                            skills: skills,
                            interests: interests,
                            ideasSparked: ideasSparked,
                            projectsContributed: projectsContributed,
                            dateJoined: dateJoined
                        )
                        isLoading = false
                    }
                } else {
                    await MainActor.run {
                        isLoading = false
                    }
                }
            } catch {
                print("Error loading user profile: \(error)")
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Profile Header
struct ProfileHeader: View {
    let user: UserProfile
    let onEdit: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Avatar and Basic Info
            VStack(spacing: 12) {
                // Avatar
                Circle()
                    .fill(Color.accentGreen)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Text(String(user.username.prefix(1)).uppercased())
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                    )
                
                // Name and Username
                VStack(spacing: 4) {
                    Text(user.username)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color.textPrimary)
                    
                    Text(user.email)
                        .font(.system(size: 14))
                        .foregroundColor(Color.textSecondary)
                }
                
                // Bio
                if let bio = user.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.system(size: 16))
                        .foregroundColor(Color.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                // Edit Button
                Button(action: onEdit) {
                    Text("Edit Profile".localized)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.accentGreen)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.accentGreen.opacity(0.1))
                        .cornerRadius(20)
                }
            }
            
            // Join Date
            Text("\("Member since".localized) \(user.dateJoined, style: .date)")
                .font(.system(size: 12))
                .foregroundColor(Color.textSecondary)
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Stats Section
struct StatsSection: View {
    let user: UserProfile
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Impact".localized)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color.textPrimary)
                .padding(.horizontal, 20)
            
            HStack(spacing: 16) {
                StatCard(
                    title: "Ideas Sparked".localized,
                    value: "\(user.ideasSparked)",
                    icon: "sparkles",
                    color: Color.accentOrange
                )
                
                StatCard(
                    title: "Projects Contributed".localized,
                    value: "\(user.projectsContributed)",
                    icon: "person.3",
                    color: Color.accentGreen
                )
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Skills & Interests Section
struct SkillsInterestsSection: View {
    let user: UserProfile
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Skills & Interests".localized)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color.textPrimary)
                .padding(.horizontal, 20)
            
            VStack(spacing: 16) {
                // Skills
                if !user.skills.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Skills".localized)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color.textPrimary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(user.skills, id: \.self) { skill in
                                    Text(skill)
                                        .font(.system(size: 12, weight: .medium))
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
                
                // Interests
                if !user.interests.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Interests")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color.textPrimary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(user.interests, id: \.self) { interest in
                                    Text(interest)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(Color.accentBlue)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.accentBlue.opacity(0.1))
                                        .cornerRadius(12)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Menu Section  
struct MenuSection: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Quick Access")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
            
            Text("Visit the Explore tab to view your ideas, or My Pods to see your collaborations.")
                .font(.system(size: 14))
                .foregroundColor(Color.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.backgroundPrimary)
                .cornerRadius(12)
                .padding(.horizontal, 20)
        }
    }
}

// MARK: - Menu Row
struct MenuRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(Color.accentGreen)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.textPrimary)
                    
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(Color.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(Color.textSecondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Edit Profile View
struct EditProfileView: View {
    let user: UserProfile
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var supabaseManager: SupabaseManager
    @State private var username: String
    @State private var bio: String
    @State private var skills: [String]
    @State private var interests: [String]
    @State private var newSkill = ""
    @State private var newInterest = ""
    @State private var isSaving = false
    
    init(user: UserProfile) {
        self.user = user
        self._username = State(initialValue: user.username)
        self._bio = State(initialValue: user.bio ?? "")
        self._skills = State(initialValue: user.skills)
        self._interests = State(initialValue: user.interests)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Avatar Section
                    VStack(spacing: 16) {
                        Circle()
                            .fill(Color.accentGreen)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Text(String(username.prefix(1)).uppercased())
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.white)
                            )
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)
                    
                    // Username
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Username")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.textPrimary)
                        
                        TextField("Username", text: $username)
                            .textFieldStyle(CustomTextFieldStyle())
                    }
                    .padding(.horizontal, 20)
                    
                    // Bio
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Bio")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.textPrimary)
                        
                        TextEditor(text: $bio)
                            .frame(minHeight: 100)
                            .padding(12)
                            .background(Color.backgroundSecondary)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.textSecondary.opacity(0.2), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 20)
                    
                    // Skills
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Skills")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.textPrimary)
                        
                        // Add Skill Input
                        HStack {
                            TextField("Add a skill...".localized, text: $newSkill)
                                .textFieldStyle(CustomTextFieldStyle())
                            
                            Button(action: addSkill) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(Color.accentGreen)
                            }
                            .disabled(newSkill.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                        
                        // Skills Display
                        if !skills.isEmpty {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                                ForEach(skills, id: \.self) { skill in
                                    TagView(tag: skill) {
                                        removeSkill(skill)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Interests
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Interests".localized)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.textPrimary)
                        
                        // Add Interest Input
                        HStack {
                            TextField("Add an interest...".localized, text: $newInterest)
                                .textFieldStyle(CustomTextFieldStyle())
                            
                            Button(action: addInterest) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(Color.accentBlue)
                            }
                            .disabled(newInterest.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                        
                        // Interests Display
                        if !interests.isEmpty {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                                ForEach(interests, id: \.self) { interest in
                                    InterestTagView(interest: interest) {
                                        removeInterest(interest)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 40)
            }
            .background(Color.backgroundSecondary)
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel".localized) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save".localized) {
                        saveProfile()
                    }
                    .disabled(isSaving)
                }
            }

        }
    }
    

    
    private func addSkill() {
        let trimmedSkill = newSkill.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedSkill.isEmpty && !skills.contains(trimmedSkill) {
            skills.append(trimmedSkill)
            newSkill = ""
        }
    }
    
    private func removeSkill(_ skill: String) {
        skills.removeAll { $0 == skill }
    }
    
    private func addInterest() {
        let trimmedInterest = newInterest.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedInterest.isEmpty && !interests.contains(trimmedInterest) {
            interests.append(trimmedInterest)
            newInterest = ""
        }
    }
    
    private func removeInterest(_ interest: String) {
        interests.removeAll { $0 == interest }
    }
    
    private func saveProfile() {
        guard let currentUser = supabaseManager.currentUser else { return }
        
        isSaving = true
        
        Task {
            do {
                try await supabaseManager.updateUserProfile(userId: currentUser.id.uuidString, updates: [
                    "username": username,
                    "bio": bio,
                    "skills": skills,
                    "interests": interests
                ])
                
                await MainActor.run {
                    isSaving = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                }
            }
        }
    }
}

// MARK: - Interest Tag View
struct InterestTagView: View {
    let interest: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            Text(interest)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.accentBlue)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(Color.textSecondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.accentBlue.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var localizationManager: LocalizationManager
    @EnvironmentObject private var supabaseManager: SupabaseManager
    @State private var showingLanguageSelector = false
    
    private func signOut() async {
        do {
            try await supabaseManager.signOut()
        } catch {
            // Error is handled by SupabaseManager
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                Section("Account".localized) {
                    SettingsRow(icon: "person", title: "Account Settings".localized, action: {})
                    SettingsRow(icon: "bell", title: "Notifications".localized, action: {})
                    SettingsRow(icon: "lock", title: "Privacy".localized, action: {})
                }
                
                Section("App".localized) {
                    SettingsRow(icon: "globe", title: "Language".localized, action: { showingLanguageSelector = true })
                    SettingsRow(icon: "questionmark.circle", title: "Help & Support".localized, action: {})
                    SettingsRow(icon: "doc.text", title: "Terms of Service".localized, action: {})
                    SettingsRow(icon: "hand.raised", title: "Privacy Policy".localized, action: {})
                }
                
                Section {
                    SettingsRow(icon: "arrow.right.square", title: "Sign Out".localized, action: {
                        Task {
                            await signOut()
                            dismiss()
                        }
                    })
                        .foregroundColor(Color.error)
                }
            }
            .navigationTitle("Settings".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done".localized) {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingLanguageSelector) {
                LanguageSelectorView()
            }
        }
    }
}

// MARK: - Language Selector View
struct LanguageSelectorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var localizationManager: LocalizationManager
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Text("Select your preferred language".localized)
                        .font(.system(size: 14))
                        .foregroundColor(Color.textSecondary)
                        .padding(.vertical, 8)
                }
                
                Section {
                    ForEach(LocalizationManager.Language.allCases, id: \.self) { language in
                        Button(action: {
                            localizationManager.setLanguage(language)
                            dismiss()
                        }) {
                            HStack {
                                Text(language.displayName)
                                    .font(.system(size: 16))
                                    .foregroundColor(Color.textPrimary)
                                
                                Spacer()
                                
                                if localizationManager.currentLanguage == language {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(Color.accentGreen)
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .navigationTitle("Language".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done".localized) {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Settings Row
struct SettingsRow: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(Color.accentGreen)
                    .frame(width: 20)
                
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(Color.textPrimary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(Color.textSecondary)
                    .flipsForRightToLeftLayoutDirection(true)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}





#Preview {
    ProfileView()
        .environmentObject(LocalizationManager.shared)
        .environmentObject(SupabaseManager.shared)
} 