//
//  CoreDataManager.swift
//  Vspot
//
//  Core Data stack and management
//

import Foundation
import CoreData
import Combine

class CoreDataManager: ObservableObject {
    static let shared = CoreDataManager()
    
    // MARK: - Core Data Stack
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Vspot")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data store failed to load: \(error.localizedDescription)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // MARK: - Initialization
    
    private init() {
        // Perform initial data migration if needed
        performInitialMigrationIfNeeded()
    }
    
    // MARK: - Core Data Operations
    
    func save() {
        let context = persistentContainer.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Core Data save error: \(error)")
                // In production, this should be logged and handled appropriately
            }
        }
    }
    
    func delete(_ object: NSManagedObject) {
        context.delete(object)
        save()
    }
    
    func rollback() {
        context.rollback()
    }
    
    // MARK: - Data Migration
    
    private func performInitialMigrationIfNeeded() {
        let hasMigrated = UserDefaults.standard.bool(forKey: "hasMigratedToCoreData")
        
        if !hasMigrated {
            migrateFromUserDefaults()
            UserDefaults.standard.set(true, forKey: "hasMigratedToCoreData")
        }
    }
    
    private func migrateFromUserDefaults() {
        print("Starting migration from UserDefaults to Core Data...")
        
        // Migrate Clipboard Items
        migrateClipboardItems()
        
        // Migrate Notes
        migrateNotes()
        
        // Migrate AI Prompts
        migrateAIPrompts()
        
        // Migrate Custom Tabs
        migrateCustomTabs()
        
        save()
        print("Migration completed successfully")
    }
    
    private func migrateClipboardItems() {
        guard let data = UserDefaults.standard.data(forKey: "clipboardItems"),
              let items = try? JSONDecoder().decode([ClipboardItem].self, from: data) else {
            return
        }
        
        for item in items {
            let cdItem = CDClipboardItem(context: context)
            cdItem.id = item.id
            cdItem.content = item.content
            cdItem.type = item.type.rawValue
            cdItem.preview = item.preview
            cdItem.isFavorite = item.isFavorite
            cdItem.isEncrypted = item.isEncrypted
            cdItem.createdAt = item.timestamp
            cdItem.updatedAt = item.timestamp
        }
    }
    
    private func migrateNotes() {
        guard let data = UserDefaults.standard.data(forKey: "stickyNotes"),
              let notes = try? JSONDecoder().decode([Note].self, from: data) else {
            return
        }
        
        for note in notes {
            let cdNote = CDNote(context: context)
            cdNote.id = note.id
            cdNote.title = note.title
            cdNote.content = note.content
            cdNote.color = note.color.rawValue
            cdNote.tags = note.tags
            cdNote.isEncrypted = note.isEncrypted
            cdNote.createdAt = note.timestamp
            cdNote.lastModified = note.lastModified
        }
    }
    
    private func migrateAIPrompts() {
        guard let data = UserDefaults.standard.data(forKey: "aiPrompts"),
              let prompts = try? JSONDecoder().decode([AIPrompt].self, from: data) else {
            return
        }
        
        for prompt in prompts {
            let cdPrompt = CDAIPrompt(context: context)
            cdPrompt.id = prompt.id
            cdPrompt.title = prompt.title
            cdPrompt.content = prompt.content
            cdPrompt.category = prompt.category.rawValue
            cdPrompt.tags = prompt.tags
            cdPrompt.isFavorite = prompt.isFavorite
            cdPrompt.useCount = Int32(prompt.useCount)
            cdPrompt.createdAt = prompt.dateCreated
        }
    }
    
    private func migrateCustomTabs() {
        guard let data = UserDefaults.standard.data(forKey: "customTabs"),
              let tabs = try? JSONDecoder().decode([CustomTab].self, from: data) else {
            return
        }
        
        for tab in tabs {
            let cdTab = CDCustomTab(context: context)
            cdTab.id = tab.id
            cdTab.name = tab.name
            cdTab.isSecure = tab.isSecure
            cdTab.order = 0
            cdTab.createdAt = Date()
        }
    }
    
    // MARK: - Data Export/Import
    
    func exportData() -> Data? {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest()
        
        var allData: [String: Any] = [:]
        
        // Export Clipboard Items
        fetchRequest.entity = NSEntityDescription.entity(forEntityName: "CDClipboardItem", in: context)
        if let clipboardItems = try? context.fetch(fetchRequest) as? [CDClipboardItem] {
            let itemsData = clipboardItems.map { item -> [String: Any] in
                var itemDict: [String: Any] = [:]
                itemDict["id"] = item.id?.uuidString ?? ""
                itemDict["content"] = item.content ?? ""
                itemDict["type"] = item.type ?? ""
                itemDict["preview"] = item.preview ?? ""
                itemDict["isFavorite"] = item.isFavorite
                itemDict["isEncrypted"] = item.isEncrypted
                itemDict["createdAt"] = item.createdAt?.timeIntervalSince1970 ?? 0
                itemDict["updatedAt"] = item.updatedAt?.timeIntervalSince1970 ?? 0
                return itemDict
            }
            allData["clipboardItems"] = itemsData
        }
        
        // Export Notes
        fetchRequest.entity = NSEntityDescription.entity(forEntityName: "CDNote", in: context)
        if let notes = try? context.fetch(fetchRequest) as? [CDNote] {
            let notesData = notes.map { note -> [String: Any] in
                var noteDict: [String: Any] = [:]
                noteDict["id"] = note.id?.uuidString ?? ""
                noteDict["title"] = note.title ?? ""
                noteDict["content"] = note.content ?? ""
                noteDict["color"] = note.color ?? ""
                noteDict["tags"] = note.tags ?? []
                noteDict["isEncrypted"] = note.isEncrypted
                noteDict["createdAt"] = note.createdAt?.timeIntervalSince1970 ?? 0
                noteDict["lastModified"] = note.lastModified?.timeIntervalSince1970 ?? 0
                return noteDict
            }
            allData["notes"] = notesData
        }
        
        // Export AI Prompts
        fetchRequest.entity = NSEntityDescription.entity(forEntityName: "CDAIPrompt", in: context)
        if let prompts = try? context.fetch(fetchRequest) as? [CDAIPrompt] {
            let promptsData = prompts.map { prompt -> [String: Any] in
                var promptDict: [String: Any] = [:]
                promptDict["id"] = prompt.id?.uuidString ?? ""
                promptDict["title"] = prompt.title ?? ""
                promptDict["content"] = prompt.content ?? ""
                promptDict["category"] = prompt.category ?? ""
                promptDict["tags"] = prompt.tags ?? []
                promptDict["isFavorite"] = prompt.isFavorite
                promptDict["isEncrypted"] = prompt.isEncrypted
                promptDict["useCount"] = prompt.useCount
                promptDict["createdAt"] = prompt.createdAt?.timeIntervalSince1970 ?? 0
                return promptDict
            }
            allData["aiPrompts"] = promptsData
        }
        
        // Export Custom Tabs
        fetchRequest.entity = NSEntityDescription.entity(forEntityName: "CDCustomTab", in: context)
        if let tabs = try? context.fetch(fetchRequest) as? [CDCustomTab] {
            let tabsData = tabs.map { tab -> [String: Any] in
                var tabDict: [String: Any] = [:]
                tabDict["id"] = tab.id?.uuidString ?? ""
                tabDict["name"] = tab.name ?? ""
                tabDict["fields"] = tab.fields ?? []
                tabDict["values"] = tab.values ?? []
                tabDict["isSecure"] = tab.isSecure
                tabDict["isEncrypted"] = tab.isEncrypted
                tabDict["order"] = tab.order
                tabDict["createdAt"] = tab.createdAt?.timeIntervalSince1970 ?? 0
                return tabDict
            }
            allData["customTabs"] = tabsData
        }
        
        return try? JSONSerialization.data(withJSONObject: allData, options: .prettyPrinted)
    }
    
    func importData(_ data: Data) throws {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw CoreDataError.invalidDataFormat
        }
        
        // Clear existing data
        clearAllData()
        
        // Import Clipboard Items
        if let clipboardItems = json["clipboardItems"] as? [[String: Any]] {
            for itemData in clipboardItems {
                let item = CDClipboardItem(context: context)
                item.id = UUID(uuidString: itemData["id"] as? String ?? "")
                item.content = itemData["content"] as? String ?? ""
                item.type = itemData["type"] as? String ?? ""
                item.preview = itemData["preview"] as? String ?? ""
                item.isFavorite = itemData["isFavorite"] as? Bool ?? false
                item.isEncrypted = itemData["isEncrypted"] as? Bool ?? false
                item.createdAt = Date(timeIntervalSince1970: itemData["createdAt"] as? TimeInterval ?? 0)
                item.updatedAt = Date(timeIntervalSince1970: itemData["updatedAt"] as? TimeInterval ?? 0)
            }
        }
        
        // Import Notes
        if let notes = json["notes"] as? [[String: Any]] {
            for noteData in notes {
                let note = CDNote(context: context)
                note.id = UUID(uuidString: noteData["id"] as? String ?? "")
                note.title = noteData["title"] as? String ?? ""
                note.content = noteData["content"] as? String ?? ""
                note.color = noteData["color"] as? String ?? ""
                note.tags = noteData["tags"] as? [String] ?? []
                note.isEncrypted = noteData["isEncrypted"] as? Bool ?? false
                note.createdAt = Date(timeIntervalSince1970: noteData["createdAt"] as? TimeInterval ?? 0)
                note.lastModified = Date(timeIntervalSince1970: noteData["lastModified"] as? TimeInterval ?? 0)
            }
        }
        
        // Import AI Prompts
        if let prompts = json["aiPrompts"] as? [[String: Any]] {
            for promptData in prompts {
                let prompt = CDAIPrompt(context: context)
                prompt.id = UUID(uuidString: promptData["id"] as? String ?? "")
                prompt.title = promptData["title"] as? String ?? ""
                prompt.content = promptData["content"] as? String ?? ""
                prompt.category = promptData["category"] as? String ?? ""
                prompt.tags = promptData["tags"] as? [String] ?? []
                prompt.isFavorite = promptData["isFavorite"] as? Bool ?? false
                prompt.isEncrypted = promptData["isEncrypted"] as? Bool ?? false
                prompt.useCount = Int32(promptData["useCount"] as? Int ?? 0)
                prompt.createdAt = Date(timeIntervalSince1970: promptData["createdAt"] as? TimeInterval ?? 0)
            }
        }
        
        // Import Custom Tabs
        if let tabs = json["customTabs"] as? [[String: Any]] {
            for tabData in tabs {
                let tab = CDCustomTab(context: context)
                tab.id = UUID(uuidString: tabData["id"] as? String ?? "")
                tab.name = tabData["name"] as? String ?? ""
                tab.fields = tabData["fields"] as? [String] ?? []
                tab.values = tabData["values"] as? [String] ?? []
                tab.isSecure = tabData["isSecure"] as? Bool ?? false
                tab.isEncrypted = tabData["isEncrypted"] as? Bool ?? false
                tab.order = Int32(tabData["order"] as? Int ?? 0)
                tab.createdAt = Date(timeIntervalSince1970: tabData["createdAt"] as? TimeInterval ?? 0)
            }
        }
        
        save()
    }
    
    private func clearAllData() {
        let entities = ["CDClipboardItem", "CDNote", "CDAIPrompt", "CDCustomTab"]
        
        for entityName in entities {
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest()
            fetchRequest.entity = NSEntityDescription.entity(forEntityName: entityName, in: context)
            
            if let objects = try? context.fetch(fetchRequest) as? [NSManagedObject] {
                for object in objects {
                    context.delete(object)
                }
            }
        }
    }
}

// MARK: - Errors

enum CoreDataError: Error, LocalizedError {
    case invalidDataFormat
    case saveFailed
    case fetchFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidDataFormat:
            return "Invalid data format for import"
        case .saveFailed:
            return "Failed to save data"
        case .fetchFailed:
            return "Failed to fetch data"
        }
    }
}
