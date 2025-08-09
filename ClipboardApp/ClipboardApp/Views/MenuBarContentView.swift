//
//  MenuBarContentView.swift
//  ClipboardApp
//
//  Main content view for the menubar app
//

import SwiftUI

struct MenuBarContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var clipboardManager: ClipboardManager
    @State private var searchText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with tabs
            HeaderView()
                .padding(.horizontal)
                .padding(.vertical, 8)
            
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
                    NotesView()
                case .custom(let name):
                    CustomTabView(tabName: name)
                }
            }
            .frame(maxWidth: 400, maxHeight: 500)
            
            Divider()
            
            // Footer with actions
            FooterView()
                .padding(.horizontal)
                .padding(.vertical, 8)
        }
        .frame(width: 400)
    }
}

struct HeaderView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        HStack {
            // Tab buttons
            TabButton(title: "Clipboard", icon: "doc.on.clipboard", tab: .clipboard)
            TabButton(title: "Notes", icon: "note.text", tab: .notes)
            
            Spacer()
            
            // Settings button
            Button(action: {
                // Open settings
            }) {
                Image(systemName: "gear")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
    }
}

struct TabButton: View {
    let title: String
    let icon: String
    let tab: AppTab
    @EnvironmentObject var appState: AppState
    
    var isSelected: Bool {
        appState.currentTab == tab
    }
    
    var body: some View {
        Button(action: {
            appState.currentTab = tab
        }) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(title)
                    .font(.system(size: 13))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .foregroundColor(isSelected ? .accentColor : .secondary)
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("Search...", text: $text)
                .textFieldStyle(.plain)
        }
        .padding(6)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(6)
    }
}

struct FooterView: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    
    var body: some View {
        HStack {
            Text("\(clipboardManager.items.count) items")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button("Clear All") {
                clipboardManager.clearAll()
            }
            .font(.caption)
            .buttonStyle(.plain)
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .font(.caption)
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    MenuBarContentView()
        .environmentObject(AppState())
        .environmentObject(ClipboardManager())
}