//
//  MenuBarContentView.swift
//  Vspot
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
                    CustomTabView(tabName: name, searchText: searchText)
                }
            }
            .frame(maxWidth: 400, maxHeight: 600)
            
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
    @State private var tabToDelete: CustomTab?
    @State private var showingDeleteConfirmation = false
    @State private var dragTargetIndex: Int?
    @State private var showDropIndicator = false
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                // Fixed tabs (compact)
                CompactTabButton(title: "Board", icon: "doc.on.clipboard", tab: .clipboard)
                CompactTabButton(title: "AI", icon: "sparkles", tab: .aiPrompts)
                CompactTabButton(title: "Notes", icon: "note.text", tab: .notes)
                
                // Custom tabs with improved drag reordering
                ForEach(Array(customTabManager.customTabs.enumerated()), id: \.element.id) { index, customTab in
                    HStack(spacing: 2) {
                        // Drop indicator before tab
                        if showDropIndicator && dragTargetIndex == index {
                            Rectangle()
                                .fill(Color.accentColor)
                                .frame(width: 2, height: 20)
                                .animation(.easeInOut(duration: 0.2), value: showDropIndicator)
                        }
                        
                        CompactTabButton(
                            title: abbreviatedTitle(customTab.name),
                            icon: customTab.icon,
                            tab: .custom(customTab.name)
                        )
                        .opacity(draggedTab?.id == customTab.id ? 0.5 : 1.0)
                        .scaleEffect(draggedTab?.id == customTab.id ? 0.95 : 1.0)
                        .contextMenu {
                            Button(action: {
                                confirmDeleteTab(customTab)
                            }) {
                                Label("Delete Tab", systemImage: "trash")
                            }
                            .foregroundColor(.red)
                            
                            Button(action: {
                                // TODO: Implement rename functionality
                            }) {
                                Label("Rename Tab", systemImage: "pencil")
                            }
                        }
                        .onDrag {
                            draggedTab = customTab
                            return NSItemProvider(object: customTab.id.uuidString as NSString)
                        }
                        .onDrop(of: [.text], isTargeted: nil) { providers in
                            return handleDrop(at: index)
                        }
                        
                        // Drop indicator after last tab
                        if showDropIndicator && dragTargetIndex == customTabManager.customTabs.count && index == customTabManager.customTabs.count - 1 {
                            Rectangle()
                                .fill(Color.accentColor)
                                .frame(width: 2, height: 20)
                                .animation(.easeInOut(duration: 0.2), value: showDropIndicator)
                        }
                    }
                }
                
                // Drop zone at the end for appending
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 20, height: 20)
                    .onDrop(of: [.text], isTargeted: nil) { providers in
                        return handleDrop(at: customTabManager.customTabs.count)
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
            .onDrop(of: [.text], isTargeted: nil) { providers in
                // Reset drag state when dropping outside valid areas
                resetDragState()
                return false
            }
        }
        .sheet(isPresented: $showingAddTab) {
            AddCustomTabView()
        }
        .confirmationDialog(
            "Delete Tab",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let tab = tabToDelete {
                    deleteCustomTab(tab)
                }
            }
            Button("Cancel", role: .cancel) {
                resetDeleteState()
            }
        } message: {
            if let tab = tabToDelete {
                Text("Are you sure you want to delete the '\(tab.name)' tab? This will permanently remove all items in this tab.")
            }
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
    
    // MARK: - Drag and Drop Handling
    
    private func handleDrop(at targetIndex: Int) -> Bool {
        guard let draggedTab = draggedTab else {
            resetDragState()
            return false
        }
        
        guard let sourceIndex = customTabManager.customTabs.firstIndex(where: { $0.id == draggedTab.id }) else {
            resetDragState()
            return false
        }
        
        // Don't move if dropping on same position
        if sourceIndex == targetIndex {
            resetDragState()
            return true
        }
        
        // Perform the reorder operation using CustomTabManager's method
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            customTabManager.reorderTabs(from: sourceIndex, to: targetIndex)
        }
        
        resetDragState()
        return true
    }
    
    private func resetDragState() {
        withAnimation(.easeOut(duration: 0.2)) {
            draggedTab = nil
            dragTargetIndex = nil
            showDropIndicator = false
        }
    }
    
    // MARK: - Deletion Handling
    
    private func confirmDeleteTab(_ tab: CustomTab) {
        tabToDelete = tab
        showingDeleteConfirmation = true
    }
    
    private func deleteCustomTab(_ tab: CustomTab) {
        // If we're currently viewing the tab being deleted, switch to clipboard tab
        if appState.currentTab == .custom(tab.name) {
            appState.currentTab = .clipboard
        }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            customTabManager.deleteTab(tab)
        }
        
        resetDeleteState()
    }
    
    private func resetDeleteState() {
        tabToDelete = nil
        showingDeleteConfirmation = false
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
        .foregroundColor(isSelected ? .accentColor : .secondary)
        .contentShape(Rectangle())
        .onTapGesture {
            appState.currentTab = tab
        }
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
                .onSubmit {
                    // Optional: Add any search submission behavior here
                }
        }
        .padding(6)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
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
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
                    ForEach(availableIcons, id: \.self) { icon in
                        Button(action: { selectedIcon = icon }) {
                            Image(systemName: icon)
                                .font(.system(size: 18))
                                .foregroundColor(selectedIcon == icon ? .white : .primary)
                                .frame(width: 36, height: 36)
                                .background(selectedIcon == icon ? Color.blue : Color.gray.opacity(0.15))
                                .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                        .help(icon)
                    }
                }
                .padding(.horizontal, 4)
            }
            
            Toggle("Secure Tab (for sensitive data)", isOn: $isSecure)
            
            Spacer()
            
            HStack {
                Button("Cancel") {
                    // Reset form state before dismissing
                    tabName = ""
                    selectedIcon = "folder"
                    isSecure = false
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Create") {
                    createTab()
                }
                .buttonStyle(.borderedProminent)
                .disabled(tabName.isEmpty)
            }
        }
        .padding()
        .presentationSizing(.fitted)
    }
    
    private func createTab() {
        guard !tabName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let newTab = customTabManager.createTab(name: tabName.trimmingCharacters(in: .whitespacesAndNewlines), icon: selectedIcon, isSecure: isSecure)
        appState.currentTab = .custom(newTab.name)
        
        // Reset form state
        tabName = ""
        selectedIcon = "folder"
        isSecure = false
        
        dismiss()
    }
}

#Preview {
    MenuBarContentView()
        .environmentObject(AppState())
        .environmentObject(ClipboardManager())
}