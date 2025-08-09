//
//  NotesManager.swift
//  ClipboardApp
//
//  Manages sticky notes
//

import Foundation
import SwiftUI

class NotesManager: ObservableObject {
    @Published var notes: [Note] = []
    
    init() {
        loadNotes()
    }
    
    func addNote(title: String, content: String, color: NoteColor = .yellow) {
        let newNote = Note(
            title: title,
            content: content,
            color: color
        )
        notes.insert(newNote, at: 0)
        saveNotes()
    }
    
    func updateNote(_ note: Note) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes[index] = note
            notes[index].lastModified = Date()
            saveNotes()
        }
    }
    
    func deleteNote(_ note: Note) {
        notes.removeAll { $0.id == note.id }
        saveNotes()
    }
    
    func searchNotes(query: String) -> [Note] {
        if query.isEmpty {
            return notes
        }
        
        return notes.filter { note in
            note.title.localizedCaseInsensitiveContains(query) ||
            note.content.localizedCaseInsensitiveContains(query) ||
            note.tags.contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }
    
    private func loadNotes() {
        // Load from UserDefaults for now (will use Core Data later)
        if let data = UserDefaults.standard.data(forKey: "stickyNotes"),
           let decoded = try? JSONDecoder().decode([Note].self, from: data) {
            notes = decoded
        } else {
            // Add sample notes for demo
            notes = [
                Note(
                    title: "Welcome to ClipboardApp",
                    content: "Your menubar clipboard manager with sticky notes!",
                    color: .yellow
                ),
                Note(
                    title: "Features",
                    content: "• Real-time clipboard monitoring\n• Sticky notes\n• Custom tabs\n• App Store ready",
                    color: .blue
                )
            ]
        }
    }
    
    private func saveNotes() {
        // Save to UserDefaults for now (will use Core Data later)
        if let encoded = try? JSONEncoder().encode(notes) {
            UserDefaults.standard.set(encoded, forKey: "stickyNotes")
        }
    }
}