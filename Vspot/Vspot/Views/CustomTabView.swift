//
//  CustomTabView.swift
//  Vspot
//
//  Custom user-defined tabs
//

import SwiftUI

struct CustomTabView: View {
    let tabName: String
    let searchText: String
    @ObservedObject var customTabManager = CustomTabManager.shared
    @State private var showingAddItem = false
    @State private var selectedItem: CustomTabItem? = nil
    @State private var showingEditItem = false
    
    init(tabName: String, searchText: String = "") {
        self.tabName = tabName
        self.searchText = searchText
    }
    
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
                
                // Removed redundant "Add Item" button - use the one in the header instead
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
    
    var primaryValue: String {
        // Use the first field's value as the title, or "Untitled"
        if let firstField = tab.fields.first,
           let value = item.values[firstField.name], !value.isEmpty {
            return value
        }
        return "Untitled"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with title and main actions
            HStack {
                Image(systemName: tab.icon)
                    .foregroundColor(.blue)
                
                Text(primaryValue)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button("Edit") {
                        onEdit()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    
                    Button("Delete") {
                        deleteItem()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .foregroundColor(.red)
                }
            }
            
            // All fields with copy buttons
            VStack(spacing: 8) {
                ForEach(tab.fields, id: \.id) { field in
                    if let value = item.values[field.name], !value.isEmpty {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(field.name)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                if field.isSecure {
                                    Text("••••••••")
                                        .font(.body)
                                        .foregroundColor(.primary)
                                } else {
                                    Text(value)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                        .lineLimit(field.type == .multilineText ? 3 : 1)
                                }
                            }
                            
                            Spacer()
                            
                            Button("Copy") {
                                copyToClipboard(value)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.mini)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private func copyToClipboard(_ value: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)
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
    @State private var isSaving = false
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var customTabManager = CustomTabManager.shared
    
    init(tab: CustomTab, isEditing: Bool, item: CustomTabItem? = nil) {
        self.tab = tab
        self.isEditing = isEditing
        self.item = item
        
        // Initialize fieldValues with existing item values or empty strings for all fields
        var initialValues: [String: String] = [:]
        
        // First, set all fields to empty strings
        for field in tab.fields {
            initialValues[field.name] = ""
        }
        
        // Then, override with existing values if editing
        if let existingValues = item?.values {
            for (key, value) in existingValues {
                initialValues[key] = value
            }
        }
        
        _fieldValues = State(initialValue: initialValues)
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
                    Button(action: {
                        saveItem()
                    }) {
                        if isSaving {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Saving...")
                            }
                        } else {
                            Text("Save")
                        }
                    }
                    .disabled(!isValidInput() || isSaving)
                }
            }
        }
        .frame(width: 480, height: 420)
        .presentationSizing(.fitted)
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
        // Check if any required fields are missing or empty
        for field in tab.fields where field.isRequired {
            let value = fieldValues[field.name] ?? ""
            if value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return false
            }
        }
        return true
    }
    
    private func saveItem() {
        // Prevent double-saving
        guard !isSaving else { return }
        
        isSaving = true
        
        // Clean up field values by trimming whitespace
        var cleanedValues: [String: String] = [:]
        for (key, value) in fieldValues {
            let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
            cleanedValues[key] = trimmedValue
        }
        
        // Add some debug logging
        print("Saving item to tab: \(tab.name)")
        print("Field values: \(cleanedValues)")
        print("Is editing: \(isEditing)")
        
        // Perform the save operation
        if isEditing, let item = item {
            customTabManager.updateItem(in: tab.name, item: item, values: cleanedValues)
            print("Successfully updated item with ID: \(item.id)")
        } else {
            customTabManager.addItem(to: tab.name, values: cleanedValues)
            print("Successfully added new item to tab: \(tab.name)")
        }
        
        // Small delay to show saving state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isSaving = false
            dismiss()
        }
    }
}


#Preview {
    CustomTabView(tabName: "Passwords", searchText: "")
        .environmentObject(ClipboardManager())
}