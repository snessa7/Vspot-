//
//  ClipboardItem.swift
//  ClipboardApp
//
//  Model for clipboard items
//

import Foundation

struct ClipboardItem: Identifiable, Codable, Equatable {
    let id: UUID
    let content: String
    let type: PasteboardType
    let timestamp: Date
    let preview: String
    var isFavorite: Bool
    var isEncrypted: Bool
    
    init(
        id: UUID = UUID(),
        content: String,
        type: PasteboardType,
        timestamp: Date = Date(),
        isFavorite: Bool = false,
        isEncrypted: Bool = false
    ) {
        self.id = id
        self.content = content
        self.type = type
        self.timestamp = timestamp
        self.isFavorite = isFavorite
        self.isEncrypted = isEncrypted
        
        // Generate preview
        self.preview = Self.generatePreview(from: content, type: type)
    }
    
    private static func generatePreview(from content: String, type: PasteboardType) -> String {
        let maxLength = 100
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.count <= maxLength {
            return trimmed
        } else {
            let index = trimmed.index(trimmed.startIndex, offsetBy: maxLength)
            return String(trimmed[..<index]) + "..."
        }
    }
}

enum PasteboardType: String, CaseIterable, Codable {
    case text = "text"
    case image = "image"
    case url = "url"
    case richText = "richText"
    case file = "file"
    
    var icon: String {
        switch self {
        case .text: return "text.alignleft"
        case .image: return "photo"
        case .url: return "link"
        case .richText: return "text.quote"
        case .file: return "doc"
        }
    }
    
    var displayName: String {
        switch self {
        case .text: return "Text"
        case .image: return "Image"
        case .url: return "URL"
        case .richText: return "Rich Text"
        case .file: return "File"
        }
    }
}