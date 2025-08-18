//
//  AIPrompt.swift
//  Vspot
//
//  AI Prompt model for storing frequently used prompts
//

import Foundation

struct AIPrompt: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var content: String
    var category: PromptCategory
    var tags: [String]
    var isFavorite: Bool
    var useCount: Int
    var dateCreated: Date
    var dateModified: Date
    
    init(title: String, content: String, category: PromptCategory = .general, tags: [String] = [], isFavorite: Bool = false) {
        self.title = title
        self.content = content
        self.category = category
        self.tags = tags
        self.isFavorite = isFavorite
        self.useCount = 0
        self.dateCreated = Date()
        self.dateModified = Date()
    }
    
    mutating func incrementUseCount() {
        useCount += 1
        dateModified = Date()
    }
    
    mutating func updateContent(title: String, content: String, category: PromptCategory, tags: [String]) {
        self.title = title
        self.content = content
        self.category = category
        self.tags = tags
        self.dateModified = Date()
    }
}

enum PromptCategory: String, CaseIterable, Codable {
    case general = "General"
    case coding = "Coding"
    case writing = "Writing" 
    case analysis = "Analysis"
    case creative = "Creative"
    case productivity = "Productivity"
    case research = "Research"
    case debugging = "Debugging"
    case review = "Code Review"
    case documentation = "Documentation"
    
    var icon: String {
        switch self {
        case .general: return "sparkles"
        case .coding: return "chevron.left.forwardslash.chevron.right"
        case .writing: return "pencil.and.outline"
        case .analysis: return "chart.bar.xaxis"
        case .creative: return "paintbrush"
        case .productivity: return "checkmark.circle"
        case .research: return "magnifyingglass"
        case .debugging: return "ant"
        case .review: return "checklist"
        case .documentation: return "doc.text"
        }
    }
    
    var color: String {
        switch self {
        case .general: return "blue"
        case .coding: return "green"
        case .writing: return "purple"
        case .analysis: return "orange"
        case .creative: return "pink"
        case .productivity: return "indigo"
        case .research: return "teal"
        case .debugging: return "red"
        case .review: return "yellow"
        case .documentation: return "gray"
        }
    }
}