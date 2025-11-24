//
//  ProfileView.swift
//  Synapse
//
//  Created by Abdulrahman Alshehri on 18/01/1447 AH.
//

import SwiftUI
import Supabase
import UIKit

struct ProfileView: View {
    @State private var user: UserProfile?
    @State private var isLoading = false
    @State private var showingEditProfile = false
    @State private var showingSettings = false
    @EnvironmentObject private var localizationManager: LocalizationManager
    @EnvironmentObject private var supabaseManager: SupabaseManager
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Elegant Profile Header
                if let user = user {
                    ProfilePageHeader(
                        username: user.username,
                        email: user.email,
                        avatarInitial: String(user.username.prefix(1)).uppercased(),
                        onSettings: { showingSettings = true }
                    )
                    .environmentObject(localizationManager)
                } else if !isLoading {
                    // Fallback header when user profile is not loaded yet
                    ProfilePageHeader(
                        username: supabaseManager.currentUser?.email?.split(separator: "@").first.map(String.init) ?? "User",
                        email: supabaseManager.currentUser?.email ?? "",
                        avatarInitial: String(supabaseManager.currentUser?.email?.prefix(1) ?? "U").uppercased(),
                        onSettings: { showingSettings = true }
                    )
                    .environmentObject(localizationManager)
                }

