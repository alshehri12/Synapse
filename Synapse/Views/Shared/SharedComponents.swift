//
//  SharedComponents.swift
//  Synapse
//
//  Created for shared UI components
//

import SwiftUI

// MARK: - Filter Chip
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : Color.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentGreen : Color.backgroundPrimary)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.accentGreen.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

// MARK: - App Alert Banner
struct AppAlertBanner: View {
    enum Style { case info, success, warning, error }
    let title: String
    let message: String
    let style: Style
    let onClose: (() -> Void)?
    
    private var backgroundColor: Color {
        switch style {
        case .info: return Color.accentBlue.opacity(0.1)
        case .success: return Color.accentGreen.opacity(0.1)
        case .warning: return Color.accentOrange.opacity(0.12)
        case .error: return Color.error.opacity(0.1)
        }
    }
    
    private var accentColor: Color {
        switch style {
        case .info: return Color.accentBlue
        case .success: return Color.accentGreen
        case .warning: return Color.accentOrange
        case .error: return Color.error
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(accentColor)
                .frame(width: 10, height: 10)
                .padding(.top, 6)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.textPrimary)
                Text(message)
                    .font(.system(size: 13))
                    .foregroundColor(Color.textSecondary)
            }
            
            Spacer()
            
            if let onClose = onClose {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color.textSecondary)
                        .padding(6)
                        .background(Color.backgroundPrimary)
                        .clipShape(Circle())
                }
            }
        }
        .padding(16)
        .background(backgroundColor)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(accentColor.opacity(0.2), lineWidth: 1)
        )
        .cornerRadius(12)
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(Color.textSecondary)
            
            Text(title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Color.textPrimary)
            
            Text(message)
                .font(.system(size: 16))
                .foregroundColor(Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.vertical, 60)
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Color.textPrimary)
            
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.backgroundPrimary)
        .cornerRadius(12)
    }
}

// MARK: - Tag View
struct TagView: View {
    let tag: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            Text("#\(tag)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.accentGreen)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(Color.textSecondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.accentGreen.opacity(0.1))
        .cornerRadius(12)
    }
} 