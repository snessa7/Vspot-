//
//  ClipboardAppApp.swift
//  ClipboardApp
//
//  MenuBar-only clipboard manager for macOS
//

import SwiftUI

@main
struct ClipboardAppApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()
    @StateObject private var clipboardManager = ClipboardManager()
    
    var body: some Scene {
        // MenuBarExtra requires macOS 13.0+
        MenuBarExtra {
            MenuBarContentView()
                .environmentObject(appState)
                .environmentObject(clipboardManager)
        } label: {
            Image(systemName: "v.circle.fill")
                .symbolRenderingMode(.hierarchical)
        }
        .menuBarExtraStyle(.window)
    }
}

// App delegate for handling app lifecycle
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide from dock (menubar-only app)
        NSApp.setActivationPolicy(.accessory)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Cleanup when app quits
    }
}