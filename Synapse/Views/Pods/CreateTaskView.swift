//
//  CreateTaskView.swift
//  Synapse
//
//  Created by Abdulrahman Alshehri on 18/01/1447 AH.
//

import SwiftUI
import Supabase

struct CreateTaskView: View {
    let pod: IncubationProject
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var supabaseManager: SupabaseManager
    @EnvironmentObject private var localizationManager: LocalizationManager
    
    @State private var taskTitle = ""
    @State private var taskDescription = ""
    @State private var selectedAssignee: ProjectMember?
    @State private var selectedPriority: ProjectTask.TaskPriority = .medium
    @State private var dueDate = Date().addingTimeInterval(86400) // Tomorrow
    @State private var hasDueDate = true
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showingError = false
    
    // Form validation
    @State private var titleError = ""
    @State private var descriptionError = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Create New Task".localized)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color.textPrimary)
                        
                        Text("Add a task to \(pod.name)".localized)
                            .font(.system(size: 16))
                            .foregroundColor(Color.textSecondary)
                    }
                    .padding(.horizontal, 20)
                    
                    // Task Title
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Task Title".localized)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.textPrimary)
                        
                        TextField("Enter task title".localized, text: $taskTitle)
                            .textFieldStyle(CustomTextFieldStyle())
                            .onChange(of: taskTitle) { _ in
                                validateTitle()
                            }
                        
                        if !titleError.isEmpty {
                            Text(titleError)
                                .font(.system(size: 12))
                                .foregroundColor(Color.error)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Task Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description".localized)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.textPrimary)
                        
                        TextEditor(text: $taskDescription)
                            .frame(minHeight: 100)
                            .padding(12)
                            .background(Color.backgroundPrimary)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.border, lineWidth: 1)
                            )
                            .onChange(of: taskDescription) { _ in
                                validateDescription()
                            }
                        
                        if !descriptionError.isEmpty {
                            Text(descriptionError)
                                .font(.system(size: 12))
                                .foregroundColor(Color.error)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Assignee
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Assignee".localized)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.textPrimary)
                        
                        Menu {
                            ForEach(pod.members) { member in
                                Button(action: { selectedAssignee = member }) {
                                    HStack {
                                        Text(member.username)
                                        if selectedAssignee?.id == member.id {
                                            Spacer()
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                if let assignee = selectedAssignee {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(assignee.username)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(Color.textPrimary)
                                        
                                        Text(assignee.role)
                                            .font(.system(size: 14))
                                            .foregroundColor(Color.textSecondary)
                                    }
                                } else {
                                    Text("Select assignee".localized)
                                        .font(.system(size: 16))
                                        .foregroundColor(Color.textSecondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.down")
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
                    }
                    .padding(.horizontal, 20)
                    
                    // Priority
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Priority".localized)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.textPrimary)
                        
                        HStack(spacing: 12) {
                            ForEach(ProjectTask.TaskPriority.allCases, id: \.self) { priority in
                                PriorityOption(
                                    priority: priority,
                                    isSelected: selectedPriority == priority,
                                    action: { selectedPriority = priority }
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Due Date
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Due Date".localized)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color.textPrimary)
                            
                            Spacer()
                            
                            Toggle("", isOn: $hasDueDate)
                                .toggleStyle(SwitchToggleStyle(tint: Color.accentGreen))
                        }
                        
                        if hasDueDate {
                            DatePicker(
                                "Due Date".localized,
                                selection: $dueDate,
                                displayedComponents: [.date]
                            )
                            .datePickerStyle(CompactDatePickerStyle())
                            .padding(16)
                            .background(Color.backgroundPrimary)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.border, lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Create Button
                    Button(action: createTask) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Text("Create Task".localized)
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
            .alert("Error".localized, isPresented: $showingError) {
                Button("OK".localized) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var isFormValid: Bool {
        !taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !taskDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        titleError.isEmpty &&
        descriptionError.isEmpty
    }
    
    private func validateTitle() {
        let trimmedTitle = taskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedTitle.isEmpty {
            titleError = "Task title is required".localized
        } else if trimmedTitle.count < 3 {
            titleError = "Task title must be at least 3 characters".localized
        } else if trimmedTitle.count > 100 {
            titleError = "Task title must be less than 100 characters".localized
        } else {
            titleError = ""
        }
    }
    
    private func validateDescription() {
        let trimmedDescription = taskDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedDescription.isEmpty {
            descriptionError = "Description is required".localized
        } else if trimmedDescription.count < 5 {
            descriptionError = "Description must be at least 5 characters".localized
        } else if trimmedDescription.count > 500 {
            descriptionError = "Description must be less than 500 characters".localized
        } else {
            descriptionError = ""
        }
    }
    
    private func createTask() {
        guard isFormValid else { return }
        
        isLoading = true
        
        Task {
            do {
                let trimmedTitle = taskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                let trimmedDescription = taskDescription.trimmingCharacters(in: .whitespacesAndNewlines)
                
                print("✅ Task creation requested:")
                print("- Project: \(pod.id)")
                print("- Title: \(trimmedTitle)")
                print("- Description: \(trimmedDescription)")
                print("- Assigned To: \(selectedAssignee?.userId ?? "None")")
                print("- Username: \(selectedAssignee?.username ?? "None")")
                print("- Due Date: \(hasDueDate ? dueDate.description : "None")")
                print("- Priority: \(selectedPriority.rawValue)")
                
                _ = try await supabaseManager.createTask(
                    podId: pod.id,
                    title: trimmedTitle,
                    description: trimmedDescription.isEmpty ? nil : trimmedDescription,
                    assignedTo: selectedAssignee?.userId,
                    assignedToUsername: selectedAssignee?.username,
                    priority: selectedPriority.rawValue,
                    dueDate: hasDueDate ? dueDate : nil
                )
                
                print("🎉 Task created successfully!")
                
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                print("❌ Error creating task: \(error.localizedDescription)")
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
}

// MARK: - Priority Option
struct PriorityOption: View {
    let priority: ProjectTask.TaskPriority
    let isSelected: Bool
    let action: () -> Void
    
    var priorityColor: Color {
        switch priority {
        case .low: return Color.textSecondary
        case .medium: return Color.accentOrange
        case .high: return Color.accentBlue
        case .urgent: return Color.error
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Circle()
                    .fill(isSelected ? priorityColor : Color.clear)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .stroke(priorityColor, lineWidth: 2)
                    )
                
                Text(priority.rawValue.localized.capitalized)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? priorityColor : Color.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? priorityColor.opacity(0.1) : Color.backgroundPrimary)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? priorityColor : Color.border, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    CreateTaskView(pod: mockPods[0])
        .environmentObject(LocalizationManager.shared)
        .environmentObject(SupabaseManager.shared)
} 