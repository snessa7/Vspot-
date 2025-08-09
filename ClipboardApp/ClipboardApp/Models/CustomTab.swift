//
//  CustomTab.swift
//  ClipboardApp
//
//  Model for custom user-defined tabs
//

import Foundation

struct CustomTab: Identifiable, Codable {
    let id: UUID
    var name: String
    var icon: String
    var fields: [CustomField]
    var items: [CustomTabItem]
    var isSecure: Bool
    
    init(
        id: UUID = UUID(),
        name: String,
        icon: String = "folder",
        fields: [CustomField] = [],
        items: [CustomTabItem] = [],
        isSecure: Bool = false
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.fields = fields
        self.items = items
        self.isSecure = isSecure
    }
}

struct CustomField: Identifiable, Codable {
    let id: UUID
    var name: String
    var type: FieldType
    var isRequired: Bool
    var placeholder: String
    var isSecure: Bool
    
    init(
        id: UUID = UUID(),
        name: String,
        type: FieldType,
        isRequired: Bool = false,
        placeholder: String = "",
        isSecure: Bool = false
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.isRequired = isRequired
        self.placeholder = placeholder
        self.isSecure = isSecure
    }
}

struct CustomTabItem: Identifiable, Codable {
    let id: UUID
    var values: [String: String]
    var createdDate: Date
    var modifiedDate: Date
    
    init(
        id: UUID = UUID(),
        values: [String: String] = [:],
        createdDate: Date = Date(),
        modifiedDate: Date = Date()
    ) {
        self.id = id
        self.values = values
        self.createdDate = createdDate
        self.modifiedDate = modifiedDate
    }
}

enum FieldType: String, CaseIterable, Codable {
    case text = "text"
    case multilineText = "multilineText"
    case password = "password"
    case date = "date"
    case dropdown = "dropdown"
    case number = "number"
    
    var displayName: String {
        switch self {
        case .text: return "Text"
        case .multilineText: return "Multi-line Text"
        case .password: return "Password"
        case .date: return "Date"
        case .dropdown: return "Dropdown"
        case .number: return "Number"
        }
    }
}