//
//  ModerationService.swift
//  Synapse
//
//  Main content moderation service
//

import Foundation

// MARK: - Moderation Models
struct ModerationResult {
    let isAllowed: Bool
    let confidence: Double
    let violations: [ViolationType]
    let sanitizedContent: String?
    let moderationId: String
    
    enum ViolationType: String, CaseIterable {
        case hate = "hate"
        case harassment = "harassment"
        case violence = "violence"
        case selfHarm = "self-harm"
        case sexual = "sexual"
        case spam = "spam"
        case toxicity = "toxicity"
        case profanity = "profanity"
        case personalInfo = "personal-info"
    }
}

enum ContentType: String, CaseIterable {
    case idea = "idea"
    case comment = "comment"
    case chat = "chat"
    case task = "task"
    case profile = "profile"
    case podDescription = "pod_description"
}

// MARK: - Moderation Service
@MainActor
class ModerationService: ObservableObject {
    static let shared = ModerationService()
    
    private let openAIService = OpenAIService.shared
    
    private init() {}
    
    // MARK: - Public API
    
    /// Check if moderation service is ready
    var isReady: Bool {
        return openAIService.isConfigured
    }
    
    /// Test all configured moderation services
    func testServices() async -> [String] {
        var results: [String] = []
        
        // Test OpenAI
        let openAIResult = await openAIService.testConnection()
        results.append("OpenAI: \(openAIResult.message)")
        
        // Test custom rules
        results.append("Custom Rules: ✅ Ready")
        
        return results
    }
    
    /// Moderate content using available providers
    func moderateContent(_ content: String, contentType: ContentType) async throws -> ModerationResult {
        // Try OpenAI first if available
        if openAIService.isConfigured {
            do {
                let result = try await moderateWithOpenAI(content)
                return result
            } catch {
                print("⚠️ OpenAI moderation failed: \(error)")
                // Fall back to custom rules
            }
        }
        
        // Use custom rules as fallback
        return moderateWithCustomRules(content, contentType: contentType)
    }
    
    /// Quick moderation check for real-time use
    func quickModerationCheck(_ content: String, contentType: ContentType = .chat) async -> Bool {
        guard content.count > 5 else { return true }
        
        // Only use custom rules for performance
        let result = moderateWithCustomRules(content, contentType: contentType)
        return result.isAllowed
    }
    
    // MARK: - OpenAI Integration
    private func moderateWithOpenAI(_ content: String) async throws -> ModerationResult {
        let result = try await openAIService.moderateContent(content)
        
        var violations: [ModerationResult.ViolationType] = []
        if result.categories.hate { violations.append(.hate) }
        if result.categories.harassment { violations.append(.harassment) }
        if result.categories.violence { violations.append(.violence) }
        if result.categories.selfHarm { violations.append(.selfHarm) }
        if result.categories.sexual { violations.append(.sexual) }
        
        let maxScore = max(
            result.categoryScores.hate,
            result.categoryScores.harassment,
            result.categoryScores.violence,
            result.categoryScores.selfHarm,
            result.categoryScores.sexual
        )
        
        return ModerationResult(
            isAllowed: !result.flagged,
            confidence: maxScore,
            violations: violations,
            sanitizedContent: nil,
            moderationId: UUID().uuidString
        )
    }
    
    // MARK: - Custom Rules Engine
    private func moderateWithCustomRules(_ content: String, contentType: ContentType) -> ModerationResult {
        var violations: [ModerationResult.ViolationType] = []
        
        // Basic spam detection
        if detectSpam(content) {
            violations.append(.spam)
        }
        
        // Personal information detection
        if detectPersonalInfo(content) {
            violations.append(.personalInfo)
        }
        
        // Basic profanity filter
        if detectProfanity(content.lowercased()) {
            violations.append(.profanity)
        }
        
        let isAllowed = violations.isEmpty
        let confidence = violations.isEmpty ? 0.1 : 0.7
        
        return ModerationResult(
            isAllowed: isAllowed,
            confidence: confidence,
            violations: violations,
            sanitizedContent: isAllowed ? nil : sanitizeContent(content),
            moderationId: UUID().uuidString
        )
    }
    
    private func detectSpam(_ content: String) -> Bool {
        // Simple spam detection
        let tooManyEmojis = content.unicodeScalars.filter { $0.properties.isEmoji }.count > content.count / 3
        let allCaps = content.uppercased() == content && content.count > 15
        return tooManyEmojis || allCaps
    }
    
    private func detectPersonalInfo(_ content: String) -> Bool {
        let emailRegex = #"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}"#
        return content.range(of: emailRegex, options: .regularExpression) != nil
    }
    
    private func detectProfanity(_ content: String) -> Bool {
        let basicProfanity = ["spam", "scam", "fake"]
        return basicProfanity.contains { content.contains($0) }
    }
    
    private func sanitizeContent(_ content: String) -> String {
        var sanitized = content
        
        // Remove email addresses
        let emailRegex = #"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}"#
        sanitized = sanitized.replacingOccurrences(
            of: emailRegex,
            with: "[EMAIL_REMOVED]",
            options: .regularExpression
        )
        
        return sanitized.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
