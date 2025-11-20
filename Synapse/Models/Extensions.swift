//
//  Extensions.swift
//  Synapse
//
//  Created by Abdulrahman Alshehri on 18/01/1447 AH.
//

import Foundation

extension Date {
    func timeAgoDisplay() -> String {
        let now = Date()
        let timeInterval = now.timeIntervalSince(self)

        // Get the app's selected locale from LocalizationManager
        let appLocale = LocalizationManager.shared.locale

        // If less than 24 hours, show relative time
        if timeInterval < 86400 { // 24 hours
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .full
            formatter.dateTimeStyle = .named
            formatter.locale = appLocale
            return formatter.localizedString(for: self, relativeTo: now)
        } else {
            // If more than 24 hours, show actual date and time
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            formatter.locale = appLocale
            return formatter.string(from: self)
        }
    }
}

extension String {
    func localizedCaseInsensitiveContains(_ other: String) -> Bool {
        return self.range(of: other, options: [.caseInsensitive]) != nil
    }
} 