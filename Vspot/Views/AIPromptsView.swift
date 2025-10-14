//
//  AIPromptsView.swift
//  Vspot
//
//  AI Prompts management interface
//

import SwiftUI

struct AIPromptsView: View {
    @ObservedObject var promptsManager = AIPromptsManager.shared
    let searchText: String
    @State private var selectedCategory: PromptCategory? = nil
    @State private var showingAddPrompt = false
    @State private var selectedPrompt: AIPrompt? = nil
    @State private var showingEditPrompt = false
    
    init(searchText: String = "") {
        self.searchText = searchText
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
            
            // Removed redundant "Add Prompt" button - use the one in the header instead
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
    @State private var isSaving = false
    
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
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Details Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Details")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Title")
                                .font(.subheadline)
                            TextField("Enter prompt title", text: $title)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Category")
                                .font(.subheadline)
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
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tags")
                                .font(.subheadline)
                            TextField("Enter tags separated by commas", text: $tagsText)
                                .textFieldStyle(.roundedBorder)
                                .help("Enter tags separated by commas")
                        }
                    }
                    
                    // Content Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Prompt Content")
                            .font(.headline)
                        
                        TextEditor(text: $content)
                            .font(.body)
                            .frame(minHeight: 200)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(8)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle(isEditing ? "Edit Prompt" : "New Prompt")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        // Reset form state before dismissing
                        title = ""
                        content = ""
                        category = .general
                        tagsText = ""
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: {
                        savePrompt()
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
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || 
                             content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || 
                             isSaving)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .presentationSizing(.fitted)
    }
    
    private func savePrompt() {
        // Prevent double-saving
        guard !isSaving else { return }
        
        isSaving = true
        
        // Clean up input values
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        let tags = tagsText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        
        // Add some debug logging
        print("Saving prompt: \(cleanTitle)")
        print("Category: \(category)")
        print("Tags: \(tags)")
        print("Is editing: \(isEditing)")
        
        // Perform the save operation
        if isEditing, let prompt = prompt {
            promptsManager.updatePrompt(prompt, title: cleanTitle, content: cleanContent, category: category, tags: tags)
            print("Successfully updated prompt with ID: \(prompt.id)")
        } else {
            promptsManager.addPrompt(title: cleanTitle, content: cleanContent, category: category, tags: tags)
            print("Successfully added new prompt: \(cleanTitle)")
        }
        
        // Reset form state
        title = ""
        content = ""
        category = .general
        tagsText = ""
        
        // Small delay to show saving state, then dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isSaving = false
            dismiss()
        }
    }
}