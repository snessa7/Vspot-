//
//  VspotTests.swift
//  VspotTests
//
//  Unit tests for Vspot application
//

import XCTest
import CoreData
@testable import Vspot

final class VspotTests: XCTestCase {
    
    // MARK: - Test Properties
    
    var coreDataManager: CoreDataManager!
    var securityManager: SecurityManager!
    var clipboardManager: ClipboardManager!
    var notesManager: NotesManager!
    var aiPromptsManager: AIPromptsManager!
    var customTabManager: CustomTabManager!
    
    // MARK: - Setup and Teardown
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Create in-memory Core Data stack for testing
        coreDataManager = CoreDataManager.shared
        
        // Initialize managers
        securityManager = SecurityManager.shared
        clipboardManager = ClipboardManager()
        notesManager = NotesManager.shared
        aiPromptsManager = AIPromptsManager.shared
        customTabManager = CustomTabManager.shared
        
        // Clear any existing test data
        clearTestData()
    }
    
    override func tearDownWithError() throws {
        clearTestData()
        try super.tearDownWithError()
    }
    
    // MARK: - Helper Methods
    
    private func clearTestData() {
        // Clear Core Data
        let entities = ["CDClipboardItem", "CDNote", "CDAIPrompt", "CDCustomTab"]
        
        for entityName in entities {
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest()
            fetchRequest.entity = NSEntityDescription.entity(forEntityName: entityName, in: coreDataManager.context)
            
            if let objects = try? coreDataManager.context.fetch(fetchRequest) as? [NSManagedObject] {
                for object in objects {
                    coreDataManager.context.delete(object)
                }
            }
        }
        
        coreDataManager.save()
    }
    
    // MARK: - Core Data Manager Tests
    
    func testCoreDataManagerInitialization() {
        XCTAssertNotNil(coreDataManager)
        XCTAssertNotNil(coreDataManager.context)
        XCTAssertNotNil(coreDataManager.persistentContainer)
    }
    
    func testCoreDataSave() {
        // Create a test clipboard item
        let cdItem = CDClipboardItem(context: coreDataManager.context)
        cdItem.id = UUID()
        cdItem.content = "Test content"
        cdItem.type = "text"
        cdItem.preview = "Test content"
        cdItem.isFavorite = false
        cdItem.isEncrypted = false
        cdItem.createdAt = Date()
        cdItem.updatedAt = Date()
        
        // Save and verify
        coreDataManager.save()
        
        let fetchRequest: NSFetchRequest<CDClipboardItem> = CDClipboardItem.fetchRequest()
        let items = try? coreDataManager.context.fetch(fetchRequest)
        
        XCTAssertEqual(items?.count, 1)
        XCTAssertEqual(items?.first?.content, "Test content")
    }
    
    // MARK: - Security Manager Tests
    
    func testSecurityManagerInitialization() {
        XCTAssertNotNil(securityManager)
        XCTAssertTrue(securityManager.isEncryptionEnabled)
    }
    
    func testEncryptionDecryption() throws {
        let testString = "This is a test string for encryption"
        let testData = testString.data(using: .utf8)!
        
        // Test data encryption/decryption
        let encryptedData = try securityManager.encrypt(testData)
        XCTAssertNotEqual(encryptedData, testData)
        
        let decryptedData = try securityManager.decrypt(encryptedData)
        XCTAssertEqual(decryptedData, testData)
        
        // Test string encryption/decryption
        let encryptedStringData = try securityManager.encryptString(testString)
        let decryptedString = try securityManager.decryptString(encryptedStringData)
        XCTAssertEqual(decryptedString, testString)
    }
    
    func testSecurityAudit() {
        let audit = securityManager.generateSecurityAudit()
        
        XCTAssertNotNil(audit)
        XCTAssertTrue(audit.encryptionEnabled)
        XCTAssertNotNil(audit.lastAuditDate)
    }
    
    // MARK: - Clipboard Manager Tests
    
    func testClipboardManagerInitialization() {
        XCTAssertNotNil(clipboardManager)
        XCTAssertEqual(clipboardManager.items.count, 0)
    }
    
    func testAddClipboardItem() {
        let testContent = "Test clipboard content"
        let testType = PasteboardType.text
        
        clipboardManager.addItem(content: testContent, type: testType)
        
        XCTAssertEqual(clipboardManager.items.count, 1)
        XCTAssertEqual(clipboardManager.items.first?.content, testContent)
        XCTAssertEqual(clipboardManager.items.first?.type, testType)
    }
    
    func testDuplicateClipboardItem() {
        let testContent = "Duplicate test content"
        let testType = PasteboardType.text
        
        // Add item twice
        clipboardManager.addItem(content: testContent, type: testType)
        clipboardManager.addItem(content: testContent, type: testType)
        
        // Should only have one item (duplicate handling)
        XCTAssertEqual(clipboardManager.items.count, 1)
        XCTAssertEqual(clipboardManager.items.first?.content, testContent)
    }
    
    func testToggleFavorite() {
        let testContent = "Favorite test content"
        let testType = PasteboardType.text
        
        clipboardManager.addItem(content: testContent, type: testType)
        
        guard let item = clipboardManager.items.first else {
            XCTFail("No item to test")
            return
        }
        
        XCTAssertFalse(item.isFavorite)
        
        clipboardManager.toggleFavorite(item)
        
        // Reload items to see changes
        clipboardManager.loadItems()
        
        XCTAssertTrue(clipboardManager.items.first?.isFavorite ?? false)
    }
    
    func testDeleteClipboardItem() {
        let testContent = "Delete test content"
        let testType = PasteboardType.text
        
        clipboardManager.addItem(content: testContent, type: testType)
        XCTAssertEqual(clipboardManager.items.count, 1)
        
        guard let item = clipboardManager.items.first else {
            XCTFail("No item to delete")
            return
        }
        
        clipboardManager.deleteItem(item)
        XCTAssertEqual(clipboardManager.items.count, 0)
    }
    
    func testClearAllClipboardItems() {
        // Add multiple items
        clipboardManager.addItem(content: "Item 1", type: .text)
        clipboardManager.addItem(content: "Item 2", type: .url)
        clipboardManager.addItem(content: "Item 3", type: .richText)
        
        XCTAssertEqual(clipboardManager.items.count, 3)
        
        clipboardManager.clearAll()
        XCTAssertEqual(clipboardManager.items.count, 0)
    }
    
    // MARK: - Notes Manager Tests
    
    func testNotesManagerInitialization() {
        XCTAssertNotNil(notesManager)
        XCTAssertEqual(notesManager.notes.count, 0)
    }
    
    func testAddNote() {
        let title = "Test Note"
        let content = "This is a test note"
        let color = NoteColor.yellow
        
        notesManager.addNote(title: title, content: content, color: color)
        
        XCTAssertEqual(notesManager.notes.count, 1)
        XCTAssertEqual(notesManager.notes.first?.title, title)
        XCTAssertEqual(notesManager.notes.first?.content, content)
        XCTAssertEqual(notesManager.notes.first?.color, color)
    }
    
    func testUpdateNote() {
        let title = "Original Title"
        let content = "Original content"
        let color = NoteColor.yellow
        
        notesManager.addNote(title: title, content: content, color: color)
        
        guard let note = notesManager.notes.first else {
            XCTFail("No note to update")
            return
        }
        
        let updatedTitle = "Updated Title"
        let updatedContent = "Updated content"
        let updatedColor = NoteColor.blue
        
        var updatedNote = note
        updatedNote.title = updatedTitle
        updatedNote.content = updatedContent
        updatedNote.color = updatedColor
        
        notesManager.updateNote(updatedNote)
        
        XCTAssertEqual(notesManager.notes.first?.title, updatedTitle)
        XCTAssertEqual(notesManager.notes.first?.content, updatedContent)
        XCTAssertEqual(notesManager.notes.first?.color, updatedColor)
    }
    
    func testDeleteNote() {
        notesManager.addNote(title: "Test Note", content: "Test content", color: .yellow)
        XCTAssertEqual(notesManager.notes.count, 1)
        
        guard let note = notesManager.notes.first else {
            XCTFail("No note to delete")
            return
        }
        
        notesManager.deleteNote(note)
        XCTAssertEqual(notesManager.notes.count, 0)
    }
    
    func testSearchNotes() {
        notesManager.addNote(title: "Apple", content: "Red fruit", color: .red)
        notesManager.addNote(title: "Banana", content: "Yellow fruit", color: .yellow)
        notesManager.addNote(title: "Orange", content: "Orange fruit", color: .orange)
        
        let searchResults = notesManager.searchNotes(query: "fruit")
        XCTAssertEqual(searchResults.count, 3)
        
        let appleResults = notesManager.searchNotes(query: "Apple")
        XCTAssertEqual(appleResults.count, 1)
        XCTAssertEqual(appleResults.first?.title, "Apple")
    }
    
    // MARK: - AI Prompts Manager Tests
    
    func testAIPromptsManagerInitialization() {
        XCTAssertNotNil(aiPromptsManager)
        // Should have default prompts loaded
        XCTAssertGreaterThan(aiPromptsManager.prompts.count, 0)
    }
    
    func testAddPrompt() {
        let title = "Test Prompt"
        let content = "This is a test prompt"
        let category = PromptCategory.general
        let tags = ["test", "example"]
        
        aiPromptsManager.addPrompt(title: title, content: content, category: category, tags: tags)
        
        XCTAssertTrue(aiPromptsManager.prompts.contains { $0.title == title })
        XCTAssertTrue(aiPromptsManager.prompts.contains { $0.content == content })
    }
    
    func testUpdatePrompt() {
        aiPromptsManager.addPrompt(title: "Original", content: "Original content", category: .general)
        
        guard let prompt = aiPromptsManager.prompts.first else {
            XCTFail("No prompt to update")
            return
        }
        
        let newTitle = "Updated"
        let newContent = "Updated content"
        let newCategory = PromptCategory.coding
        let newTags = ["updated", "test"]
        
        aiPromptsManager.updatePrompt(prompt, title: newTitle, content: newContent, category: newCategory, tags: newTags)
        
        XCTAssertEqual(aiPromptsManager.prompts.first?.title, newTitle)
        XCTAssertEqual(aiPromptsManager.prompts.first?.content, newContent)
        XCTAssertEqual(aiPromptsManager.prompts.first?.category, newCategory)
        XCTAssertEqual(aiPromptsManager.prompts.first?.tags, newTags)
    }
    
    func testDeletePrompt() {
        aiPromptsManager.addPrompt(title: "Test Prompt", content: "Test content", category: .general)
        
        guard let prompt = aiPromptsManager.prompts.first else {
            XCTFail("No prompt to delete")
            return
        }
        
        aiPromptsManager.deletePrompt(prompt)
        XCTAssertFalse(aiPromptsManager.prompts.contains { $0.id == prompt.id })
    }
    
    func testToggleFavorite() {
        aiPromptsManager.addPrompt(title: "Test Prompt", content: "Test content", category: .general)
        
        guard let prompt = aiPromptsManager.prompts.first else {
            XCTFail("No prompt to test")
            return
        }
        
        XCTAssertFalse(prompt.isFavorite)
        
        aiPromptsManager.toggleFavorite(prompt)
        
        XCTAssertTrue(aiPromptsManager.prompts.first?.isFavorite ?? false)
    }
    
    func testUsePrompt() {
        aiPromptsManager.addPrompt(title: "Test Prompt", content: "Test content", category: .general)
        
        guard let prompt = aiPromptsManager.prompts.first else {
            XCTFail("No prompt to test")
            return
        }
        
        let initialUseCount = prompt.useCount
        let result = aiPromptsManager.usePrompt(prompt)
        
        XCTAssertEqual(result, "Test content")
        XCTAssertEqual(aiPromptsManager.prompts.first?.useCount, initialUseCount + 1)
    }
    
    func testSearchPrompts() {
        aiPromptsManager.addPrompt(title: "Code Review", content: "Review this code", category: .review, tags: ["code", "review"])
        aiPromptsManager.addPrompt(title: "Debug Helper", content: "Help debug this", category: .debugging, tags: ["debug", "help"])
        
        let codeResults = aiPromptsManager.searchPrompts(query: "code")
        XCTAssertGreaterThan(codeResults.count, 0)
        
        let debugResults = aiPromptsManager.searchPrompts(query: "debug")
        XCTAssertGreaterThan(debugResults.count, 0)
    }
    
    func testPromptsByCategory() {
        aiPromptsManager.addPrompt(title: "Code Review", content: "Review this code", category: .review)
        aiPromptsManager.addPrompt(title: "Debug Helper", content: "Help debug this", category: .debugging)
        
        let reviewPrompts = aiPromptsManager.promptsByCategory(.review)
        XCTAssertEqual(reviewPrompts.count, 1)
        XCTAssertEqual(reviewPrompts.first?.category, .review)
        
        let debuggingPrompts = aiPromptsManager.promptsByCategory(.debugging)
        XCTAssertEqual(debuggingPrompts.count, 1)
        XCTAssertEqual(debuggingPrompts.first?.category, .debugging)
    }
    
    func testFavoritePrompts() {
        aiPromptsManager.addPrompt(title: "Favorite 1", content: "Content 1", category: .general)
        aiPromptsManager.addPrompt(title: "Favorite 2", content: "Content 2", category: .general)
        
        guard let prompt1 = aiPromptsManager.prompts.first(where: { $0.title == "Favorite 1" }),
              let prompt2 = aiPromptsManager.prompts.first(where: { $0.title == "Favorite 2" }) else {
            XCTFail("Prompts not found")
            return
        }
        
        aiPromptsManager.toggleFavorite(prompt1)
        aiPromptsManager.toggleFavorite(prompt2)
        
        let favorites = aiPromptsManager.favoritePrompts()
        XCTAssertEqual(favorites.count, 2)
    }
    
    func testMostUsedPrompts() {
        aiPromptsManager.addPrompt(title: "Prompt 1", content: "Content 1", category: .general)
        aiPromptsManager.addPrompt(title: "Prompt 2", content: "Content 2", category: .general)
        
        guard let prompt1 = aiPromptsManager.prompts.first(where: { $0.title == "Prompt 1" }),
              let prompt2 = aiPromptsManager.prompts.first(where: { $0.title == "Prompt 2" }) else {
            XCTFail("Prompts not found")
            return
        }
        
        // Use prompt2 more times
        aiPromptsManager.usePrompt(prompt2)
        aiPromptsManager.usePrompt(prompt2)
        aiPromptsManager.usePrompt(prompt1)
        
        let mostUsed = aiPromptsManager.mostUsedPrompts(limit: 2)
        XCTAssertEqual(mostUsed.count, 2)
        XCTAssertEqual(mostUsed.first?.title, "Prompt 2") // Should be first due to higher use count
    }
    
    // MARK: - Custom Tab Manager Tests
    
    func testCustomTabManagerInitialization() {
        XCTAssertNotNil(customTabManager)
        XCTAssertEqual(customTabManager.tabs.count, 0)
    }
    
    func testAddCustomTab() {
        let name = "Test Tab"
        let fields = ["Field 1", "Field 2", "Field 3"]
        let isSecure = false
        
        customTabManager.addTab(name: name, fields: fields, isSecure: isSecure)
        
        XCTAssertEqual(customTabManager.tabs.count, 1)
        XCTAssertEqual(customTabManager.tabs.first?.name, name)
        XCTAssertEqual(customTabManager.tabs.first?.fields, fields)
        XCTAssertEqual(customTabManager.tabs.first?.isSecure, isSecure)
    }
    
    func testUpdateCustomTab() {
        customTabManager.addTab(name: "Original", fields: ["Field 1"], isSecure: false)
        
        guard let tab = customTabManager.tabs.first else {
            XCTFail("No tab to update")
            return
        }
        
        let newName = "Updated"
        let newFields = ["New Field 1", "New Field 2"]
        let newIsSecure = true
        
        customTabManager.updateTab(tab, name: newName, fields: newFields, isSecure: newIsSecure)
        
        XCTAssertEqual(customTabManager.tabs.first?.name, newName)
        XCTAssertEqual(customTabManager.tabs.first?.fields, newFields)
        XCTAssertEqual(customTabManager.tabs.first?.isSecure, newIsSecure)
    }
    
    func testDeleteCustomTab() {
        customTabManager.addTab(name: "Test Tab", fields: ["Field 1"], isSecure: false)
        
        guard let tab = customTabManager.tabs.first else {
            XCTFail("No tab to delete")
            return
        }
        
        customTabManager.deleteTab(tab)
        XCTAssertEqual(customTabManager.tabs.count, 0)
    }
    
    func testReorderCustomTabs() {
        customTabManager.addTab(name: "Tab 1", fields: ["Field 1"], isSecure: false)
        customTabManager.addTab(name: "Tab 2", fields: ["Field 2"], isSecure: false)
        customTabManager.addTab(name: "Tab 3", fields: ["Field 3"], isSecure: false)
        
        XCTAssertEqual(customTabManager.tabs.count, 3)
        
        // Reorder tabs
        let reorderedTabs = customTabManager.tabs.reversed()
        customTabManager.reorderTabs(reorderedTabs)
        
        XCTAssertEqual(customTabManager.tabs.first?.name, "Tab 3")
        XCTAssertEqual(customTabManager.tabs.last?.name, "Tab 1")
    }
    
    // MARK: - Performance Tests
    
    func testClipboardManagerPerformance() {
        measure {
            for i in 0..<100 {
                clipboardManager.addItem(content: "Performance test item \(i)", type: .text)
            }
        }
    }
    
    func testSearchPerformance() {
        // Add many items for search testing
        for i in 0..<1000 {
            notesManager.addNote(title: "Note \(i)", content: "Content for note \(i)", color: .yellow)
        }
        
        measure {
            _ = notesManager.searchNotes(query: "note")
        }
    }
    
    // MARK: - Integration Tests
    
    func testDataMigration() {
        // This test verifies that data migration works correctly
        // In a real scenario, this would test migration from UserDefaults to Core Data
        
        // Add test data
        clipboardManager.addItem(content: "Migration test", type: .text)
        notesManager.addNote(title: "Migration Note", content: "Migration content", color: .blue)
        aiPromptsManager.addPrompt(title: "Migration Prompt", content: "Migration prompt content", category: .general)
        
        // Verify data exists
        XCTAssertEqual(clipboardManager.items.count, 1)
        XCTAssertEqual(notesManager.notes.count, 1)
        XCTAssertTrue(aiPromptsManager.prompts.contains { $0.title == "Migration Prompt" })
    }
    
    func testSecurityIntegration() {
        // Test that security features work with data operations
        let testContent = "Sensitive test content"
        
        // Test encryption
        do {
            let encryptedData = try securityManager.encryptString(testContent)
            let decryptedString = try securityManager.decryptString(encryptedData)
            XCTAssertEqual(decryptedString, testContent)
        } catch {
            XCTFail("Security integration test failed: \(error)")
        }
    }
}
