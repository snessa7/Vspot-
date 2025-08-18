//
//  AIPromptsManager.swift
//  Vspot
//
//  Manages AI prompts storage and operations
//

import Foundation
import SwiftUI

class AIPromptsManager: ObservableObject {
    static let shared = AIPromptsManager()
    
    @Published var prompts: [AIPrompt] = []
    
    private let userDefaultsKey = "aiPrompts"
    
    init() {
        loadPrompts()
        if prompts.isEmpty {
            loadDefaultPrompts()
        }
    }
    
    // MARK: - CRUD Operations
    
    func addPrompt(title: String, content: String, category: PromptCategory = .general, tags: [String] = []) {
        let newPrompt = AIPrompt(title: title, content: content, category: category, tags: tags)
        prompts.insert(newPrompt, at: 0)
        savePrompts()
    }
    
    func updatePrompt(_ prompt: AIPrompt, title: String, content: String, category: PromptCategory, tags: [String]) {
        if let index = prompts.firstIndex(where: { $0.id == prompt.id }) {
            prompts[index].updateContent(title: title, content: content, category: category, tags: tags)
            savePrompts()
        }
    }
    
    func deletePrompt(_ prompt: AIPrompt) {
        prompts.removeAll { $0.id == prompt.id }
        savePrompts()
    }
    
    func toggleFavorite(_ prompt: AIPrompt) {
        if let index = prompts.firstIndex(where: { $0.id == prompt.id }) {
            prompts[index].isFavorite.toggle()
            savePrompts()
        }
    }
    
    func usePrompt(_ prompt: AIPrompt) -> String {
        if let index = prompts.firstIndex(where: { $0.id == prompt.id }) {
            prompts[index].incrementUseCount()
            savePrompts()
        }
        return prompt.content
    }
    
    // MARK: - Search and Filter
    
    func searchPrompts(query: String) -> [AIPrompt] {
        if query.isEmpty {
            return prompts
        }
        
        return prompts.filter { prompt in
            prompt.title.localizedCaseInsensitiveContains(query) ||
            prompt.content.localizedCaseInsensitiveContains(query) ||
            prompt.tags.contains { $0.localizedCaseInsensitiveContains(query) } ||
            prompt.category.rawValue.localizedCaseInsensitiveContains(query)
        }
    }
    
    func promptsByCategory(_ category: PromptCategory) -> [AIPrompt] {
        return prompts.filter { $0.category == category }
    }
    
    func favoritePrompts() -> [AIPrompt] {
        return prompts.filter { $0.isFavorite }
    }
    
    func mostUsedPrompts(limit: Int = 10) -> [AIPrompt] {
        return prompts.sorted { $0.useCount > $1.useCount }.prefix(limit).map { $0 }
    }
    
    // MARK: - Data Persistence
    
    func loadPrompts() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([AIPrompt].self, from: data) {
            prompts = decoded
        }
    }
    
    func savePrompts() {
        if let encoded = try? JSONEncoder().encode(prompts) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    // MARK: - Default Prompts
    
    private func loadDefaultPrompts() {
        let defaultPrompts = [
            AIPrompt(title: "Code Review", 
                    content: "Please review this code for:\n- Best practices\n- Potential bugs\n- Performance issues\n- Security concerns\n- Code readability\n\n[Paste your code here]", 
                    category: .review, 
                    tags: ["review", "quality"]),
            
            AIPrompt(title: "Debug Helper", 
                    content: "I'm encountering an issue with my code. Here's what's happening:\n\n**Problem:** [Describe the issue]\n**Expected:** [What should happen]\n**Actual:** [What actually happens]\n**Code:** [Paste relevant code]\n\nCan you help me identify and fix the problem?", 
                    category: .debugging, 
                    tags: ["debug", "fix", "troubleshoot"]),
            
            AIPrompt(title: "Explain Code", 
                    content: "Please explain this code in simple terms:\n- What does it do?\n- How does it work?\n- Any important concepts?\n- Potential improvements?\n\n[Paste your code here]", 
                    category: .coding, 
                    tags: ["explain", "learn", "understand"]),
            
            AIPrompt(title: "Write Documentation", 
                    content: "Please create clear documentation for this code including:\n- Purpose and overview\n- Parameters and return values\n- Usage examples\n- Important notes or warnings\n\n[Paste your code here]", 
                    category: .documentation, 
                    tags: ["docs", "readme", "comments"]),
            
            AIPrompt(title: "Improve Writing", 
                    content: "Please improve this text for:\n- Clarity and readability\n- Grammar and spelling\n- Professional tone\n- Conciseness\n\n[Paste your text here]", 
                    category: .writing, 
                    tags: ["improve", "edit", "polish"]),
            
            AIPrompt(title: "Creative Ideas", 
                    content: "I need creative ideas for: [Topic/Project]\n\nPlease provide:\n- 10 unique and innovative ideas\n- Brief explanation for each\n- Potential benefits or applications\n- Implementation suggestions", 
                    category: .creative, 
                    tags: ["brainstorm", "ideas", "innovation"]),
            
            AIPrompt(title: "Research Summary", 
                    content: "Please research and summarize information about: [Topic]\n\nInclude:\n- Key facts and statistics\n- Current trends\n- Important considerations\n- Reliable sources\n- Actionable insights", 
                    category: .research, 
                    tags: ["research", "summary", "facts"]),
            
            AIPrompt(title: "Task Breakdown", 
                    content: "Please break down this project/task into manageable steps:\n\n**Project:** [Describe your project]\n**Goal:** [What you want to achieve]\n**Timeline:** [Available timeframe]\n**Resources:** [What you have available]\n\nProvide a detailed action plan with priorities and estimated timeframes.", 
                    category: .productivity, 
                    tags: ["planning", "organize", "steps"])
        ]
        
        prompts = defaultPrompts
        savePrompts()
    }
}