                // Content
                ScrollView {
                    VStack(spacing: 24) {
                        // Loading State
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color.accentGreen))
                                .scaleEffect(1.2)
                                .frame(height: 200)
                        } else if let user = user {
                            // Bio Section
                            if let bio = user.bio, !bio.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("About".localized)
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(Color.textPrimary)
                                        .padding(.horizontal, 20)

                                    Text(bio)
                                        .font(.system(size: 14))
                                        .foregroundColor(Color.textSecondary)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 12)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color.backgroundPrimary)
                                        .cornerRadius(12)
                                        .padding(.horizontal, 20)
                                }
                            }

                            // Edit Profile Button
                            Button(action: { showingEditProfile = true }) {
                                Text("Edit Profile".localized)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        LinearGradient(
                                            colors: [Color.Brand.primary, Color.Brand.primaryDark],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal, 20)

                            // Stats Section
                            StatsSection(user: user)

                            // Skills & Interests
                            SkillsInterestsSection(user: user)

                            // Menu Items
                            MenuSection()
                        } else {
                            // No user profile found - show message
                            VStack(spacing: 16) {
                                Image(systemName: "person.crop.circle.badge.exclamationmark")
                                    .font(.system(size: 64))
                                    .foregroundColor(Color.accentGreen.opacity(0.5))
                                    .padding(.top, 40)

                                Text("Profile Not Found")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(Color.textPrimary)

                                Text("Your profile couldn't be loaded. This might be because your profile wasn't created properly during sign up.")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color.textSecondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)

                                Button(action: {
                                    loadUserProfile()
                                }) {
                                    Text("Try Again")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 32)
                                        .padding(.vertical, 12)
                                        .background(Color.accentGreen)
                                        .cornerRadius(12)
                                }
                                .padding(.top, 8)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 60)
                        }
                    }
                    .padding(.vertical, 20)
                }
            }
            .background(Color.backgroundSecondary)
            .navigationBarHidden(true)
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
                    let username = userData["username"] as? String ?? ""
                    let email = userData["email"] as? String ?? ""
                    let bio = userData["bio"] as? String
                    let avatarURL = userData["avatar_url"] as? String
                    let skills = userData["skills"] as? [String] ?? []
                    let interests = userData["interests"] as? [String] ?? []
                    let ideasSparked = userData["ideas_sparked"] as? Int ?? 0
                    let projectsContributed = userData["projects_contributed"] as? Int ?? 0
                    let dateJoined: Date = {
                        if let s = userData["date_joined"] as? String, let d = ISO8601DateFormatter().date(from: s) {
                            return d
                        }
                        return Date()
                    }()

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
                    // Profile doesn't exist, try to create it
                    print("⚠️ Profile not found, attempting to create one...")
                    let defaultUsername = currentUser.email?.split(separator: "@").first.map(String.init) ?? "User_\(currentUser.id.uuidString.prefix(6))"

                    try await supabaseManager.createUserProfile(
                        userId: currentUser.id.uuidString,
                        email: currentUser.email ?? "",
                        username: defaultUsername
                    )

                    print("✅ Profile created, reloading...")
                    // Try loading again after creating
                    if let userData = try await supabaseManager.getUserProfile(userId: currentUser.id.uuidString) {
                        let username = userData["username"] as? String ?? defaultUsername
                        let email = userData["email"] as? String ?? currentUser.email ?? ""

                        await MainActor.run {
                            user = UserProfile(
                                id: currentUser.id.uuidString,
                                username: username,
                                email: email,
                                bio: nil,
                                avatarURL: nil,
                                skills: [],
                                interests: [],
                                ideasSparked: 0,
                                projectsContributed: 0,
                                dateJoined: Date()
                            )
                            isLoading = false
                        }
                    } else {
                        await MainActor.run {
                            isLoading = false
                        }
                    }
                }
            } catch {
                print("❌ Error loading user profile: \(error)")
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
                    icon: "lightbulb",
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
    @EnvironmentObject private var appearanceManager: AppearanceManager
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
                    SettingsLinkRow(icon: "person", title: "Account Settings".localized) {
                        AccountSettingsView()
                    }
                    SettingsLinkRow(icon: "bell", title: "Notifications".localized) {
                        NotificationSettingsView()
                    }
                    SettingsLinkRow(icon: "lock", title: "Privacy".localized) {
                        PrivacySettingsView()
                    }
                }
                
                Section("Appearance".localized) {
                    SettingsLinkRow(icon: "paintbrush", title: "Appearance".localized) {
                        AppearanceSettingsView()
                    }
                }

                Section("App".localized) {
                    SettingsRow(icon: "globe", title: "Language".localized, action: { showingLanguageSelector = true })
                    SettingsLinkRow(icon: "gearshape.2", title: "App Preferences".localized) {
                        AppPreferencesView()
                    }
                    SettingsLinkRow(icon: "shield.checkered", title: "Content Moderation Test".localized) {
                        ModerationTestView()
                    }
                    SettingsLinkRow(icon: "questionmark.circle", title: "Help & Support".localized) {
                        HelpSupportView()
                    }
                    SettingsLinkRow(icon: "doc.text", title: "Terms of Service".localized) {
                        TermsView()
                    }
                    SettingsLinkRow(icon: "hand.raised", title: "Privacy Policy".localized) {
                        PrivacyPolicyView()
                    }
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

// MARK: - Settings Navigation Row
struct SettingsLinkRow<Destination: View>: View {
    let icon: String
    let title: String
    let destination: Destination
    
    init(icon: String, title: String, @ViewBuilder destination: () -> Destination) {
        self.icon = icon
        self.title = title
        self.destination = destination()
    }
    
    var body: some View {
        NavigationLink(destination: destination) {
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

// MARK: - Account Settings
struct AccountSettingsView: View {
    @EnvironmentObject private var localizationManager: LocalizationManager
    @EnvironmentObject private var supabaseManager: SupabaseManager
    @State private var showingResetAlert = false
    
    private var userEmail: String {
        supabaseManager.currentUser?.email ?? ""
    }
    
    private var username: String {
        supabaseManager.currentUser?.displayName ?? ""
    }
    
    var body: some View {
        List {
            Section(header: Text("Profile".localized), footer: Text("Manage your public information".localized)) {
                SettingsLinkRow(icon: "person.crop.circle", title: "Edit Profile".localized) {
                    EditProfileView(user: mockUser)
                }
            }
            
            Section(header: Text("Account".localized)) {
                HStack {
                    Text("Email".localized)
                    Spacer()
                    Text(userEmail).foregroundColor(Color.textSecondary)
                }
                HStack {
                    Text("Username".localized)
                    Spacer()
                    Text(username).foregroundColor(Color.textSecondary)
                }
            }
            
            Section(header: Text("Security".localized), footer: Text("We will email you a link to reset your password.".localized)) {
                Button {
                    showingResetAlert = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "key.fill").foregroundColor(Color.accentGreen).frame(width: 20)
                        Text("Send Password Reset Email".localized).foregroundColor(Color.textPrimary)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .navigationTitle("Account Settings".localized)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Coming Soon".localized, isPresented: $showingResetAlert) {
            Button("OK".localized, role: .cancel) {}
        } message: {
            Text("Password reset via email will be available after SMTP setup.".localized)
        }
    }
}

// MARK: - Notification Settings
struct NotificationSettingsView: View {
    @AppStorage("notifications.pushEnabled") private var pushEnabled = true
    @AppStorage("notifications.inAppEnabled") private var inAppEnabled = true
    @AppStorage("notifications.mentions") private var mentionsEnabled = true
    @AppStorage("notifications.messages") private var messagesEnabled = true
    @AppStorage("notifications.projectUpdates") private var projectUpdatesEnabled = true
    @AppStorage("notifications.taskUpdates") private var taskUpdatesEnabled = true
    @AppStorage("notifications.likesComments") private var likesCommentsEnabled = true
    
    var body: some View {
        List {
            Section(header: Text("General".localized), footer: Text("Control how you get notified".localized)) {
                Toggle("Push Notifications".localized, isOn: $pushEnabled)
                Toggle("In-App Notifications".localized, isOn: $inAppEnabled)
            }
            Section(header: Text("Types".localized)) {
                Toggle("Mentions".localized, isOn: $mentionsEnabled)
                Toggle("Messages".localized, isOn: $messagesEnabled)
                Toggle("Project Updates".localized, isOn: $projectUpdatesEnabled)
                Toggle("Task Updates".localized, isOn: $taskUpdatesEnabled)
                Toggle("Likes & Comments".localized, isOn: $likesCommentsEnabled)
            }
        }
        .navigationTitle("Notifications".localized)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Privacy Settings
struct PrivacySettingsView: View {
    @AppStorage("privacy.publicProfile") private var publicProfile = true
    @AppStorage("privacy.showOnlineStatus") private var showOnlineStatus = true
    @AppStorage("privacy.mentionsScope") private var mentionsScope = 0 // 0 Everyone, 1 Following, 2 No one
    @AppStorage("privacy.invitesScope") private var invitesScope = 0
    
    var body: some View {
        List {
            Section(header: Text("Profile".localized)) {
                Toggle("Public Profile".localized, isOn: $publicProfile)
                Toggle("Show Online Status".localized, isOn: $showOnlineStatus)
            }
            Section(header: Text("Interactions".localized)) {
                Picker("Allow mentions from".localized, selection: $mentionsScope) {
                    Text("Everyone".localized).tag(0)
                    Text("People You Follow".localized).tag(1)
                    Text("No One".localized).tag(2)
                }
                Picker("Allow project invites from".localized, selection: $invitesScope) {
                    Text("Everyone".localized).tag(0)
                    Text("People You Follow".localized).tag(1)
                    Text("No One".localized).tag(2)
                }
            }
        }
        .navigationTitle("Privacy".localized)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Appearance Settings
struct AppearanceSettingsView: View {
    @EnvironmentObject private var appearanceManager: AppearanceManager
    @EnvironmentObject private var localizationManager: LocalizationManager

    var body: some View {
        List {
            Section(header: Text("Theme".localized), footer: Text("Choose how Synapse looks on your device".localized)) {
                ForEach(AppearanceManager.ColorSchemePreference.allCases, id: \.self) { preference in
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            appearanceManager.setPreference(preference)
                        }
                    }) {
                        HStack {
                            Image(systemName: preference.icon)
                                .foregroundColor(Color.accentGreen)
                                .frame(width: 24)

                            Text(preference.rawValue.localized)
                                .foregroundColor(Color.Text.primary)

                            Spacer()

                            if appearanceManager.preference == preference {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Color.accentGreen)
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .navigationTitle("Appearance".localized)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - App Preferences
struct AppPreferencesView: View {
    @AppStorage("app.appearance") private var appearance = 0 // 0 System, 1 Light, 2 Dark
    @AppStorage("app.dataSaver") private var dataSaver = false
    @AppStorage("app.autoplayMedia") private var autoplayMedia = true
    @AppStorage("app.haptics") private var haptics = true
    @AppStorage("app.analytics") private var analytics = false
    
    var body: some View {
        List {
            Section(header: Text("Appearance".localized), footer: Text("Appearance changes may require app restart in this version.".localized)) {
                Picker("Theme".localized, selection: $appearance) {
                    Text("System Default".localized).tag(0)
                    Text("Light".localized).tag(1)
                    Text("Dark".localized).tag(2)
                }
            }
            Section(header: Text("Playback".localized)) {
                Toggle("Autoplay Media".localized, isOn: $autoplayMedia)
                Toggle("Data Saver".localized, isOn: $dataSaver)
            }
            Section(header: Text("Feedback".localized)) {
                Toggle("Haptics".localized, isOn: $haptics)
                Toggle("Share Analytics".localized, isOn: $analytics)
            }
        }
        .navigationTitle("App Preferences".localized)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Help & Support
struct HelpSupportView: View {
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
        return "v\(version) (\(build))"
    }
    
    var body: some View {
        List {
            Section(header: Text("Support".localized)) {
                Button {
                    if let url = URL(string: "mailto:support@mysynapeses.com") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "envelope.fill").foregroundColor(Color.accentGreen).frame(width: 20)
                        Text("Contact Support".localized).foregroundColor(Color.textPrimary)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            Section(header: Text("About".localized)) {
                HStack {
                    Text("App Version".localized)
                    Spacer()
                    Text(appVersion).foregroundColor(Color.textSecondary)
                }
                Button {
                    if let url = URL(string: "https://apps.apple.com") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "star.fill").foregroundColor(Color.accentGreen).frame(width: 20)
                        Text("Rate App".localized).foregroundColor(Color.textPrimary)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .navigationTitle("Help & Support".localized)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Terms & Privacy
struct TermsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Terms of Service".localized)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color.textPrimary)
                Text("These are a summary of our Terms. For full details, please visit our website.".localized)
                    .foregroundColor(Color.textSecondary)
                Button {
                    if let url = URL(string: "https://usynapse.com/terms") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("View Full Terms".localized)
                        .foregroundColor(Color.accentGreen)
                }
                .padding(.top, 8)
            }
            .padding(16)
        }
        .background(Color.backgroundSecondary)
        .navigationTitle("Terms of Service".localized)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Privacy Policy".localized)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color.textPrimary)
                Text("Learn how we collect, use, and protect your data. For full details, please visit our website.".localized)
                    .foregroundColor(Color.textSecondary)
                Button {
                    if let url = URL(string: "https://usynapse.com/privacy") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("View Full Policy".localized)
                        .foregroundColor(Color.accentGreen)
                }
                .padding(.top, 8)
            }
            .padding(16)
        }
        .background(Color.backgroundSecondary)
        .navigationTitle("Privacy Policy".localized)
        .navigationBarTitleDisplayMode(.inline)
    }
}





#Preview {
    ProfileView()
        .environmentObject(LocalizationManager.shared)
        .environmentObject(SupabaseManager.shared)
} 