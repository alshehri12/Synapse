//
//  OpenAIService.swift
//  Synapse
//
//  OpenAI API service for content moderation
//

import Foundation

// MARK: - OpenAI Service
class OpenAIService {
    static let shared = OpenAIService()
    
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1"
    
    private init() {
        // Try multiple sources for API key
        self.apiKey = Bundle.main.infoDictionary?["OpenAIAPIKey"] as? String ?? 
                     ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
    }
    
    // MARK: - Public API
    
    /// Check if OpenAI service is properly configured
    var isConfigured: Bool {
        return !apiKey.isEmpty && apiKey != "YOUR_OPENAI_API_KEY_HERE"
    }
    
    /// Test the OpenAI connection
    func testConnection() async -> (success: Bool, message: String) {
        guard isConfigured else {
            return (false, "❌ OpenAI API key not configured")
        }
        
        do {
            let _ = try await moderateContent("test")
            return (true, "✅ OpenAI connection successful")
        } catch {
            return (false, "❌ OpenAI connection failed: \(error.localizedDescription)")
        }
    }
    
    /// Moderate content using OpenAI Moderation API
    func moderateContent(_ content: String) async throws -> OpenAIModerationResult {
        guard isConfigured else {
            throw OpenAIError.apiKeyMissing
        }
        
        let url = URL(string: "\(baseURL)/moderations")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "input": content,
            "model": "text-moderation-latest"
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            guard httpResponse.statusCode == 200 else {
                throw OpenAIError.httpError(httpResponse.statusCode)
            }
        }
        
        let moderationResponse = try JSONDecoder().decode(OpenAIModerationResponse.self, from: data)
        
        guard let result = moderationResponse.results.first else {
            throw OpenAIError.invalidResponse
        }
        
        return result
    }
}

// MARK: - OpenAI Models
struct OpenAIModerationResponse: Codable {
    let id: String
    let model: String
    let results: [OpenAIModerationResult]
}

struct OpenAIModerationResult: Codable {
    let flagged: Bool
    let categories: Categories
    let categoryScores: CategoryScores
    
    struct Categories: Codable {
        let hate: Bool
        let harassment: Bool
        let violence: Bool
        let selfHarm: Bool
        let sexual: Bool
        
        enum CodingKeys: String, CodingKey {
            case hate
            case harassment
            case violence
            case selfHarm = "self-harm"
            case sexual
        }
    }
    
    struct CategoryScores: Codable {
        let hate: Double
        let harassment: Double
        let violence: Double
        let selfHarm: Double
        let sexual: Double
        
        enum CodingKeys: String, CodingKey {
            case hate
            case harassment
            case violence
            case selfHarm = "self-harm"
            case sexual
        }
    }
}

// MARK: - Error Types
enum OpenAIError: Error, LocalizedError {
    case apiKeyMissing
    case httpError(Int)
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .apiKeyMissing:
            return "OpenAI API key is not configured"
        case .httpError(let code):
            return "OpenAI API returned error code: \(code)"
        case .invalidResponse:
            return "Invalid response from OpenAI API"
        }
    }
}
