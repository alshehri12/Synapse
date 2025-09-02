//
//  Models.swift
//  Synapse
//
//  Created by Abdulrahman Alshehri on 18/01/1447 AH.
//

import Foundation

// MARK: - User Profile Model
struct UserProfile: Identifiable, Codable {
    let id: String
    var username: String
    var email: String
    var bio: String?
    var avatarURL: String?
    var skills: [String]
    var interests: [String]
    var ideasSparked: Int
    var projectsContributed: Int
    var dateJoined: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case email
        case bio
        case avatarURL
        case skills
        case interests
        case ideasSparked
        case projectsContributed
        case dateJoined
    }
}

// MARK: - Idea Spark Model
struct IdeaSpark: Identifiable, Codable {
    let id: String
    let authorId: String
    let authorUsername: String
    let title: String
    let description: String
    let tags: [String]
    let isPublic: Bool
    let createdAt: Date
    let updatedAt: Date
    var likes: Int
    var comments: Int
    var status: IdeaStatus
    
    enum IdeaStatus: String, Codable, CaseIterable {
        case planning = "planning"
        case sparking = "sparking"
        case incubating = "incubating"
        case launched = "launched"
        case completed = "completed"
        case onHold = "on_hold"
        case cancelled = "cancelled"
    }
}

// MARK: - Incubation Project Model
struct IncubationProject: Identifiable, Codable {
    let id: String
    let ideaId: String
    let name: String
    let description: String
    let creatorId: String
    let isPublic: Bool
    let createdAt: Date
    let updatedAt: Date
    var members: [ProjectMember]
    var tasks: [ProjectTask]
    var status: ProjectStatus
    
    enum ProjectStatus: String, Codable, CaseIterable {
        case planning = "planning"
        case active = "active"
        case completed = "completed"
        case onHold = "on_hold"
    }
}

// MARK: - Project Member Model
struct ProjectMember: Identifiable, Codable {
    let id: String
    let userId: String
    let username: String
    let role: String
    let joinedAt: Date
    let permissions: [Permission]
    
    enum Permission: String, Codable, CaseIterable {
        case admin = "admin"
        case edit = "edit"
        case view = "view"
        case comment = "comment"
    }
}

// MARK: - Project Task Model
struct ProjectTask: Identifiable, Codable {
    let id: String
    let title: String
    let description: String?
    let assignedTo: String?
    let assignedToUsername: String?
    let dueDate: Date?
    let createdAt: Date
    let updatedAt: Date
    var status: TaskStatus
    var priority: TaskPriority
    
    enum TaskStatus: String, Codable, CaseIterable {
        case todo = "todo"
        case inProgress = "in_progress"
        case completed = "completed"
        case cancelled = "cancelled"
        
        var displayName: String {
            switch self {
            case .todo: return "To Do"
            case .inProgress: return "In Progress"
            case .completed: return "Completed"
            case .cancelled: return "Cancelled"
            }
        }
    }
    
    enum TaskPriority: String, Codable, CaseIterable {
        case low = "low"
        case medium = "medium"
        case high = "high"
        case urgent = "urgent"
        
        var displayName: String {
            switch self {
            case .low: return "Low"
            case .medium: return "Medium"
            case .high: return "High"
            case .urgent: return "Urgent"
            }
        }
    }
}

// MARK: - Message Model
struct Message: Identifiable, Codable {
    let id: String
    let projectId: String
    let senderId: String
    let senderUsername: String
    let content: String
    let timestamp: Date
    let messageType: MessageType
    
    enum MessageType: String, Codable {
        case text = "text"
        case taskUpdate = "task_update"
        case memberJoined = "member_joined"
        case memberLeft = "member_left"
    }
}

// MARK: - App Notification Model
struct AppNotification: Identifiable, Codable {
    let id: String
    let userId: String
    let type: NotificationType
    let message: String
    var isRead: Bool
    let timestamp: Date
    
    // Additional properties for specific notification types
    var relatedId: String? // e.g., taskId, projectId, commentId
    var podInvitation: PodInvitation?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case type
        case message
        case isRead
        case timestamp
        case relatedId
    }
    
    enum NotificationType: String, Codable, CaseIterable {
        case projectInvite = "project_invite"
        case projectJoined = "project_joined"
        case taskAssigned = "task_assigned"
        case taskCompleted = "task_completed"
        case mention = "mention"
        case like = "like"
        case comment = "comment"
    }
}

// MARK: - Mock Data
let mockUser = UserProfile(
    id: "user1",
    username: "AlexChen",
    email: "alex.chen@example.com",
    bio: "Passionate about creating innovative solutions that make a difference. Full-stack developer with a love for AI and education technology.",
    avatarURL: nil,
    skills: ["Swift", "Python", "Firebase", "UI/UX Design", "Project Management"],
    interests: ["AI", "Education", "Sustainability", "Mobile Development", "Open Source"],
    ideasSparked: 3,
    projectsContributed: 7,
    dateJoined: Date().addingTimeInterval(-7776000) // 90 days ago
) 

// MARK: - Chat Models
struct ChatMessage: Identifiable, Codable {
    let id: String
    let projectId: String
    let senderId: String
    let senderName: String
    let senderAvatar: String?
    let content: String
    let messageType: MessageType
    let timestamp: Date
    let isEdited: Bool
    let replyTo: String?
    
    enum MessageType: String, Codable {
        case text
        case image
        case file
        case system
    }
}

struct ChatRoom: Identifiable, Codable {
    let id: String
    let projectId: String
    let name: String
    let lastMessage: ChatMessage?
    let lastActivity: Date
    let memberCount: Int
    let isActive: Bool
}

struct TypingIndicator: Codable {
    let userId: String
    let userName: String
    let timestamp: Date
}

struct MessageReaction: Codable {
    let userId: String
    let reaction: String
    let timestamp: Date
}

// MARK: - Invitation Models
struct PodInvitation: Identifiable, Codable {
    let id: String
    let podId: String
    let inviterId: String
    let inviteeId: String
    let status: String // pending, accepted, declined
    let createdAt: Date
}

// MARK: - Analytics Models
struct TaskProgressData: Identifiable, Codable {
    let id = UUID()
    let date: Date
    let value: Int
}

struct TopContributor: Identifiable, Codable {
    let id = UUID()
    let username: String
    let tasksCompleted: Int
    let contributionPercentage: Double
}

struct MemberActivityData: Identifiable, Codable {
    let id = UUID()
    let member: String
    let tasksCompleted: Int
}

struct ProjectAnalytics: Codable {
    let completionRate: Int
    let activeMembers: Int
    let tasksCompleted: Int
    let totalTasks: Int
    let avgResponseTime: Int
    let taskProgress: [TaskProgressData]
    let memberActivity: [MemberActivityData]
    let topContributors: [TopContributor]
} 