//
//  NotesView.swift
//  ClipboardApp
//
//  Sticky notes view
//

import SwiftUI

struct NotesView: View {
    @StateObject private var notesManager = NotesManager.shared
    @State private var isEditing = false
    @State private var noteToEdit: Note?
    let searchText: String
    
    // Editor state
    @State private var editorTitle: String = ""
    @State private var editorContent: String = ""
    @State private var editorColor: NoteColor = .yellow
    
    var filteredNotes: [Note] {
        if searchText.isEmpty {
            return notesManager.notes
        } else {
            return notesManager.searchNotes(query: searchText)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if isEditing {
                // Inline editor view
                VStack(spacing: 0) {
                    // Editor header
                    HStack {
                        Button(action: {
                            cancelEdit()
                        }) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        
                        Text(noteToEdit != nil ? "Edit Note" : "New Note")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button("Save") {
                            saveNote()
                        }
                        .buttonStyle(.plain)
                        .disabled(editorTitle.isEmpty && editorContent.isEmpty)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    
                    Divider()
                    
                    // Editor content
                    ScrollView {
                        VStack(spacing: 12) {
                            // Title field
                            TextField("Title", text: $editorTitle)
                                .textFieldStyle(.roundedBorder)
                            
                            // Content area
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Content")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                TextEditor(text: $editorContent)
                                    .font(.system(size: 13))
                                    .frame(minHeight: 200)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                    )
                            }
                            
                            // Color picker
                            HStack(spacing: 12) {
                                Text("Color:")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                
                                ForEach(NoteColor.allCases, id: \.self) { color in
                                    Circle()
                                        .fill(color.backgroundColor)
                                        .frame(width: 24, height: 24)
                                        .overlay(
                                            Circle()
                                                .stroke(editorColor == color ? Color.accentColor : Color.clear, lineWidth: 2)
                                        )
                                        .onTapGesture {
                                            editorColor = color
                                        }
                                }
                                
                                Spacer()
                            }
                        }
                        .padding()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Notes list view
                ScrollView {
                    VStack(spacing: 8) {
                        // Add new note button
                        Button(action: {
                            startNewNote()
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("New Note")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.accentColor.opacity(0.1))
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                        
                        // Notes grid - 3 columns for smaller cards
                        if filteredNotes.isEmpty && !searchText.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 30))
                                    .foregroundColor(.secondary)
                                Text("No notes matching \"\(searchText)\"")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, maxHeight: 200)
                            .padding()
                        } else if filteredNotes.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "note.text")
                                    .font(.system(size: 30))
                                    .foregroundColor(.secondary)
                                Text("No notes yet")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                                Text("Click \"New Note\" to get started")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary.opacity(0.7))
                            }
                            .frame(maxWidth: .infinity, maxHeight: 200)
                            .padding()
                        } else {
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 6) {
                                ForEach(filteredNotes) { note in
                                    NoteCard(note: note, notesManager: notesManager)
                                        .onTapGesture {
                                            startEditNote(note)
                                        }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    private func startNewNote() {
        noteToEdit = nil
        editorTitle = ""
        editorContent = ""
        editorColor = .yellow
        isEditing = true
    }
    
    private func startEditNote(_ note: Note) {
        noteToEdit = note
        editorTitle = note.title
        editorContent = note.content
        editorColor = note.color
        isEditing = true
    }
    
    private func cancelEdit() {
        isEditing = false
        noteToEdit = nil
        editorTitle = ""
        editorContent = ""
        editorColor = .yellow
    }
    
    private func saveNote() {
        if let noteToEdit = noteToEdit {
            var updatedNote = noteToEdit
            updatedNote.title = editorTitle.isEmpty ? "Untitled" : editorTitle
            updatedNote.content = editorContent
            updatedNote.color = editorColor
            notesManager.updateNote(updatedNote)
        } else {
            notesManager.addNote(
                title: editorTitle.isEmpty ? "Untitled" : editorTitle,
                content: editorContent,
                color: editorColor
            )
        }
        cancelEdit()
    }
}

struct NoteCard: View {
    let note: Note
    let notesManager: NotesManager
    @State private var isHovered = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 2) {
                Text(note.title)
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(1)
                
                Text(note.content)
                    .font(.system(size: 10))
                    .lineLimit(2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(note.lastModified.formatted(.dateTime.month(.abbreviated).day()))
                    .font(.system(size: 8))
                    .foregroundColor(Color.secondary.opacity(0.7))
            }
            .padding(6)
            .frame(height: 70)
            .frame(maxWidth: .infinity)
            .background(note.color.backgroundColor)
            .cornerRadius(5)
            
            if isHovered {
                Button(action: {
                    notesManager.deleteNote(note)
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                        .background(Color.white.opacity(0.8))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .offset(x: -2, y: 2)
            }
        }
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

#Preview {
    NotesView(searchText: "")
}