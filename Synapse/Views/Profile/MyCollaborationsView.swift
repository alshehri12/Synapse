//
//  MyCollaborationsView.swift
//  Synapse
//
//  Created by Abdulrahman Alshehri on 18/01/1447 AH.
//

import SwiftUI
import Supabase

struct MyCollaborationsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var supabaseManager: SupabaseManager
    @State private var pods: [IncubationProject] = []
    @State private var isLoading = true
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Selector
                Picker("Pod Status", selection: $selectedTab) {
                    Text("Active".localized).tag(0)
                    Text("Planning".localized).tag(1)
                    Text("Completed".localized).tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                
                if isLoading {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color.accentGreen))
                        .scaleEffect(1.2)
                    Spacer()
                } else if filteredPods.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "person.3")
                            .font(.system(size: 48))
                            .foregroundColor(Color.textSecondary)
                        
                        Text("No collaborations yet".localized)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Color.textSecondary)
                        
                        Text("Join pods to start collaborating on ideas".localized)
                            .font(.system(size: 14))
                            .foregroundColor(Color.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredPods.indices, id: \.self) { index in
                                let pod = filteredPods[index]
                                CollaborationCard(pod: pod)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .background(Color.backgroundSecondary)
            .navigationTitle("My Collaborations".localized)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done".localized) {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadCollaborations()
            }
            .onChange(of: selectedTab) { _, _ in
                // Filter is applied automatically
            }
        }
    }
    
    private var filteredPods: [IncubationProject] {
        let statusMap = [IncubationProject.ProjectStatus.active, .planning, .completed]
        let selectedStatus = statusMap[selectedTab]
        
        return pods.filter { pod in
            return pod.status == selectedStatus
        }
    }
    
    private func loadCollaborations() {
        guard let currentUser = supabaseManager.currentUser else { return }
        
        isLoading = true
        
        Task {
            do {
                // Get all pods where user is a member or creator
                let allPods = try await supabaseManager.getPodsForUser(userId: currentUser.uid)

                await MainActor.run {
                    pods = allPods
                    isLoading = false
                }
            } catch {
                print("Error loading collaborations: \(error)")
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}

struct CollaborationCard: View {
    let pod: IncubationProject
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title and Status
            HStack {
                Text(pod.name)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color.textPrimary)
                    .lineLimit(1)
                
                Spacer()
                
                // Status Badge
                let status = pod.status
                Text(status.rawValue.capitalized.localized)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor(for: status.rawValue))
                    .cornerRadius(8)
            }
            
            // Description
            Text(pod.description)
                .font(.system(size: 14))
                .foregroundColor(Color.textSecondary)
                .lineLimit(2)
            
            // Progress
            let tasks = pod.tasks
            let totalTasks = tasks.count
            let completedTasks = tasks.filter { task in
                return task.status == .completed
            }.count
            
            let progress = totalTasks > 0 ? Double(completedTasks) / Double(totalTasks) : 0.0
                
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Progress".localized)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.textSecondary)
                    
                    Spacer()
                    
                    Text("\(completedTasks)/\(totalTasks)")
                        .font(.system(size: 12))
                        .foregroundColor(Color.textSecondary)
                }
                
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: Color.accentGreen))
                    .scaleEffect(y: 0.8)
            }
            
            // Members
            let members = pod.members
            HStack {
                Text("\(members.count) members".localized)
                    .font(.system(size: 12))
                    .foregroundColor(Color.textSecondary)
                
                Spacer()
                
                // Member avatars
                HStack(spacing: -8) {
                    ForEach(Array(members.prefix(3).enumerated()), id: \.offset) { index, member in
                        Circle()
                            .fill(Color.accentGreen)
                            .frame(width: 24, height: 24)
                            .overlay(
                                Text(String(member.username.prefix(1)).uppercased())
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color.backgroundPrimary, lineWidth: 2)
                            )
                    }
                    
                    if members.count > 3 {
                        Text("+\(members.count - 3)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Color.textSecondary)
                            .padding(.leading, 8)
                    }
                }
            }
            
            // Date
            Text("Created \(pod.createdAt.formatted(date: .abbreviated, time: .omitted))".localized)
                .font(.system(size: 12))
                .foregroundColor(Color.textSecondary)
        }
        .padding(16)
        .background(Color.backgroundPrimary)
        .cornerRadius(12)
    }
    
    private func statusColor(for status: String) -> Color {
        switch status {
        case "active":
            return Color.accentGreen
        case "planning":
            return Color.accentOrange
        case "completed":
            return Color.accentBlue
        default:
            return Color.accentGreen
        }
    }
}
