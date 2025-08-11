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
                    NotesView(searchText: searchText)
                case .aiPrompts:
                    AIPromptsView(searchText: searchText)
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
    @ObservedObject var customTabManager = CustomTabManager.shared
    @State private var showingAddTab = false
    @State private var draggedTab: CustomTab?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                // Fixed tabs (compact)
                CompactTabButton(title: "Board", icon: "doc.on.clipboard", tab: .clipboard)
                CompactTabButton(title: "Notes", icon: "note.text", tab: .notes)
                CompactTabButton(title: "AI", icon: "sparkles", tab: .aiPrompts)
                
                // Custom tabs with drag reordering
                ForEach(customTabManager.customTabs.indices, id: \.self) { index in
                    let customTab = customTabManager.customTabs[index]
                    CompactTabButton(
                        title: abbreviatedTitle(customTab.name),
                        icon: customTab.icon,
                        tab: .custom(customTab.name)
                    )
                    .onDrag {
                        draggedTab = customTab
                        return NSItemProvider(object: customTab.id.uuidString as NSString)
                    }
                    .onDrop(of: [.text], isTargeted: nil) { providers in
                        if let draggedTab = draggedTab {
                            moveTab(draggedTab, to: customTab)
                            self.draggedTab = nil
                        }
                        return true
                    }
                }
                
                // Fixed add button
                Button(action: { showingAddTab = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .padding(4)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(4)
                }
                .buttonStyle(.plain)
                .help("Add Custom Tab")
            }
            .padding(.horizontal, 8)
        }
        .sheet(isPresented: $showingAddTab) {
            AddCustomTabView()
        }
    }
    
    private func abbreviatedTitle(_ title: String) -> String {
        if title.count <= 6 {
            return title
        }
        
        // Try common abbreviations first
        let abbreviations = [
            "Passwords": "Pass",
            "Password": "Pass", 
            "Code Snippets": "Code",
            "Snippets": "Snip",
            "Documents": "Docs",
            "Links": "Link",
            "Contacts": "Cont",
            "Projects": "Proj",
            "Templates": "Temp",
            "Settings": "Set"
        ]
        
        if let abbrev = abbreviations[title] {
            return abbrev
        }
        
        // Fallback: take first 4 chars + first char of each word after first
        let words = title.split(separator: " ")
        if words.count > 1 {
            let firstWord = String(words[0].prefix(3))
            let otherChars = words.dropFirst().compactMap { $0.first }.map(String.init).joined()
            return firstWord + otherChars.prefix(2)
        } else {
            return String(title.prefix(4))
        }
    }
    
    private func moveTab(_ sourceTab: CustomTab, to targetTab: CustomTab) {
        guard let sourceIndex = customTabManager.customTabs.firstIndex(where: { $0.id == sourceTab.id }),
              let targetIndex = customTabManager.customTabs.firstIndex(where: { $0.id == targetTab.id }) else {
            return
        }
        
        withAnimation(.easeInOut(duration: 0.2)) {
            let movedTab = customTabManager.customTabs.remove(at: sourceIndex)
            customTabManager.customTabs.insert(movedTab, at: targetIndex)
            customTabManager.saveCustomTabs()
        }
    }
}

struct CompactTabButton: View {
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
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                Text(title)
                    .font(.system(size: 8))
                    .lineLimit(1)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
            .cornerRadius(4)
        }
        .buttonStyle(.plain)
        .foregroundColor(isSelected ? .accentColor : .secondary)
        .help(getFullTitle(title, tab))
    }
    
    private func getFullTitle(_ abbreviatedTitle: String, _ tab: AppTab) -> String {
        switch tab {
        case .clipboard:
            return "Clipboard"
        case .notes:
            return "Notes" 
        case .aiPrompts:
            return "AI Prompts"
        case .custom(let name):
            return name
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

// MARK: - Add Custom Tab View

struct AddCustomTabView: View {
    @State private var tabName = ""
    @State private var selectedIcon = "folder"
    @State private var isSecure = false
    
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var customTabManager = CustomTabManager.shared
    @EnvironmentObject var appState: AppState
    
    private let availableIcons = [
        "folder", "key.fill", "chevron.left.forwardslash.chevron.right", 
        "note.text", "link", "person.fill", "creditcard.fill", 
        "book.fill", "lightbulb.fill", "star.fill", "heart.fill", "tag.fill"
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tab Name")
                        .font(.headline)
                    
                    TextField("Enter tab name", text: $tabName)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Icon")
                        .font(.headline)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                        ForEach(availableIcons, id: \.self) { icon in
                            Button(action: { selectedIcon = icon }) {
                                Image(systemName: icon)
                                    .font(.system(size: 20))
                                    .foregroundColor(selectedIcon == icon ? .white : .primary)
                                    .frame(width: 40, height: 40)
                                    .background(selectedIcon == icon ? Color.blue : Color.gray.opacity(0.2))
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                Toggle("Secure Tab (for sensitive data)", isOn: $isSecure)
                
                Spacer()
            }
            .padding()
            .navigationTitle("New Custom Tab")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createTab()
                    }
                    .disabled(tabName.isEmpty)
                }
            }
        }
        .presentationSizing(.fitted)
        .frame(width: 450, height: 400)
    }
    
    private func createTab() {
        let newTab = customTabManager.createTab(name: tabName, icon: selectedIcon, isSecure: isSecure)
        appState.currentTab = .custom(newTab.name)
        dismiss()
    }
}

#Preview {
    MenuBarContentView()
        .environmentObject(AppState())
        .environmentObject(ClipboardManager())
}