//
//  ClipboardManager.swift
//  ClipboardApp
//
//  Manages clipboard monitoring and history
//

import Foundation
import AppKit
import Combine

class ClipboardManager: ObservableObject {
    @Published var items: [ClipboardItem] = []
    
    private var pasteboardService: PasteboardService?
    private var cancellables = Set<AnyCancellable>()
    private let maxItems = 100
    
    init() {
        loadItems()
        startMonitoring()
    }
    
    func startMonitoring() {
        pasteboardService = PasteboardService()
        pasteboardService?.startMonitoring { [weak self] content, type in
            self?.addItem(content: content, type: type)
        }
    }
    
    func stopMonitoring() {
        pasteboardService?.stopMonitoring()
    }
    
    func addItem(content: String, type: PasteboardType) {
        // Check for duplicates
        if let existingIndex = items.firstIndex(where: { $0.content == content }) {
            // Move to top if already exists
            let existingItem = items.remove(at: existingIndex)
            items.insert(existingItem, at: 0)
        } else {
            // Add new item
            let newItem = ClipboardItem(content: content, type: type)
            items.insert(newItem, at: 0)
            
            // Maintain max items limit
            if items.count > maxItems {
                items = Array(items.prefix(maxItems))
            }
        }
        
        saveItems()
    }
    
    func copyToPasteboard(_ item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(item.content, forType: .string)
        
        // Move to top of list
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items.remove(at: index)
            items.insert(item, at: 0)
            saveItems()
        }
    }
    
    func toggleFavorite(_ item: ClipboardItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].isFavorite.toggle()
            saveItems()
        }
    }
    
    func deleteItem(_ item: ClipboardItem) {
        items.removeAll { $0.id == item.id }
        saveItems()
    }
    
    func clearAll() {
        items.removeAll()
        saveItems()
    }
    
    private func loadItems() {
        // Load from UserDefaults for now (will use Core Data later)
        if let data = UserDefaults.standard.data(forKey: "clipboardItems"),
           let decoded = try? JSONDecoder().decode([ClipboardItem].self, from: data) {
            items = decoded
        }
    }
    
    private func saveItems() {
        // Save to UserDefaults for now (will use Core Data later)
        if let encoded = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(encoded, forKey: "clipboardItems")
        }
    }
    
    deinit {
        stopMonitoring()
    }
}