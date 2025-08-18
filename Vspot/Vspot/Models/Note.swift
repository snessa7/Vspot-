//
//  Note.swift
//  Vspot
//
//  Model for sticky notes
//

import Foundation
import SwiftUI

struct Note: Identifiable, Codable {
    let id: UUID
    var title: String
    var content: String
    var color: NoteColor
    var timestamp: Date
    var lastModified: Date
    var tags: [String]
    var isEncrypted: Bool
    
    init(
        id: UUID = UUID(),
        title: String,
        content: String,
        color: NoteColor = .yellow,
        timestamp: Date = Date(),
        lastModified: Date = Date(),
        tags: [String] = [],
        isEncrypted: Bool = false
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.color = color
        self.timestamp = timestamp
        self.lastModified = lastModified
        self.tags = tags
        self.isEncrypted = isEncrypted
    }
}

enum NoteColor: String, CaseIterable, Codable {
    case yellow = "yellow"
    case blue = "blue"
    case green = "green"
    case pink = "pink"
    case purple = "purple"
    case orange = "orange"
    case gray = "gray"
    
    var backgroundColor: Color {
        switch self {
        case .yellow: return Color.yellow.opacity(0.3)
        case .blue: return Color.blue.opacity(0.3)
        case .green: return Color.green.opacity(0.3)
        case .pink: return Color.pink.opacity(0.3)
        case .purple: return Color.purple.opacity(0.3)
        case .orange: return Color.orange.opacity(0.3)
        case .gray: return Color.gray.opacity(0.3)
        }
    }
}