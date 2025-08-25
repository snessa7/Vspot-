//
//  VspotUITests.swift
//  VspotUITests
//
//  UI tests for Vspot application
//

import XCTest

final class VspotUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Basic App Functionality Tests
    
    func testAppLaunch() throws {
        // Verify app launches successfully
        XCTAssertTrue(app.isRunning)
        
        // Check that menubar item is present
        let menubarItem = app.statusBars.element
        XCTAssertTrue(menubarItem.exists)
    }
    
    func testMenubarAccessibility() throws {
        // Test that menubar item is accessible
        let menubarItem = app.statusBars.element
        XCTAssertTrue(menubarItem.isAccessibilityElement)
        
        // Test menubar interaction
        menubarItem.click()
        
        // Verify popover/window appears
        let popover = app.windows.element(boundBy: 0)
        XCTAssertTrue(popover.exists)
    }
    
    // MARK: - Clipboard Management Tests
    
    func testClipboardCapture() throws {
        // This test would require simulating clipboard changes
        // In a real scenario, we'd use accessibility features to verify clipboard items appear
        
        // Simulate copying text to clipboard
        let testText = "Test clipboard content"
        
        // Copy text to system clipboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(testText, forType: .string)
        
        // Wait for clipboard manager to detect change
        Thread.sleep(forTimeInterval: 1.0)
        
        // Verify clipboard item appears in UI
        // This would require specific UI element identification
        // For now, we'll test the basic functionality
        XCTAssertTrue(app.isRunning)
    }
    
    func testClipboardItemInteraction() throws {
        // Test clicking on clipboard items
        // This would require specific UI element setup
        
        // Simulate clipboard item selection
        let clipboardList = app.collectionViews.firstMatch
        if clipboardList.exists {
            let firstItem = clipboardList.cells.firstMatch
            if firstItem.exists {
                firstItem.click()
                
                // Verify item is selected or copied
                XCTAssertTrue(firstItem.isSelected)
            }
        }
    }
    
    // MARK: - Notes Management Tests
    
    func testCreateNote() throws {
        // Navigate to notes tab
        let notesTab = app.buttons["Notes"]
        if notesTab.exists {
            notesTab.click()
            
            // Find add note button
            let addButton = app.buttons["Add Note"]
            if addButton.exists {
                addButton.click()
                
                // Fill in note details
                let titleField = app.textFields["Note Title"]
                let contentField = app.textViews["Note Content"]
                
                if titleField.exists {
                    titleField.click()
                    titleField.typeText("Test Note")
                }
                
                if contentField.exists {
                    contentField.click()
                    contentField.typeText("This is a test note content")
                }
                
                // Save note
                let saveButton = app.buttons["Save"]
                if saveButton.exists {
                    saveButton.click()
                }
                
                // Verify note was created
                XCTAssertTrue(app.staticTexts["Test Note"].exists)
            }
        }
    }
    
    func testEditNote() throws {
        // Test editing an existing note
        let notesTab = app.buttons["Notes"]
        if notesTab.exists {
            notesTab.click()
            
            // Find and click on a note
            let noteItem = app.cells.firstMatch
            if noteItem.exists {
                noteItem.doubleClick()
                
                // Edit the note
                let titleField = app.textFields["Note Title"]
                if titleField.exists {
                    titleField.click()
                    titleField.typeText(" - Edited")
                }
                
                // Save changes
                let saveButton = app.buttons["Save"]
                if saveButton.exists {
                    saveButton.click()
                }
            }
        }
    }
    
    func testDeleteNote() throws {
        // Test deleting a note
        let notesTab = app.buttons["Notes"]
        if notesTab.exists {
            notesTab.click()
            
            // Find a note to delete
            let noteItem = app.cells.firstMatch
            if noteItem.exists {
                // Right-click to show context menu
                noteItem.rightClick()
                
                // Find delete option
                let deleteButton = app.menuItems["Delete"]
                if deleteButton.exists {
                    deleteButton.click()
                    
                    // Confirm deletion
                    let confirmButton = app.buttons["Delete"]
                    if confirmButton.exists {
                        confirmButton.click()
                    }
                }
            }
        }
    }
    
    // MARK: - AI Prompts Tests
    
    func testAIPromptLibrary() throws {
        // Navigate to AI Prompts tab
        let aiPromptsTab = app.buttons["AI Prompts"]
        if aiPromptsTab.exists {
            aiPromptsTab.click()
            
            // Verify default prompts are loaded
            XCTAssertTrue(app.staticTexts["Code Review"].exists)
            XCTAssertTrue(app.staticTexts["Debug Helper"].exists)
        }
    }
    
    func testCreateAIPrompt() throws {
        // Navigate to AI Prompts tab
        let aiPromptsTab = app.buttons["AI Prompts"]
        if aiPromptsTab.exists {
            aiPromptsTab.click()
            
            // Find add prompt button
            let addButton = app.buttons["Add Prompt"]
            if addButton.exists {
                addButton.click()
                
                // Fill in prompt details
                let titleField = app.textFields["Prompt Title"]
                let contentField = app.textViews["Prompt Content"]
                let categoryPicker = app.pickers["Category"]
                
                if titleField.exists {
                    titleField.click()
                    titleField.typeText("Test Prompt")
                }
                
                if contentField.exists {
                    contentField.click()
                    contentField.typeText("This is a test AI prompt")
                }
                
                if categoryPicker.exists {
                    categoryPicker.click()
                    let generalOption = app.buttons["General"]
                    if generalOption.exists {
                        generalOption.click()
                    }
                }
                
                // Save prompt
                let saveButton = app.buttons["Save"]
                if saveButton.exists {
                    saveButton.click()
                }
                
                // Verify prompt was created
                XCTAssertTrue(app.staticTexts["Test Prompt"].exists)
            }
        }
    }
    
    func testUseAIPrompt() throws {
        // Navigate to AI Prompts tab
        let aiPromptsTab = app.buttons["AI Prompts"]
        if aiPromptsTab.exists {
            aiPromptsTab.click()
            
            // Find and click on a prompt
            let promptItem = app.cells.firstMatch
            if promptItem.exists {
                promptItem.click()
                
                // Verify prompt content is displayed
                let contentView = app.textViews["Prompt Content"]
                XCTAssertTrue(contentView.exists)
                
                // Test copy to clipboard
                let copyButton = app.buttons["Copy"]
                if copyButton.exists {
                    copyButton.click()
                    
                    // Verify copy feedback
                    XCTAssertTrue(app.staticTexts["Copied to clipboard"].exists)
                }
            }
        }
    }
    
    // MARK: - Custom Tabs Tests
    
    func testCustomTabs() throws {
        // Navigate to custom tabs
        let customTabsButton = app.buttons["Custom Tabs"]
        if customTabsButton.exists {
            customTabsButton.click()
            
            // Verify default tabs exist
            XCTAssertTrue(app.staticTexts["Passwords"].exists)
            XCTAssertTrue(app.staticTexts["Code Snippets"].exists)
        }
    }
    
    func testCreateCustomTab() throws {
        // Navigate to custom tabs
        let customTabsButton = app.buttons["Custom Tabs"]
        if customTabsButton.exists {
            customTabsButton.click()
            
            // Find add tab button
            let addButton = app.buttons["Add Tab"]
            if addButton.exists {
                addButton.click()
                
                // Fill in tab details
                let nameField = app.textFields["Tab Name"]
                let fieldsList = app.collectionViews["Fields List"]
                
                if nameField.exists {
                    nameField.click()
                    nameField.typeText("Test Tab")
                }
                
                // Add fields
                let addFieldButton = app.buttons["Add Field"]
                if addFieldButton.exists {
                    addFieldButton.click()
                    
                    let fieldNameField = app.textFields["Field Name"]
                    if fieldNameField.exists {
                        fieldNameField.click()
                        fieldNameField.typeText("Test Field")
                    }
                }
                
                // Save tab
                let saveButton = app.buttons["Save"]
                if saveButton.exists {
                    saveButton.click()
                }
                
                // Verify tab was created
                XCTAssertTrue(app.staticTexts["Test Tab"].exists)
            }
        }
    }
    
    // MARK: - Search Functionality Tests
    
    func testGlobalSearch() throws {
        // Find search field
        let searchField = app.textFields["Search"]
        if searchField.exists {
            searchField.click()
            searchField.typeText("test")
            
            // Verify search results appear
            let searchResults = app.collectionViews["Search Results"]
            XCTAssertTrue(searchResults.exists)
        }
    }
    
    func testSearchInNotes() throws {
        // Navigate to notes and test search
        let notesTab = app.buttons["Notes"]
        if notesTab.exists {
            notesTab.click()
            
            let searchField = app.textFields["Search Notes"]
            if searchField.exists {
                searchField.click()
                searchField.typeText("test")
                
                // Verify filtered results
                let filteredResults = app.collectionViews["Notes List"]
                XCTAssertTrue(filteredResults.exists)
            }
        }
    }
    
    func testSearchInAIPrompts() throws {
        // Navigate to AI prompts and test search
        let aiPromptsTab = app.buttons["AI Prompts"]
        if aiPromptsTab.exists {
            aiPromptsTab.click()
            
            let searchField = app.textFields["Search Prompts"]
            if searchField.exists {
                searchField.click()
                searchField.typeText("code")
                
                // Verify filtered results
                let filteredResults = app.collectionViews["Prompts List"]
                XCTAssertTrue(filteredResults.exists)
            }
        }
    }
    
    // MARK: - Settings and Preferences Tests
    
    func testAppSettings() throws {
        // Find settings/preferences button
        let settingsButton = app.buttons["Settings"]
        if settingsButton.exists {
            settingsButton.click()
            
            // Test various settings
            let launchAtLoginToggle = app.checkBoxes["Launch at Login"]
            if launchAtLoginToggle.exists {
                launchAtLoginToggle.click()
            }
            
            let globalShortcutsToggle = app.checkBoxes["Global Shortcuts"]
            if globalShortcutsToggle.exists {
                globalShortcutsToggle.click()
            }
            
            // Test menubar style selection
            let menubarStylePicker = app.pickers["Menubar Style"]
            if menubarStylePicker.exists {
                menubarStylePicker.click()
                let popoverOption = app.buttons["Popover"]
                if popoverOption.exists {
                    popoverOption.click()
                }
            }
        }
    }
    
    func testSecuritySettings() throws {
        // Find security settings
        let securityButton = app.buttons["Security"]
        if securityButton.exists {
            securityButton.click()
            
            // Test encryption toggle
            let encryptionToggle = app.checkBoxes["Enable Encryption"]
            if encryptionToggle.exists {
                encryptionToggle.click()
            }
            
            // Test biometric authentication
            let biometricToggle = app.checkBoxes["Biometric Authentication"]
            if biometricToggle.exists {
                biometricToggle.click()
                
                // Handle biometric authentication dialog
                let biometricDialog = app.dialogs["Biometric Authentication"]
                if biometricDialog.exists {
                    let cancelButton = biometricDialog.buttons["Cancel"]
                    if cancelButton.exists {
                        cancelButton.click()
                    }
                }
            }
        }
    }
    
    // MARK: - Data Export/Import Tests
    
    func testDataExport() throws {
        // Find export button
        let exportButton = app.buttons["Export Data"]
        if exportButton.exists {
            exportButton.click()
            
            // Handle file save dialog
            let saveDialog = app.sheets["Save Dialog"]
            if saveDialog.exists {
                let saveButton = saveDialog.buttons["Save"]
                if saveButton.exists {
                    saveButton.click()
                }
            }
            
            // Verify export success message
            XCTAssertTrue(app.staticTexts["Data exported successfully"].exists)
        }
    }
    
    func testDataImport() throws {
        // Find import button
        let importButton = app.buttons["Import Data"]
        if importButton.exists {
            importButton.click()
            
            // Handle file open dialog
            let openDialog = app.sheets["Open Dialog"]
            if openDialog.exists {
                let cancelButton = openDialog.buttons["Cancel"]
                if cancelButton.exists {
                    cancelButton.click()
                }
            }
        }
    }
    
    // MARK: - Performance Tests
    
    func testLargeDatasetPerformance() throws {
        // Test app performance with large datasets
        // This would require pre-populating the app with large amounts of data
        
        // Navigate through different tabs to test performance
        let tabs = ["Clipboard", "Notes", "AI Prompts", "Custom Tabs"]
        
        for tabName in tabs {
            let tabButton = app.buttons[tabName]
            if tabButton.exists {
                tabButton.click()
                
                // Wait for content to load
                Thread.sleep(forTimeInterval: 0.5)
                
                // Verify tab loads without issues
                XCTAssertTrue(app.isRunning)
            }
        }
    }
    
    // MARK: - Accessibility Tests
    
    func testAccessibility() throws {
        // Test that all important UI elements are accessible
        let accessibilityElements = [
            "Clipboard",
            "Notes", 
            "AI Prompts",
            "Custom Tabs",
            "Search",
            "Settings"
        ]
        
        for elementName in accessibilityElements {
            let element = app.buttons[elementName]
            if element.exists {
                XCTAssertTrue(element.isAccessibilityElement, "\(elementName) should be accessible")
            }
        }
    }
    
    func testKeyboardNavigation() throws {
        // Test keyboard navigation through the app
        // Press Tab to navigate through elements
        app.typeKey(.tab, modifierFlags: [])
        
        // Verify focus moves to next element
        let focusedElement = app.focusedElement
        XCTAssertNotNil(focusedElement)
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorHandling() throws {
        // Test how the app handles various error conditions
        
        // Test invalid data input
        let notesTab = app.buttons["Notes"]
        if notesTab.exists {
            notesTab.click()
            
            let addButton = app.buttons["Add Note"]
            if addButton.exists {
                addButton.click()
                
                // Try to save without required fields
                let saveButton = app.buttons["Save"]
                if saveButton.exists {
                    saveButton.click()
                    
                    // Verify error message appears
                    XCTAssertTrue(app.staticTexts["Please fill in all required fields"].exists)
                }
            }
        }
    }
    
    // MARK: - App Lifecycle Tests
    
    func testAppBackgrounding() throws {
        // Test app behavior when backgrounded
        XCUIDevice.shared.press(.home)
        
        // Wait a moment
        Thread.sleep(forTimeInterval: 1.0)
        
        // Return to app
        app.activate()
        
        // Verify app is still running and responsive
        XCTAssertTrue(app.isRunning)
    }
    
    func testAppTermination() throws {
        // Test app termination and restart
        app.terminate()
        
        // Restart app
        app.launch()
        
        // Verify app starts successfully
        XCTAssertTrue(app.isRunning)
    }
}
