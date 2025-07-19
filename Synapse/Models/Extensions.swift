//
//  Extensions.swift
//  Synapse
//
//  Created by Abdulrahman Alshehri on 18/01/1447 AH.
//

import Foundation

extension Date {
    func timeAgoDisplay() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

extension String {
    func localizedCaseInsensitiveContains(_ other: String) -> Bool {
        return self.range(of: other, options: [.caseInsensitive]) != nil
    }
} 