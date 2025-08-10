//
//  AIPromptsView.swift
//  ClipboardApp
//
//  AI Prompts management interface
//

import SwiftUI

struct AIPromptsView: View {
    @ObservedObject var promptsManager = AIPromptsManager.shared
    @State private var searchText: String
    @State private var selectedCategory: PromptCategory? = nil
    @State private var showingAddPrompt = false
    @State private var selectedPrompt: AIPrompt? = nil
    @State private var showingEditPrompt = false
    
    init(searchText: String = "") {
        _searchText = State(initialValue: searchText)
    }
    
    var filteredPrompts: [AIPrompt] {
        var prompts = promptsManager.searchPrompts(query: searchText)
        
        if let category = selectedCategory {
            prompts = prompts.filter { $0.category == category }
        }
        
        return prompts.sorted { lhs, rhs in
            if lhs.isFavorite != rhs.isFavorite {
                return lhs.isFavorite && !rhs.isFavorite
            }
            return lhs.useCount > rhs.useCount
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with category filter
            headerView
            
            Divider()
            
            // Content
            if filteredPrompts.isEmpty {
                emptyStateView
            } else {
                promptsList
            }
        }
        .sheet(isPresented: $showingAddPrompt) {
            AddEditPromptView(isEditing: false)
        }
        .sheet(item: $selectedPrompt) { prompt in
            AddEditPromptView(isEditing: true, prompt: prompt)
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 8) {
            // Category filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // All button
                    Button(action: { selectedCategory = nil }) {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("All")
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(selectedCategory == nil ? Color.blue : Color.gray.opacity(0.2))
                        .foregroundColor(selectedCategory == nil ? .white : .primary)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    
                    // Category buttons
                    ForEach(PromptCategory.allCases, id: \.self) { category in
                        Button(action: { selectedCategory = category }) {
                            HStack {
                                Image(systemName: category.icon)
                                Text(category.rawValue)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedCategory == category ? Color(category.color) : Color.gray.opacity(0.2))
                            .foregroundColor(selectedCategory == category ? .white : .primary)
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
            
            // Add button
            HStack {
                Text("\(filteredPrompts.count) prompts")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: { showingAddPrompt = true }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("New Prompt")
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
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text("No AI Prompts")
                .font(.headline)
            
            Text(selectedCategory != nil ? 
                 "No prompts in this category" : 
                 searchText.isEmpty ? 
                 "Add your first AI prompt to get started" : 
                 "No prompts match your search")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: { showingAddPrompt = true }) {
                HStack {
                    Image(systemName: "plus")
                    Text("Add Prompt")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Prompts List
    
    private var promptsList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(filteredPrompts) { prompt in
                    PromptRowView(prompt: prompt, onEdit: {
                        selectedPrompt = prompt
                    })
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Prompt Row View

struct PromptRowView: View {
    let prompt: AIPrompt
    let onEdit: () -> Void
    @ObservedObject var promptsManager = AIPromptsManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                HStack {
                    Image(systemName: prompt.category.icon)
                        .foregroundColor(Color(prompt.category.color))
                    
                    Text(prompt.title)
                        .font(.headline)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Stats and actions
                HStack(spacing: 12) {
                    // Use count
                    if prompt.useCount > 0 {
                        Text("\(prompt.useCount)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Favorite
                    Button(action: { promptsManager.toggleFavorite(prompt) }) {
                        Image(systemName: prompt.isFavorite ? "heart.fill" : "heart")
                            .foregroundColor(prompt.isFavorite ? .red : .gray)
                    }
                    .buttonStyle(.plain)
                    
                    // Copy
                    Button(action: { copyPrompt() }) {
                        Image(systemName: "doc.on.clipboard")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                    
                    // Edit
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .foregroundColor(.orange)
                    }
                    .buttonStyle(.plain)
                    
                    // Delete
                    Button(action: { promptsManager.deletePrompt(prompt) }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Content preview
            Text(prompt.content)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
            
            // Tags
            if !prompt.tags.isEmpty {
                HStack {
                    ForEach(prompt.tags.prefix(3), id: \.self) { tag in
                        Text(tag)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(4)
                    }
                    
                    if prompt.tags.count > 3 {
                        Text("+\(prompt.tags.count - 3)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .onTapGesture(count: 2) {
            copyPrompt()
        }
    }
    
    private func copyPrompt() {
        let content = promptsManager.usePrompt(prompt)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(content, forType: .string)
        
        // Show feedback (could add a toast notification here)
        NSSound.beep()
    }
}

// MARK: - Add/Edit Prompt View

struct AddEditPromptView: View {
    let isEditing: Bool
    let prompt: AIPrompt?
    
    @State private var title: String
    @State private var content: String
    @State private var category: PromptCategory
    @State private var tagsText: String
    
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var promptsManager = AIPromptsManager.shared
    
    init(isEditing: Bool, prompt: AIPrompt? = nil) {
        self.isEditing = isEditing
        self.prompt = prompt
        
        _title = State(initialValue: prompt?.title ?? "")
        _content = State(initialValue: prompt?.content ?? "")
        _category = State(initialValue: prompt?.category ?? .general)
        _tagsText = State(initialValue: prompt?.tags.joined(separator: ", ") ?? "")
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Form {
                    Section("Details") {
                        TextField("Title", text: $title)
                            .textFieldStyle(.roundedBorder)
                        
                        Picker("Category", selection: $category) {
                            ForEach(PromptCategory.allCases, id: \.self) { category in
                                HStack {
                                    Image(systemName: category.icon)
                                    Text(category.rawValue)
                                }
                                .tag(category)
                            }
                        }
                        .pickerStyle(.menu)
                        
                        TextField("Tags (comma separated)", text: $tagsText)
                            .textFieldStyle(.roundedBorder)
                            .help("Enter tags separated by commas")
                    }
                }
                .frame(height: 140)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Prompt Content")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    TextEditor(text: $content)
                        .font(.body)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.bottom)
            }
            .navigationTitle(isEditing ? "Edit Prompt" : "New Prompt")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        savePrompt()
                    }
                    .disabled(title.isEmpty || content.isEmpty)
                }
            }
        }
        .presentationSizing(.fitted)
        .frame(minWidth: 500, idealWidth: 700, maxWidth: 800, minHeight: 400, idealHeight: 550, maxHeight: 600)
    }
    
    private func savePrompt() {
        let tags = tagsText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        
        if isEditing, let prompt = prompt {
            promptsManager.updatePrompt(prompt, title: title, content: content, category: category, tags: tags)
        } else {
            promptsManager.addPrompt(title: title, content: content, category: category, tags: tags)
        }
        
        dismiss()
    }
}