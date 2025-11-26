//
//  ContentModerationManager.swift
//  Synapse
//
//  Created for App Store compliance with Guideline 1.2
//  Content moderation, reporting, and blocking functionality
//

import Foundation
import Supabase

enum ReportReason: String, CaseIterable {
    case spam = "Spam"
    case harassment = "Harassment"
    case inappropriate = "Inappropriate Content"
    case violence = "Violence or Threats"
    case hate = "Hate Speech"
    case scam = "Scam or Fraud"
    case other = "Other"
}

class ContentModerationManager: ObservableObject {
    static let shared = ContentModerationManager()

    private let supabaseManager: SupabaseManager

    @Published var blockedUsers: Set<String> = []
    @Published var reportedContent: [String: Date] = [:]

    init(supabaseManager: SupabaseManager = SupabaseManager.shared) {
        self.supabaseManager = supabaseManager
        loadBlockedUsers()
    }

    // MARK: - Block/Unblock Users

    func blockUser(userId: String) async throws {
        guard let currentUserId = supabaseManager.currentUser?.id.uuidString else {
            throw NSError(domain: "ContentModeration", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }

        print("🚫 Blocking user: \(userId)")

        // Store in database
        try await supabaseManager.supabase.database
            .from("blocked_users")
            .insert([
                "user_id": AnyJSON.string(currentUserId),
                "blocked_user_id": AnyJSON.string(userId),
                "blocked_at": AnyJSON.string(ISO8601DateFormatter().string(from: Date()))
            ])
            .execute()

        // Update local state
        await MainActor.run {
            blockedUsers.insert(userId)
            saveBlockedUsers()
        }

        print("✅ User blocked successfully")
    }

    func unblockUser(userId: String) async throws {
        guard let currentUserId = supabaseManager.currentUser?.id.uuidString else {
            throw NSError(domain: "ContentModeration", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }

        print("✅ Unblocking user: \(userId)")

        // Remove from database
        try await supabaseManager.supabase.database
            .from("blocked_users")
            .delete()
            .eq("user_id", value: currentUserId)
            .eq("blocked_user_id", value: userId)
            .execute()

        // Update local state
        await MainActor.run {
            blockedUsers.remove(userId)
            saveBlockedUsers()
        }

        print("✅ User unblocked successfully")
    }

    func isUserBlocked(userId: String) -> Bool {
        return blockedUsers.contains(userId)
    }

    // MARK: - Report Content

    func reportContent(
        contentId: String,
        contentType: String,
        reportedUserId: String,
        reason: ReportReason,
        description: String?
    ) async throws {
        guard let currentUserId = supabaseManager.currentUser?.id.uuidString else {
            throw NSError(domain: "ContentModeration", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }

        print("🚨 Reporting content: \(contentId) for \(reason.rawValue)")

        // Store report in database
        try await supabaseManager.supabase.database
            .from("content_reports")
            .insert([
                "reporter_id": AnyJSON.string(currentUserId),
                "reported_user_id": AnyJSON.string(reportedUserId),
                "content_id": AnyJSON.string(contentId),
                "content_type": AnyJSON.string(contentType),
                "reason": AnyJSON.string(reason.rawValue),
                "description": description != nil ? AnyJSON.string(description!) : AnyJSON.null,
                "reported_at": AnyJSON.string(ISO8601DateFormatter().string(from: Date())),
                "status": AnyJSON.string("pending")
            ])
            .execute()

        // Update local state
        await MainActor.run {
            reportedContent[contentId] = Date()
        }

        print("✅ Content reported successfully")
    }

    func hasReportedContent(contentId: String) -> Bool {
        return reportedContent[contentId] != nil
    }

    // MARK: - Get Blocked Users List

    func loadBlockedUsers() {
        // Load from UserDefaults
        if let data = UserDefaults.standard.data(forKey: "blockedUsers"),
           let blocked = try? JSONDecoder().decode(Set<String>.self, from: data) {
            blockedUsers = blocked
        }
    }

    private func saveBlockedUsers() {
        if let data = try? JSONEncoder().encode(blockedUsers) {
            UserDefaults.standard.set(data, forKey: "blockedUsers")
        }
    }

    func fetchBlockedUsers() async throws -> [String] {
        guard let currentUserId = supabaseManager.currentUser?.id.uuidString else {
            return []
        }

        let response = try await supabaseManager.supabase.database
            .from("blocked_users")
            .select("blocked_user_id")
            .eq("user_id", value: currentUserId)
            .execute()

        // Parse response and extract blocked user IDs
        // This is a simplified version - you'll need to parse the actual response
        return []
    }
}
