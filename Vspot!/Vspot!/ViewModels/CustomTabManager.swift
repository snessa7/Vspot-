//
//  CustomTabManager.swift
//  Vspot!
//
//  Manages custom user-created tabs
//

import Foundation
import SwiftUI

class CustomTabManager: ObservableObject {
    static let shared = CustomTabManager()
    
    @Published var customTabs: [CustomTab] = []
    
    private let userDefaultsKey = "customTabs"
    
    init() {
        loadCustomTabs()
        if customTabs.isEmpty {
            createDefaultTabs()
        }
    }
    
    // MARK: - Tab Management
    
    func createTab(name: String, icon: String = "folder", isSecure: Bool = false) -> CustomTab {
        // Create default fields for the new tab
        let defaultFields: [CustomField] = [
            CustomField(name: "Title", type: .text, isRequired: true, placeholder: "Enter title"),
            CustomField(name: "Description", type: .multilineText, placeholder: "Enter description"),
            CustomField(name: "Tags", type: .text, placeholder: "Enter tags (comma separated)")
        ]
        
        let newTab = CustomTab(name: name, icon: icon, fields: defaultFields, isSecure: isSecure)
        customTabs.append(newTab)
        saveCustomTabs()
        return newTab
    }
    
    func reorderTabs(from sourceIndex: Int, to targetIndex: Int) {
        guard sourceIndex >= 0 && sourceIndex < customTabs.count,
              targetIndex >= 0 && targetIndex <= customTabs.count,
              sourceIndex != targetIndex else {
            return
        }
        
        let movedTab = customTabs.remove(at: sourceIndex)
        
        // Calculate the correct insertion index
        let insertIndex: Int
        if targetIndex > sourceIndex {
            // Moving forward: target index decreases by 1 because we removed an element before it
            insertIndex = min(targetIndex - 1, customTabs.count)
        } else {
            // Moving backward: target index stays the same
            insertIndex = targetIndex
        }
        
        // Ensure insertion index is within bounds
        let finalIndex = max(0, min(insertIndex, customTabs.count))
        customTabs.insert(movedTab, at: finalIndex)
        saveCustomTabs()
    }
    
    func updateTab(_ tab: CustomTab, name: String, icon: String) {
        if let index = customTabs.firstIndex(where: { $0.id == tab.id }) {
            customTabs[index].name = name
            customTabs[index].icon = icon
            saveCustomTabs()
        }
    }
    
    func deleteTab(_ tab: CustomTab) {
        customTabs.removeAll { $0.id == tab.id }
        saveCustomTabs()
    }
    
    func getTab(byName name: String) -> CustomTab? {
        return customTabs.first { $0.name == name }
    }
    
    // MARK: - Item Management
    
    func addItem(to tabName: String, values: [String: String]) {
        if let index = customTabs.firstIndex(where: { $0.name == tabName }) {
            let newItem = CustomTabItem(values: values)
            customTabs[index].items.append(newItem)
            saveCustomTabs()
        }
    }
    
    func updateItem(in tabName: String, item: CustomTabItem, values: [String: String]) {
        if let tabIndex = customTabs.firstIndex(where: { $0.name == tabName }),
           let itemIndex = customTabs[tabIndex].items.firstIndex(where: { $0.id == item.id }) {
            customTabs[tabIndex].items[itemIndex].values = values
            customTabs[tabIndex].items[itemIndex].modifiedDate = Date()
            saveCustomTabs()
        }
    }
    
    func deleteItem(from tabName: String, item: CustomTabItem) {
        if let tabIndex = customTabs.firstIndex(where: { $0.name == tabName }) {
            customTabs[tabIndex].items.removeAll { $0.id == item.id }
            saveCustomTabs()
        }
    }
    
    func searchItems(in tabName: String, query: String) -> [CustomTabItem] {
        guard let tab = getTab(byName: tabName) else { return [] }
        
        if query.isEmpty {
            return tab.items
        }
        
        return tab.items.filter { item in
            item.values.values.contains { value in
                value.localizedCaseInsensitiveContains(query)
            }
        }
    }
    
    // MARK: - Field Management
    
    func addField(to tabName: String, field: CustomField) {
        if let index = customTabs.firstIndex(where: { $0.name == tabName }) {
            customTabs[index].fields.append(field)
            saveCustomTabs()
        }
    }
    
    func updateField(in tabName: String, field: CustomField) {
        if let tabIndex = customTabs.firstIndex(where: { $0.name == tabName }),
           let fieldIndex = customTabs[tabIndex].fields.firstIndex(where: { $0.id == field.id }) {
            customTabs[tabIndex].fields[fieldIndex] = field
            saveCustomTabs()
        }
    }
    
    func deleteField(from tabName: String, field: CustomField) {
        if let tabIndex = customTabs.firstIndex(where: { $0.name == tabName }) {
            customTabs[tabIndex].fields.removeAll { $0.id == field.id }
            // Also remove field values from all items
            for itemIndex in customTabs[tabIndex].items.indices {
                customTabs[tabIndex].items[itemIndex].values.removeValue(forKey: field.name)
            }
            saveCustomTabs()
        }
    }
    
    // MARK: - Data Persistence
    
    func loadCustomTabs() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([CustomTab].self, from: data) {
            customTabs = decoded
        }
    }
    
    func saveCustomTabs() {
        if let encoded = try? JSONEncoder().encode(customTabs) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    // MARK: - Default Tabs
    
    private func createDefaultTabs() {
        // Create a sample "Passwords" tab
        let passwordTab = CustomTab(
            name: "Passwords",
            icon: "key.fill",
            fields: [
                CustomField(name: "Title", type: .text, isRequired: true, placeholder: "Website or App Name"),
                CustomField(name: "Username", type: .text, isRequired: true, placeholder: "Enter username or email"),
                CustomField(name: "Password", type: .password, isRequired: true, placeholder: "Enter password", isSecure: true),
                CustomField(name: "URL", type: .text, placeholder: "Website URL"),
                CustomField(name: "Notes", type: .multilineText, placeholder: "Additional notes")
            ],
            isSecure: true
        )
        
        // Create a sample "Code Snippets" tab
        let snippetsTab = CustomTab(
            name: "Code Snippets",
            icon: "chevron.left.forwardslash.chevron.right",
            fields: [
                CustomField(name: "Title", type: .text, isRequired: true, placeholder: "Snippet name"),
                CustomField(name: "Language", type: .text, placeholder: "Programming language"),
                CustomField(name: "Code", type: .multilineText, isRequired: true, placeholder: "Your code snippet"),
                CustomField(name: "Description", type: .multilineText, placeholder: "What does this code do?")
            ]
        )
        
        customTabs = [passwordTab, snippetsTab]
        saveCustomTabs()
    }
}
