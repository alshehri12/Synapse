//
//  CreatePodView.swift
//  Synapse
//
//  Created by Abdulrahman Alshehri on 18/01/1447 AH.
//

import SwiftUI
import FirebaseFirestore

struct CreatePodView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var firebaseManager: FirebaseManager
    @EnvironmentObject private var localizationManager: LocalizationManager
    
    @State private var podName = ""
    @State private var podDescription = ""
    @State private var isPublic = true
    @State private var selectedIdea: IdeaSpark?
    @State private var showingIdeaSelector = false
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showingError = false
    
    // Form validation
    @State private var nameError = ""
    @State private var descriptionError = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Create New Pod".localized)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color.textPrimary)
                        
                        Text("Start collaborating on your idea with a team".localized)
                            .font(.system(size: 16))
                            .foregroundColor(Color.textSecondary)
                    }
                    .padding(.horizontal, 20)
                    
                    // Pod Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Pod Name".localized)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.textPrimary)
                        
                        TextField("Enter pod name".localized, text: $podName)
                            .textFieldStyle(CustomTextFieldStyle())
                            .onChange(of: podName) { _ in
                                validateName()
                            }
                        
                        if !nameError.isEmpty {
                            Text(nameError)
                                .font(.system(size: 12))
                                .foregroundColor(Color.error)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Pod Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description".localized)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.textPrimary)
                        
                        TextEditor(text: $podDescription)
                            .frame(minHeight: 100)
                            .padding(12)
                            .background(Color.backgroundPrimary)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.border, lineWidth: 1)
                            )
                            .onChange(of: podDescription) { _ in
                                validateDescription()
                            }
                        
                        if !descriptionError.isEmpty {
                            Text(descriptionError)
                                .font(.system(size: 12))
                                .foregroundColor(Color.error)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Associated Idea
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Associated Idea".localized)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.textPrimary)
                        
                        Button(action: { showingIdeaSelector = true }) {
                            HStack {
                                if let idea = selectedIdea {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(idea.title)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(Color.textPrimary)
                                        
                                        Text(idea.description)
                                            .font(.system(size: 14))
                                            .foregroundColor(Color.textSecondary)
                                            .lineLimit(2)
                                    }
                                } else {
                                    Text("Select an idea to associate with this pod".localized)
                                        .font(.system(size: 16))
                                        .foregroundColor(Color.textSecondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color.textSecondary)
                            }
                            .padding(16)
                            .background(Color.backgroundPrimary)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.border, lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 20)
                    
                    // Privacy Settings
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Privacy Settings".localized)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.textPrimary)
                        
                        VStack(spacing: 12) {
                            PrivacyOption(
                                title: "Public Pod".localized,
                                description: "Anyone can discover and request to join".localized,
                                isSelected: isPublic,
                                action: { isPublic = true }
                            )
                            
                            PrivacyOption(
                                title: "Private Pod".localized,
                                description: "Only invited members can join".localized,
                                isSelected: !isPublic,
                                action: { isPublic = false }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Create Button
                    Button(action: createPod) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Text("Create Pod".localized)
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(isFormValid ? Color.accentGreen : Color.textSecondary)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(!isFormValid || isLoading)
                    .padding(.horizontal, 20)
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
            }
            .sheet(isPresented: $showingIdeaSelector) {
                IdeaSelectorView(selectedIdea: $selectedIdea)
            }
            .alert("Error".localized, isPresented: $showingError) {
                Button("OK".localized) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var isFormValid: Bool {
        !podName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !podDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        nameError.isEmpty &&
        descriptionError.isEmpty
    }
    
    private func validateName() {
        let trimmedName = podName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedName.isEmpty {
            nameError = "Pod name is required".localized
        } else if trimmedName.count < 3 {
            nameError = "Pod name must be at least 3 characters".localized
        } else if trimmedName.count > 50 {
            nameError = "Pod name must be less than 50 characters".localized
        } else {
            nameError = ""
        }
    }
    
    private func validateDescription() {
        let trimmedDescription = podDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedDescription.isEmpty {
            descriptionError = "Description is required".localized
        } else if trimmedDescription.count < 10 {
            descriptionError = "Description must be at least 10 characters".localized
        } else if trimmedDescription.count > 500 {
            descriptionError = "Description must be less than 500 characters".localized
        } else {
            descriptionError = ""
        }
    }
    
    private func createPod() {
        guard isFormValid else { return }
        
        isLoading = true
        
        Task {
            do {
                _ = try await firebaseManager.createPod(
                    name: podName.trimmingCharacters(in: .whitespacesAndNewlines),
                    description: podDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                    ideaId: selectedIdea?.id,
                    isPublic: isPublic
                )
                
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

// MARK: - Privacy Option
struct PrivacyOption: View {
    let title: String
    let description: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? Color.accentGreen : Color.textSecondary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.textPrimary)
                    
                    Text(description)
                        .font(.system(size: 14))
                        .foregroundColor(Color.textSecondary)
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

// MARK: - Custom Text Field Style
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .foregroundColor(Color.textPrimary) // Explicitly set text color
            .padding(16)
            .background(Color.backgroundPrimary)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.border, lineWidth: 1)
            )
    }
}

#Preview {
    CreatePodView()
        .environmentObject(LocalizationManager.shared)
        .environmentObject(FirebaseManager.shared)
} 