//
//  ClipboardManager.swift
//  Vspot
//
//  Manages clipboard monitoring and history with Core Data
//

import Foundation
import AppKit
import Combine
import CoreData

class ClipboardManager: ObservableObject {
    @Published var items: [ClipboardItem] = []
    
    private var pasteboardService: PasteboardService?
    private var cancellables = Set<AnyCancellable>()
    private let maxItems = 100
    private let coreDataManager = CoreDataManager.shared
    
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
        // Check for duplicates in Core Data
        let fetchRequest: NSFetchRequest<CDClipboardItem> = CDClipboardItem.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "content == %@", content)
        
        do {
            let existingItems = try coreDataManager.context.fetch(fetchRequest)
            
            if let existingItem = existingItems.first {
                // Update existing item timestamp
                existingItem.updatedAt = Date()
                coreDataManager.save()
                
                // Reload items to reflect changes
                loadItems()
            } else {
                // Create new item in Core Data
                let cdItem = CDClipboardItem(context: coreDataManager.context)
                cdItem.id = UUID()
                cdItem.content = content
                cdItem.type = type.rawValue
                cdItem.preview = ClipboardItem.generatePreview(from: content, type: type)
                cdItem.isFavorite = false
                cdItem.isEncrypted = false
                cdItem.createdAt = Date()
                cdItem.updatedAt = Date()
                
                coreDataManager.save()
                
                // Reload items to reflect changes
                loadItems()
                
                // Maintain max items limit
                if items.count > maxItems {
                    // Delete oldest items from Core Data
                    let oldestFetchRequest: NSFetchRequest<CDClipboardItem> = CDClipboardItem.fetchRequest()
                    oldestFetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CDClipboardItem.updatedAt, ascending: true)]
                    oldestFetchRequest.fetchLimit = items.count - maxItems
                    
                    if let oldestItems = try? coreDataManager.context.fetch(oldestFetchRequest) {
                        for item in oldestItems {
                            coreDataManager.context.delete(item)
                        }
                        coreDataManager.save()
                        loadItems()
                    }
                }
            }
        } catch {
            print("Error adding clipboard item: \(error)")
        }
    }
    
    func copyToPasteboard(_ item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(item.content, forType: .string)
        
        // Update timestamp in Core Data to move to top
        let fetchRequest: NSFetchRequest<CDClipboardItem> = CDClipboardItem.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", item.id as CVarArg)
        
        do {
            if let cdItem = try coreDataManager.context.fetch(fetchRequest).first {
                cdItem.updatedAt = Date()
                coreDataManager.save()
                loadItems()
            }
        } catch {
            print("Error updating clipboard item: \(error)")
        }
    }
    
    func toggleFavorite(_ item: ClipboardItem) {
        let fetchRequest: NSFetchRequest<CDClipboardItem> = CDClipboardItem.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", item.id as CVarArg)
        
        do {
            if let cdItem = try coreDataManager.context.fetch(fetchRequest).first {
                cdItem.isFavorite.toggle()
                coreDataManager.save()
                loadItems()
            }
        } catch {
            print("Error toggling favorite: \(error)")
        }
    }
    
    func deleteItem(_ item: ClipboardItem) {
        let fetchRequest: NSFetchRequest<CDClipboardItem> = CDClipboardItem.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", item.id as CVarArg)
        
        do {
            if let cdItem = try coreDataManager.context.fetch(fetchRequest).first {
                coreDataManager.context.delete(cdItem)
                coreDataManager.save()
                loadItems()
            }
        } catch {
            print("Error deleting clipboard item: \(error)")
        }
    }
    
    func clearAll() {
        let fetchRequest: NSFetchRequest<CDClipboardItem> = CDClipboardItem.fetchRequest()
        
        do {
            let allItems = try coreDataManager.context.fetch(fetchRequest)
            for item in allItems {
                coreDataManager.context.delete(item)
            }
            coreDataManager.save()
            loadItems()
        } catch {
            print("Error clearing all items: \(error)")
        }
    }
    
    private func loadItems() {
        let fetchRequest: NSFetchRequest<CDClipboardItem> = CDClipboardItem.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CDClipboardItem.updatedAt, ascending: false)]
        fetchRequest.fetchLimit = maxItems
        
        do {
            let cdItems = try coreDataManager.context.fetch(fetchRequest)
            items = cdItems.compactMap { cdItem in
                guard let id = cdItem.id,
                      let content = cdItem.content,
                      let typeString = cdItem.type,
                      let type = PasteboardType(rawValue: typeString),
                      let _ = cdItem.preview,
                      let _ = cdItem.createdAt,
                      let updatedAt = cdItem.updatedAt else {
                    return nil
                }
                
                return ClipboardItem(
                    id: id,
                    content: content,
                    type: type,
                    timestamp: updatedAt,
                    isFavorite: cdItem.isFavorite,
                    isEncrypted: cdItem.isEncrypted
                )
            }
        } catch {
            print("Error loading clipboard items: \(error)")
        }
    }
    
    private func saveItems() {
        // Core Data automatically saves when context changes
        // This method is kept for compatibility but doesn't need to do anything
        // as the Core Data manager handles saving
    }
    
    deinit {
        stopMonitoring()
    }
}