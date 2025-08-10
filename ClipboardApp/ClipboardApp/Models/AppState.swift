//
//  AppState.swift
//  ClipboardApp
//
//  Global app state management
//

import Foundation
import SwiftUI

class AppState: ObservableObject {
    @Published var isMenuBarVisible: Bool = true
    @Published var menuBarStyle: MenuBarStyle = .window
    @Published var currentTab: AppTab = .clipboard
    @Published var isLaunchAtLoginEnabled: Bool = false
    @Published var globalShortcutsEnabled: Bool = true
    
    // User preferences
    @AppStorage("menuBarStyle") private var storedMenuBarStyle: String = "window"
    @AppStorage("launchAtLogin") private var storedLaunchAtLogin: Bool = false
    @AppStorage("globalShortcuts") private var storedGlobalShortcuts: Bool = true
    
    init() {
        loadPreferences()
    }
    
    private func loadPreferences() {
        if storedMenuBarStyle == "popover" {
            menuBarStyle = .popover
        } else if storedMenuBarStyle == "automatic" {
            menuBarStyle = .automatic
        } else {
            menuBarStyle = .window
        }
        
        isLaunchAtLoginEnabled = storedLaunchAtLogin
        globalShortcutsEnabled = storedGlobalShortcuts
    }
    
    func savePreferences() {
        storedMenuBarStyle = menuBarStyle.rawValue
        storedLaunchAtLogin = isLaunchAtLoginEnabled
        storedGlobalShortcuts = globalShortcutsEnabled
    }
}

enum MenuBarStyle: String {
    case window = "window"
    case popover = "popover"
    case automatic = "automatic"
}

enum AppTab: Equatable {
    case clipboard
    case notes
    case aiPrompts
    case custom(String)
    
    static func == (lhs: AppTab, rhs: AppTab) -> Bool {
        switch (lhs, rhs) {
        case (.clipboard, .clipboard), (.notes, .notes), (.aiPrompts, .aiPrompts):
            return true
        case let (.custom(name1), .custom(name2)):
            return name1 == name2
        default:
            return false
        }
    }
}