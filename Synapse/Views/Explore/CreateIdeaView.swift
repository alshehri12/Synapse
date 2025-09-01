//
//  CreateIdeaView.swift
//  Synapse
//
//  Created by Abdulrahman Alshehri on 18/01/1447 AH.
//

import SwiftUI

struct CreateIdeaView: View {
    let onDismiss: () -> Void
    @State private var title = ""
    @State private var description = ""
    @State private var tags: [String] = []
    @State private var newTag = ""
    @State private var isPublic = true
    @State private var isSubmitting = false
    @State private var showingSuccessAlert = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @EnvironmentObject private var localizationManager: LocalizationManager
    @EnvironmentObject private var supabaseManager: SupabaseManager
    
    private let maxTitleLength = 100
    private let maxDescriptionLength = 500
    private let maxTags = 5
    
    var isFormValid: Bool {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return !trimmedTitle.isEmpty &&
               !trimmedDescription.isEmpty &&
               title.count <= maxTitleLength &&
               description.count <= maxDescriptionLength
    }
    
    var body: some View {
        ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Custom Back Button
                    HStack {
                        Button(action: {
                            print("Custom back button tapped!")
                            onDismiss()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .medium))
                                Text("Back".localized)
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .foregroundColor(Color.accentGreen)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        
                        Spacer()
                    }
                    
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Spark a New Idea".localized)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color.textPrimary)
                        
                        Text("Share your creative vision and find collaborators".localized)
                            .font(.system(size: 16))
                            .foregroundColor(Color.textSecondary)
                    }
                    .padding(.horizontal, 20)
                    
                    // Title Section
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
                    
                    // Description Section
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
                    
                    // Tags Section
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
                        
                        // Add Tag Input
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
                        
                        // Tags Display
                        if !tags.isEmpty {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                                ForEach(tags, id: \.self) { tag in
                                    TagView(tag: tag) {
                                        removeTag(tag)
                                    }
                                }
                            }
                        }
                        
                        // Suggested Tags
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Popular tags:".localized)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color.textSecondary)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(suggestedTags, id: \.self) { tag in
                                        if !tags.contains(tag) {
                                            Button(action: { addSuggestedTag(tag) }) {
                                                Text("#\(tag)")
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
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Privacy Section
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
                    
                    // Submit Button
                    VStack(spacing: 16) {
                        Button(action: {
                            submitIdea()
                        }) {
                            HStack {
                                if isSubmitting {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                
                                Text(isSubmitting ? "Sparking...".localized : "Create Idea".localized)
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
                        
                        Text("Your idea will be visible to the Synapse community and can attract collaborators".localized)
                            .font(.system(size: 12))
                            .foregroundColor(Color.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                }
                .padding(.bottom, 40)
            }
            .background(Color.backgroundSecondary)
            .alert("Idea created successfully!".localized, isPresented: $showingSuccessAlert) {
                Button("Continue".localized) {
                    resetForm()
                    onDismiss()
                }
            } message: {
                Text("Your idea has been shared with the community.".localized)
            }
            .alert("Error Creating Idea".localized, isPresented: $showingErrorAlert) {
                Button("OK".localized) { }
            } message: {
                Text(errorMessage)
            }
    }
    
    private func addTag() {
        let trimmedTag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTag.isEmpty && !tags.contains(trimmedTag) && tags.count < maxTags {
            tags.append(trimmedTag)
            newTag = ""
        }
    }
    
    private func addSuggestedTag(_ tag: String) {
        if !tags.contains(tag) && tags.count < maxTags {
            tags.append(tag)
        }
    }
    
    private func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
    
    private func submitIdea() {
        guard isFormValid else { return }
        guard let currentUser = supabaseManager.currentUser else { return }
        
        print("🚀 CreateIdeaView: Starting idea submission...")
        print("📝 Form data: Title='\(title)', Public=\(isPublic), Tags=\(tags)")
        
        isSubmitting = true
        
        Task {
            do {
                // Try to fetch profile, but don't fail idea creation if profile lookup has issues
                var resolvedUsername: String = "Anonymous User"
                do {
                    if let userData = try await supabaseManager.getUserProfile(userId: currentUser.uid) {
                        resolvedUsername = userData["username"] as? String
                            ?? supabaseManager.currentUser?.displayName
                            ?? (supabaseManager.currentUser?.email?.split(separator: "@").first.map(String.init))
                            ?? "Anonymous User"
                        print("👤 User profile found: \(resolvedUsername)")
                    } else {
                        resolvedUsername = supabaseManager.currentUser?.displayName
                            ?? (supabaseManager.currentUser?.email?.split(separator: "@").first.map(String.init))
                            ?? "Anonymous User"
                        print("ℹ️ No profile row; using resolved username: \(resolvedUsername)")
                    }
                } catch {
                    resolvedUsername = supabaseManager.currentUser?.displayName
                        ?? (supabaseManager.currentUser?.email?.split(separator: "@").first.map(String.init))
                        ?? "Anonymous User"
                    print("⚠️ Profile lookup failed; falling back to username: \(resolvedUsername). Error: \(error)")
                }

                let ideaSparkId = try await supabaseManager.createIdeaSpark(
                    title: title,
                    description: description,
                    tags: tags,
                    isPublic: isPublic,
                    creatorId: currentUser.uid,
                    creatorUsername: resolvedUsername
                )
                
                print("✅ CreateIdeaView: Idea created with ID: \(ideaSparkId)")
                
                await MainActor.run {
                    isSubmitting = false
                    showingSuccessAlert = true
                }
            } catch {
                print("❌ CreateIdeaView: Error creating idea - \(error)")
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = error.localizedDescription
                    showingErrorAlert = true
                }
            }
        }
    }
    
    private func resetForm() {
        title = ""
        description = ""
        tags = []
        newTag = ""
        isPublic = true
    }
}







// MARK: - Suggested Tags
let suggestedTags = [
    "AI", "MobileApp", "WebApp", "Sustainability", "Healthcare", "Education",
    "Finance", "Entertainment", "SocialImpact", "Technology", "Design", "Marketing"
]

#Preview {
    CreateIdeaView(onDismiss: {})
        .environmentObject(LocalizationManager.shared)
        .environmentObject(SupabaseManager.shared)
} 