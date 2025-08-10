//
//  ClipboardAppApp.swift
//  ClipboardApp
//
//  Clipboard manager for macOS with menubar access
//

import SwiftUI

@main
struct ClipboardAppApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()
    @StateObject private var clipboardManager = ClipboardManager()
    
    var body: some Scene {
        // Main window
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(clipboardManager)
                .frame(minWidth: 500, idealWidth: 700, maxWidth: 900,
                       minHeight: 450, idealHeight: 600, maxHeight: 800)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            // Application menu
            CommandGroup(replacing: .appInfo) {
                Button("About VSpot") {
                    appDelegate.showAbout()
                }
            }
            
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
                    CustomTabView(tabName: name)
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
                        .onChange(of: showInMenuBar) { newValue in
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
                button.image = NSImage(systemSymbolName: "v.circle.fill", accessibilityDescription: "VSpot ClipboardApp")
                button.image?.isTemplate = true // Ensures proper dark/light mode adaptation
                
                button.action = #selector(togglePopover)
                button.target = self
                button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            }
            
            popover.contentSize = NSSize(width: 400, height: 500)
            popover.behavior = .transient
            popover.contentViewController = NSHostingController(
                rootView: MenuBarContentView()
                    .environmentObject(AppState())
                    .environmentObject(ClipboardManager())
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
            if NSEvent.modifierFlags.contains(.control) || NSEvent.modifierFlags.contains(.option) {
                // Right-click or option-click: show menu
                showContextMenu(button)
            } else {
                // Left-click: toggle popover
                if popover.isShown {
                    popover.performClose(nil)
                } else {
                    popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                }
            }
        }
    }
    
    func showContextMenu(_ sender: NSStatusBarButton) {
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "Open VSpot", action: #selector(openMainWindow), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Preferences...", action: #selector(openPreferences), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "About VSpot", action: #selector(showAbout), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
        
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
    }
    
    @objc func openMainWindow() {
        NSApplication.shared.activate(ignoringOtherApps: true)
        NSApp.windows.first?.makeKeyAndOrderFront(nil)
    }
    
    @objc func openPreferences() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }
    
    @objc func showAbout() {
        NSApp.orderFrontStandardAboutPanel(
            options: [
                .applicationName: "VSpot ClipboardApp",
                .applicationVersion: "1.0.0",
                .version: "Version 1.0.0",
                .credits: NSAttributedString(string: """
                    © 2024 VSpot ClipboardApp
                    
                    A powerful clipboard manager for macOS.
                    
                    Features:
                    • Real-time clipboard monitoring
                    • Sticky notes with colors
                    • Search functionality
                    • Menu bar access
                    """)
            ]
        )
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

