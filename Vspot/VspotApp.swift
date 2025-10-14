//
//  VspotApp.swift
//  Vspot
//
//  Clipboard manager for macOS with menubar access
//

import SwiftUI

@main
struct VspotApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()
    @StateObject private var clipboardManager = ClipboardManager()
    
    var body: some Scene {
        // Main window
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(clipboardManager)
                .frame(minWidth: 500, idealWidth: 700, maxWidth: .infinity,
                       minHeight: 450, idealHeight: 600, maxHeight: .infinity)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            // Application menu
            CommandGroup(replacing: .appInfo) {}
            
            // File menu
            CommandGroup(replacing: .newItem) {}
            
            // Edit menu
            CommandMenu("Edit") {
                Button("Clear All Clipboard Items") {
                    clipboardManager.clearAll()
                }
                .keyboardShortcut("k", modifiers: [.command, .shift])
                
                Button("Clear All Notes") {
                    NotesManager.shared.notes.removeAll()
                    NotesManager.shared.saveNotes()
                }
            }
            
            // View menu
            CommandMenu("View") {
                Button("Show in Menu Bar") {
                    appDelegate.showInMenuBar()
                }
                
                Button("Hide from Menu Bar") {
                    appDelegate.hideFromMenuBar()
                }
            }
        }
        
        // Preferences window
        Settings {
            PreferencesView()
                .environmentObject(appState)
        }
    }
}

// Main content view (same as MenuBarContentView but adapted for window)
struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var clipboardManager: ClipboardManager
    @State private var searchText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with tabs
            HeaderView()
                .padding(.horizontal)
                .padding(.vertical, 12)
            
            Divider()
            
            // Search bar
            SearchBar(text: $searchText)
                .padding(.horizontal)
                .padding(.vertical, 8)
            
            Divider()
            
            // Content based on selected tab
            Group {
                switch appState.currentTab {
                case .clipboard:
                    ClipboardListView(searchText: searchText)
                case .notes:
                    NotesView(searchText: searchText)
                case .aiPrompts:
                    AIPromptsView(searchText: searchText)
                case .custom(let name):
                    CustomTabView(tabName: name, searchText: searchText)
                }
            }
            
            Divider()
            
            // Footer with actions
            FooterView()
                .padding(.horizontal)
                .padding(.vertical, 8)
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// Preferences View
struct PreferencesView: View {
    @AppStorage("showInMenuBar") private var showInMenuBar = true
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("maxClipboardItems") private var maxClipboardItems = 100
    @AppStorage("autoCleanupDays") private var autoCleanupDays = 7
    
    var body: some View {
        TabView {
            // General preferences
            Form {
                Section("Startup") {
                    Toggle("Show in Menu Bar", isOn: $showInMenuBar)
                        .onChange(of: showInMenuBar) { _, newValue in
                            if newValue {
                                AppDelegate.shared?.showInMenuBar()
                            } else {
                                AppDelegate.shared?.hideFromMenuBar()
                            }
                        }
                    Toggle("Launch at Login", isOn: $launchAtLogin)
                }
                
                Section("Storage") {
                    Stepper("Max Clipboard Items: \(maxClipboardItems)", value: $maxClipboardItems, in: 10...500, step: 10)
                    Stepper("Auto-cleanup after: \(autoCleanupDays) days", value: $autoCleanupDays, in: 1...30)
                }
            }
            .tabItem {
                Label("General", systemImage: "gear")
            }
            .frame(width: 450, height: 300)
            
            // Shortcuts preferences
            VStack {
                Text("Keyboard Shortcuts")
                    .font(.headline)
                    .padding()
                
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Clear Clipboard:")
                        Spacer()
                        Text("⌘⇧K")
                    }
                    HStack {
                        Text("Toggle Window:")
                        Spacer()
                        Text("⌘⇧V")
                    }
                }
                .padding()
                .frame(maxWidth: 350)
                
                Spacer()
            }
            .tabItem {
                Label("Shortcuts", systemImage: "keyboard")
            }
            .frame(width: 450, height: 300)
        }
    }
}

// App delegate for handling app lifecycle and menubar
class AppDelegate: NSObject, NSApplicationDelegate {
    static var shared: AppDelegate?
    var statusItem: NSStatusItem?
    var popover = NSPopover()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
        
        // Set up menubar item if enabled
        if UserDefaults.standard.bool(forKey: "showInMenuBar") != false {
            showInMenuBar()
        }
    }
    
    func showInMenuBar() {
        if statusItem == nil {
            statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            
            if let button = statusItem?.button {
                // Use the white circle with "v" icon for better menubar visibility
                button.image = NSImage(systemSymbolName: "v.circle.fill", accessibilityDescription: "Vspot")
                button.image?.isTemplate = true // Ensures proper dark/light mode adaptation
                
                button.action = #selector(togglePopover)
                button.target = self
                button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            }
            
            popover.contentSize = NSSize(width: 400, height: 600)
            popover.behavior = .transient // Auto-dismiss when clicking outside
            popover.animates = true
            
            // Create shared instances for the menu bar
            let menuBarAppState = AppState()
            let menuBarClipboardManager = ClipboardManager()
            
            popover.contentViewController = NSHostingController(
                rootView: MenuBarContentView()
                    .environmentObject(menuBarAppState)
                    .environmentObject(menuBarClipboardManager)
            )
        }
    }
    
    func hideFromMenuBar() {
        if let statusItem = statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
            self.statusItem = nil
        }
    }
    
    @objc func togglePopover() {
        if let button = statusItem?.button {
            // Check the current event to determine which mouse button was clicked
            if let currentEvent = NSApp.currentEvent {
                if currentEvent.type == .rightMouseUp {
                    // Right-click: show context menu
                    showContextMenu(button)
                    return
                }
            }
            
            // Left-click: toggle popover
            if popover.isShown {
                closePopover()
            } else {
                showPopover(relativeTo: button)
            }
        }
    }
    
    func showPopover(relativeTo button: NSStatusBarButton) {
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        
        // Ensure the popover becomes key window for proper event handling
        DispatchQueue.main.async {
            self.popover.contentViewController?.view.window?.makeKey()
        }
    }
    
    func closePopover() {
        popover.performClose(nil)
    }
    
    func showContextMenu(_ sender: NSStatusBarButton) {
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
        
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
    }
    
    
    @objc func quit() {
        NSApplication.shared.terminate(nil)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Cleanup when app quits
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            NSApp.windows.first?.makeKeyAndOrderFront(nil)
        }
        return true
    }
}

