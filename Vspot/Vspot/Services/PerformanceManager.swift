//
//  PerformanceManager.swift
//  Vspot
//
//  Performance optimization and management
//

import Foundation
import CoreData
import Combine

class PerformanceManager: ObservableObject {
    static let shared = PerformanceManager()
    
    // MARK: - Properties
    
    private let pageSize = 50
    private var searchIndex: [String: [UUID]] = [:]
    private var lastSearchUpdate: Date = Date()
    private let searchIndexUpdateInterval: TimeInterval = 300 // 5 minutes
    
    // MARK: - Pagination
    
    struct PaginationResult<T> {
        let items: [T]
        let hasMore: Bool
        let totalCount: Int
        let currentPage: Int
    }
    
    func fetchClipboardItems(page: Int = 0, searchQuery: String? = nil) -> PaginationResult<ClipboardItem> {
        let fetchRequest: NSFetchRequest<CDClipboardItem> = CDClipboardItem.fetchRequest()
        
        // Apply search filter if provided
        if let query = searchQuery, !query.isEmpty {
            fetchRequest.predicate = NSPredicate(format: "content CONTAINS[cd] %@ OR preview CONTAINS[cd] %@", query, query)
        }
        
        // Sort by most recent
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CDClipboardItem.updatedAt, ascending: false)]
        
        // Apply pagination
        fetchRequest.fetchOffset = page * pageSize
        fetchRequest.fetchLimit = pageSize
        
        do {
            let cdItems = try CoreDataManager.shared.context.fetch(fetchRequest)
            let items = cdItems.compactMap { (cdItem: CDClipboardItem) -> ClipboardItem? in
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
            
            // Check if there are more items
            let totalFetchRequest: NSFetchRequest<CDClipboardItem> = CDClipboardItem.fetchRequest()
            if let query = searchQuery, !query.isEmpty {
                totalFetchRequest.predicate = NSPredicate(format: "content CONTAINS[cd] %@ OR preview CONTAINS[cd] %@", query, query)
            }
            let totalCount = try CoreDataManager.shared.context.count(for: totalFetchRequest)
            
            return PaginationResult(
                items: items,
                hasMore: (page + 1) * pageSize < totalCount,
                totalCount: totalCount,
                currentPage: page
            )
        } catch {
            print("Error fetching clipboard items: \(error)")
            return PaginationResult(items: [], hasMore: false, totalCount: 0, currentPage: page)
        }
    }
    
    func fetchNotes(page: Int = 0, searchQuery: String? = nil) -> PaginationResult<Note> {
        let fetchRequest: NSFetchRequest<CDNote> = CDNote.fetchRequest()
        
        // Apply search filter if provided
        if let query = searchQuery, !query.isEmpty {
            fetchRequest.predicate = NSPredicate(format: "title CONTAINS[cd] %@ OR content CONTAINS[cd] %@", query, query)
        }
        
        // Sort by most recent
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CDNote.lastModified, ascending: false)]
        
        // Apply pagination
        fetchRequest.fetchOffset = page * pageSize
        fetchRequest.fetchLimit = pageSize
        
        do {
            let cdNotes = try CoreDataManager.shared.context.fetch(fetchRequest)
            let notes = cdNotes.compactMap { (cdNote: CDNote) -> Note? in
                guard let id = cdNote.id,
                      let title = cdNote.title,
                      let content = cdNote.content,
                      let colorString = cdNote.color,
                      let color = NoteColor(rawValue: colorString),
                      let createdAt = cdNote.createdAt,
                      let lastModified = cdNote.lastModified else {
                    return nil
                }
                
                return Note(
                    id: id,
                    title: title,
                    content: content,
                    color: color,
                    timestamp: createdAt,
                    lastModified: lastModified,
                    tags: cdNote.tags ?? [],
                    isEncrypted: cdNote.isEncrypted
                )
            }
            
            // Check if there are more items
            let totalFetchRequest: NSFetchRequest<CDNote> = CDNote.fetchRequest()
            if let query = searchQuery, !query.isEmpty {
                totalFetchRequest.predicate = NSPredicate(format: "title CONTAINS[cd] %@ OR content CONTAINS[cd] %@", query, query)
            }
            let totalCount = try CoreDataManager.shared.context.count(for: totalFetchRequest)
            
            return PaginationResult(
                items: notes,
                hasMore: (page + 1) * pageSize < totalCount,
                totalCount: totalCount,
                currentPage: page
            )
        } catch {
            print("Error fetching notes: \(error)")
            return PaginationResult(items: [], hasMore: false, totalCount: 0, currentPage: page)
        }
    }
    
    func fetchAIPrompts(page: Int = 0, searchQuery: String? = nil, category: PromptCategory? = nil) -> PaginationResult<AIPrompt> {
        let fetchRequest: NSFetchRequest<CDAIPrompt> = CDAIPrompt.fetchRequest()
        
        var predicates: [NSPredicate] = []
        
        // Apply search filter if provided
        if let query = searchQuery, !query.isEmpty {
            predicates.append(NSPredicate(format: "title CONTAINS[cd] %@ OR content CONTAINS[cd] %@", query, query))
        }
        
        // Apply category filter if provided
        if let category = category {
            predicates.append(NSPredicate(format: "category == %@", category.rawValue))
        }
        
        // Combine predicates
        if !predicates.isEmpty {
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }
        
        // Sort by most recent
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CDAIPrompt.createdAt, ascending: false)]
        
        // Apply pagination
        fetchRequest.fetchOffset = page * pageSize
        fetchRequest.fetchLimit = pageSize
        
        do {
            let cdPrompts = try CoreDataManager.shared.context.fetch(fetchRequest)
            let prompts = cdPrompts.compactMap { (cdPrompt: CDAIPrompt) -> AIPrompt? in
                guard let id = cdPrompt.id,
                      let title = cdPrompt.title,
                      let content = cdPrompt.content,
                      let categoryString = cdPrompt.category,
                      let category = PromptCategory(rawValue: categoryString),
                      let createdAt = cdPrompt.createdAt else {
                    return nil
                }
                
                var prompt = AIPrompt(
                    title: title,
                    content: content,
                    category: category,
                    tags: cdPrompt.tags ?? [],
                    isFavorite: cdPrompt.isFavorite
                )
                prompt.id = id
                prompt.useCount = Int(cdPrompt.useCount)
                prompt.dateCreated = createdAt
                prompt.dateModified = createdAt
                return prompt
            }
            
            // Check if there are more items
            let totalFetchRequest: NSFetchRequest<CDAIPrompt> = CDAIPrompt.fetchRequest()
            if !predicates.isEmpty {
                totalFetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            }
            let totalCount = try CoreDataManager.shared.context.count(for: totalFetchRequest)
            
            return PaginationResult(
                items: prompts,
                hasMore: (page + 1) * pageSize < totalCount,
                totalCount: totalCount,
                currentPage: page
            )
        } catch {
            print("Error fetching AI prompts: \(error)")
            return PaginationResult(items: [], hasMore: false, totalCount: 0, currentPage: page)
        }
    }
    
    // MARK: - Search Indexing
    
    func updateSearchIndex() {
        let now = Date()
        guard now.timeIntervalSince(lastSearchUpdate) > searchIndexUpdateInterval else {
            return
        }
        
        lastSearchUpdate = now
        
        // Update clipboard items index
        updateClipboardSearchIndex()
        
        // Update notes index
        updateNotesSearchIndex()
        
        // Update AI prompts index
        updateAIPromptsSearchIndex()
    }
    
    private func updateClipboardSearchIndex() {
        let fetchRequest: NSFetchRequest<CDClipboardItem> = CDClipboardItem.fetchRequest()
        
        do {
            let items = try CoreDataManager.shared.context.fetch(fetchRequest)
            
            for item in items {
                guard let id = item.id,
                      let content = item.content,
                      let preview = item.preview else {
                    continue
                }
                
                let searchableText = "\(content) \(preview)".lowercased()
                let words = searchableText.components(separatedBy: .whitespacesAndNewlines)
                
                for word in words {
                    let cleanWord = word.trimmingCharacters(in: .punctuationCharacters)
                    if cleanWord.count >= 3 {
                        if searchIndex[cleanWord] == nil {
                            searchIndex[cleanWord] = []
                        }
                        if !searchIndex[cleanWord]!.contains(id) {
                            searchIndex[cleanWord]!.append(id)
                        }
                    }
                }
            }
        } catch {
            print("Error updating clipboard search index: \(error)")
        }
    }
    
    private func updateNotesSearchIndex() {
        let fetchRequest: NSFetchRequest<CDNote> = CDNote.fetchRequest()
        
        do {
            let notes = try CoreDataManager.shared.context.fetch(fetchRequest)
            
            for note in notes {
                guard let id = note.id,
                      let title = note.title,
                      let content = note.content else {
                    continue
                }
                
                let searchableText = "\(title) \(content)".lowercased()
                let words = searchableText.components(separatedBy: .whitespacesAndNewlines)
                
                for word in words {
                    let cleanWord = word.trimmingCharacters(in: .punctuationCharacters)
                    if cleanWord.count >= 3 {
                        if searchIndex[cleanWord] == nil {
                            searchIndex[cleanWord] = []
                        }
                        if !searchIndex[cleanWord]!.contains(id) {
                            searchIndex[cleanWord]!.append(id)
                        }
                    }
                }
            }
        } catch {
            print("Error updating notes search index: \(error)")
        }
    }
    
    private func updateAIPromptsSearchIndex() {
        let fetchRequest: NSFetchRequest<CDAIPrompt> = CDAIPrompt.fetchRequest()
        
        do {
            let prompts = try CoreDataManager.shared.context.fetch(fetchRequest)
            
            for prompt in prompts {
                guard let id = prompt.id,
                      let title = prompt.title,
                      let content = prompt.content else {
                    continue
                }
                
                let searchableText = "\(title) \(content)".lowercased()
                let words = searchableText.components(separatedBy: .whitespacesAndNewlines)
                
                for word in words {
                    let cleanWord = word.trimmingCharacters(in: .punctuationCharacters)
                    if cleanWord.count >= 3 {
                        if searchIndex[cleanWord] == nil {
                            searchIndex[cleanWord] = []
                        }
                        if !searchIndex[cleanWord]!.contains(id) {
                            searchIndex[cleanWord]!.append(id)
                        }
                    }
                }
            }
        } catch {
            print("Error updating AI prompts search index: \(error)")
        }
    }
    
    // MARK: - Optimized Search
    
    func searchAllContent(query: String) -> SearchResult {
        let searchTerms = query.lowercased().components(separatedBy: .whitespacesAndNewlines)
        var matchingIds: Set<UUID> = []
        
        // Use search index for fast lookup
        for term in searchTerms {
            let cleanTerm = term.trimmingCharacters(in: .punctuationCharacters)
            if cleanTerm.count >= 3, let ids = searchIndex[cleanTerm] {
                matchingIds.formUnion(ids)
            }
        }
        
        // If no results from index, fall back to direct search
        if matchingIds.isEmpty {
            return fallbackSearch(query: query)
        }
        
        // Fetch matching items
        return fetchMatchingItems(ids: Array(matchingIds))
    }
    
    private func fallbackSearch(query: String) -> SearchResult {
        var results: SearchResult = SearchResult(clipboardItems: [], notes: [], aiPrompts: [])
        
        // Search clipboard items
        let clipboardResults = fetchClipboardItems(searchQuery: query)
        results.clipboardItems = clipboardResults.items
        
        // Search notes
        let notesResults = fetchNotes(searchQuery: query)
        results.notes = notesResults.items
        
        // Search AI prompts
        let promptsResults = fetchAIPrompts(searchQuery: query)
        results.aiPrompts = promptsResults.items
        
        return results
    }
    
    private func fetchMatchingItems(ids: [UUID]) -> SearchResult {
        var results = SearchResult(clipboardItems: [], notes: [], aiPrompts: [])
        
        // Fetch clipboard items
        let clipboardFetchRequest: NSFetchRequest<CDClipboardItem> = CDClipboardItem.fetchRequest()
        clipboardFetchRequest.predicate = NSPredicate(format: "id IN %@", ids as [CVarArg])
        
        if let cdItems = try? CoreDataManager.shared.context.fetch(clipboardFetchRequest) {
            results.clipboardItems = cdItems.compactMap { cdItem in
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
        }
        
        // Fetch notes
        let notesFetchRequest: NSFetchRequest<CDNote> = CDNote.fetchRequest()
        notesFetchRequest.predicate = NSPredicate(format: "id IN %@", ids as [CVarArg])
        
        if let cdNotes = try? CoreDataManager.shared.context.fetch(notesFetchRequest) {
            results.notes = cdNotes.compactMap { (cdNote: CDNote) -> Note? in
                guard let id = cdNote.id,
                      let title = cdNote.title,
                      let content = cdNote.content,
                      let colorString = cdNote.color,
                      let color = NoteColor(rawValue: colorString),
                      let createdAt = cdNote.createdAt,
                      let lastModified = cdNote.lastModified else {
                    return nil
                }
                
                return Note(
                    id: id,
                    title: title,
                    content: content,
                    color: color,
                    timestamp: createdAt,
                    lastModified: lastModified,
                    tags: cdNote.tags ?? [],
                    isEncrypted: cdNote.isEncrypted
                )
            }
        }
        
        // Fetch AI prompts
        let promptsFetchRequest: NSFetchRequest<CDAIPrompt> = CDAIPrompt.fetchRequest()
        promptsFetchRequest.predicate = NSPredicate(format: "id IN %@", ids as [CVarArg])
        
        if let cdPrompts = try? CoreDataManager.shared.context.fetch(promptsFetchRequest) {
            results.aiPrompts = cdPrompts.compactMap { (cdPrompt: CDAIPrompt) -> AIPrompt? in
                guard let id = cdPrompt.id,
                      let title = cdPrompt.title,
                      let content = cdPrompt.content,
                      let categoryString = cdPrompt.category,
                      let category = PromptCategory(rawValue: categoryString),
                      let createdAt = cdPrompt.createdAt else {
                    return nil
                }
                
                var prompt = AIPrompt(
                    title: title,
                    content: content,
                    category: category,
                    tags: cdPrompt.tags ?? [],
                    isFavorite: cdPrompt.isFavorite
                )
                prompt.id = id
                prompt.useCount = Int(cdPrompt.useCount)
                prompt.dateCreated = createdAt
                prompt.dateModified = createdAt
                return prompt
            }
        }
        
        return results
    }
    
    // MARK: - Data Archiving
    
    func archiveOldData() {
        let calendar = Calendar.current
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        
        // Archive old clipboard items
        archiveOldClipboardItems(before: thirtyDaysAgo)
        
        // Archive old notes (keep all for now, but could implement archiving)
        // archiveOldNotes(before: thirtyDaysAgo)
        
        // Archive old AI prompts (keep all for now, but could implement archiving)
        // archiveOldAIPrompts(before: thirtyDaysAgo)
    }
    
    private func archiveOldClipboardItems(before date: Date) {
        let fetchRequest: NSFetchRequest<CDClipboardItem> = CDClipboardItem.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "updatedAt < %@ AND isFavorite == NO", date as CVarArg)
        
        do {
            let oldItems = try CoreDataManager.shared.context.fetch(fetchRequest)
            
            // Archive to separate storage or delete
            for item in oldItems {
                CoreDataManager.shared.context.delete(item)
            }
            
            CoreDataManager.shared.save()
            print("Archived \(oldItems.count) old clipboard items")
        } catch {
            print("Error archiving old clipboard items: \(error)")
        }
    }
    
    // MARK: - Memory Management
    
    func optimizeMemoryUsage() {
        // Clear search index if it gets too large
        if searchIndex.count > 10000 {
            searchIndex.removeAll()
            lastSearchUpdate = Date.distantPast
        }
        
        // Force garbage collection
        autoreleasepool {
            // This will help with memory management
        }
    }
    
    // MARK: - Performance Monitoring
    
    func getPerformanceMetrics() -> PerformanceMetrics {
        let clipboardCount = getEntityCount("CDClipboardItem")
        let notesCount = getEntityCount("CDNote")
        let promptsCount = getEntityCount("CDAIPrompt")
        let tabsCount = getEntityCount("CDCustomTab")
        
        return PerformanceMetrics(
            clipboardItemsCount: clipboardCount,
            notesCount: notesCount,
            aiPromptsCount: promptsCount,
            customTabsCount: tabsCount,
            searchIndexSize: searchIndex.count,
            lastSearchIndexUpdate: lastSearchUpdate
        )
    }
    
    private func getEntityCount(_ entityName: String) -> Int {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest()
        fetchRequest.entity = NSEntityDescription.entity(forEntityName: entityName, in: CoreDataManager.shared.context)
        
        do {
            return try CoreDataManager.shared.context.count(for: fetchRequest)
        } catch {
            print("Error getting count for \(entityName): \(error)")
            return 0
        }
    }
}

// MARK: - Supporting Types

struct SearchResult {
    var clipboardItems: [ClipboardItem]
    var notes: [Note]
    var aiPrompts: [AIPrompt]
    
    var totalCount: Int {
        return clipboardItems.count + notes.count + aiPrompts.count
    }
}

struct PerformanceMetrics {
    let clipboardItemsCount: Int
    let notesCount: Int
    let aiPromptsCount: Int
    let customTabsCount: Int
    let searchIndexSize: Int
    let lastSearchIndexUpdate: Date
    
    var totalItems: Int {
        return clipboardItemsCount + notesCount + aiPromptsCount + customTabsCount
    }
    
    var isSearchIndexStale: Bool {
        return Date().timeIntervalSince(lastSearchIndexUpdate) > 600 // 10 minutes
    }
}
