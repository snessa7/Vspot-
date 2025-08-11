//
//  CustomTabView.swift
//  ClipboardApp
//
//  Custom user-defined tabs
//

import SwiftUI

struct CustomTabView: View {
    let tabName: String
    @ObservedObject var customTabManager = CustomTabManager.shared
    @State private var searchText = ""
    @State private var showingAddItem = false
    @State private var selectedItem: CustomTabItem? = nil
    @State private var showingEditItem = false
    @State private var showingTabSettings = false
    
    private var currentTab: CustomTab? {
        customTabManager.getTab(byName: tabName)
    }
    
    private var filteredItems: [CustomTabItem] {
        customTabManager.searchItems(in: tabName, query: searchText)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if let tab = currentTab {
                // Header
                headerView(for: tab)
                
                Divider()
                
                // Content
                if filteredItems.isEmpty {
                    emptyStateView
                } else {
                    itemsList(for: tab)
                }
            } else {
                // Tab not found
                Text("Tab '\(tabName)' not found")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .sheet(isPresented: $showingAddItem) {
            if let tab = currentTab {
                AddEditCustomItemView(tab: tab, isEditing: false)
            }
        }
        .sheet(item: $selectedItem) { item in
            if let tab = currentTab {
                AddEditCustomItemView(tab: tab, isEditing: true, item: item)
            }
        }
        .sheet(isPresented: $showingTabSettings) {
            if let tab = currentTab {
                CustomTabSettingsView(tab: tab)
            }
        }
    }
    
    // MARK: - Header View
    
    private func headerView(for tab: CustomTab) -> some View {
        VStack(spacing: 8) {
            HStack {
                HStack {
                    Image(systemName: tab.icon)
                        .foregroundColor(.blue)
                    Text(tab.name)
                        .font(.headline)
                }
                
                Spacer()
                
                // Settings button
                Button(action: { showingTabSettings = true }) {
                    Image(systemName: "gear")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
            
            HStack {
                Text("\(filteredItems.count) items")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: { showingAddItem = true }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("New Item")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            if let tab = currentTab {
                Image(systemName: tab.icon)
                    .font(.system(size: 48))
                    .foregroundColor(.gray)
                
                Text("No Items")
                    .font(.headline)
                
                Text(searchText.isEmpty ? 
                     "Add your first item to get started" : 
                     "No items match your search")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Button(action: { showingAddItem = true }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Add Item")
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Items List
    
    private func itemsList(for tab: CustomTab) -> some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(filteredItems) { item in
                    CustomItemRowView(
                        tab: tab,
                        item: item,
                        onEdit: {
                            selectedItem = item
                        }
                    )
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Custom Item Row View

struct CustomItemRowView: View {
    let tab: CustomTab
    let item: CustomTabItem
    let onEdit: () -> Void
    @ObservedObject var customTabManager = CustomTabManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with primary field and actions
            HStack {
                // Primary field (first field or title)
                if let primaryField = tab.fields.first,
                   let primaryValue = item.values[primaryField.name] {
                    HStack {
                        Image(systemName: tab.icon)
                            .foregroundColor(.blue)
                        
                        Text(primaryValue)
                            .font(.headline)
                            .lineLimit(1)
                    }
                } else {
                    Text("Untitled Item")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Actions
                HStack(spacing: 12) {
                    // Copy primary value
                    if let primaryField = tab.fields.first,
                       let primaryValue = item.values[primaryField.name] {
                        Button(action: { copyValue(primaryValue) }) {
                            Image(systemName: "doc.on.clipboard")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                        .help("Copy \(primaryField.name)")
                    }
                    
                    // Edit
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .foregroundColor(.orange)
                    }
                    .buttonStyle(.plain)
                    
                    // Delete
                    Button(action: { deleteItem() }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Additional fields preview
            VStack(alignment: .leading, spacing: 4) {
                ForEach(tab.fields.dropFirst().prefix(2), id: \.id) { field in
                    if let value = item.values[field.name], !value.isEmpty {
                        HStack {
                            Text("\(field.name):")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if field.isSecure {
                                Text("••••••••")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Button(action: { copyValue(value) }) {
                                    Image(systemName: "doc.on.clipboard")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                                .buttonStyle(.plain)
                            } else {
                                Text(value)
                                    .font(.caption)
                                    .foregroundColor(.primary)
                                    .lineLimit(field.type == .multilineText ? 2 : 1)
                            }
                            
                            Spacer()
                        }
                    }
                }
                
                // Show indicator if there are more fields
                if tab.fields.count > 3 {
                    Text("+\(tab.fields.count - 3) more fields")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Date info
            HStack {
                Text("Created \(item.createdDate, style: .date)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                if item.modifiedDate != item.createdDate {
                    Text("• Modified \(item.modifiedDate, style: .date)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .onTapGesture(count: 2) {
            // Double-tap to edit
            onEdit()
        }
    }
    
    private func copyValue(_ value: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)
        NSSound.beep()
    }
    
    private func deleteItem() {
        customTabManager.deleteItem(from: tab.name, item: item)
    }
}

// MARK: - Add/Edit Item View

struct AddEditCustomItemView: View {
    let tab: CustomTab
    let isEditing: Bool
    let item: CustomTabItem?
    
    @State private var fieldValues: [String: String] = [:]
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var customTabManager = CustomTabManager.shared
    
    init(tab: CustomTab, isEditing: Bool, item: CustomTabItem? = nil) {
        self.tab = tab
        self.isEditing = isEditing
        self.item = item
        
        _fieldValues = State(initialValue: item?.values ?? [:])
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(tab.fields) { field in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(field.name)
                                    .font(.headline)
                                
                                if field.isRequired {
                                    Text("*")
                                        .foregroundColor(.red)
                                }
                                
                                Spacer()
                            }
                            
                            fieldInput(for: field)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(isEditing ? "Edit Item" : "New Item")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveItem()
                    }
                    .disabled(!isValidInput())
                }
            }
        }
        .presentationSizing(.fitted)
        .frame(minWidth: 500, idealWidth: 600, maxWidth: 700, 
               minHeight: 400, idealHeight: 500, maxHeight: 600)
    }
    
    private func fieldInput(for field: CustomField) -> some View {
        Group {
            switch field.type {
            case .text, .number:
                TextField(field.placeholder, text: Binding(
                    get: { fieldValues[field.name] ?? "" },
                    set: { fieldValues[field.name] = $0 }
                ))
                .textFieldStyle(.roundedBorder)
                
            case .password:
                SecureField(field.placeholder, text: Binding(
                    get: { fieldValues[field.name] ?? "" },
                    set: { fieldValues[field.name] = $0 }
                ))
                .textFieldStyle(.roundedBorder)
                
            case .multilineText:
                TextEditor(text: Binding(
                    get: { fieldValues[field.name] ?? "" },
                    set: { fieldValues[field.name] = $0 }
                ))
                .frame(minHeight: 80)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                
            case .date:
                // For now, use text field - can be enhanced later
                TextField(field.placeholder, text: Binding(
                    get: { fieldValues[field.name] ?? "" },
                    set: { fieldValues[field.name] = $0 }
                ))
                .textFieldStyle(.roundedBorder)
                
            case .dropdown:
                // For now, use text field - can be enhanced later
                TextField(field.placeholder, text: Binding(
                    get: { fieldValues[field.name] ?? "" },
                    set: { fieldValues[field.name] = $0 }
                ))
                .textFieldStyle(.roundedBorder)
            }
        }
    }
    
    private func isValidInput() -> Bool {
        for field in tab.fields where field.isRequired {
            if fieldValues[field.name]?.isEmpty ?? true {
                return false
            }
        }
        return true
    }
    
    private func saveItem() {
        if isEditing, let item = item {
            customTabManager.updateItem(in: tab.name, item: item, values: fieldValues)
        } else {
            customTabManager.addItem(to: tab.name, values: fieldValues)
        }
        dismiss()
    }
}

// MARK: - Tab Settings View

struct CustomTabSettingsView: View {
    let tab: CustomTab
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Tab Settings")
                    .font(.headline)
                    .padding()
                
                Text("Advanced tab management will be available in a future update")
                    .foregroundColor(.secondary)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationSizing(.fitted)
        .frame(width: 400, height: 300)
    }
}

#Preview {
    CustomTabView(tabName: "Passwords")
}