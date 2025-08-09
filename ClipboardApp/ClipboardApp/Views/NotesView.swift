//
//  NotesView.swift
//  ClipboardApp
//
//  Sticky notes view
//

import SwiftUI

struct NotesView: View {
    @StateObject private var notesManager = NotesManager()
    @State private var showingNewNote = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                // Add new note button
                Button(action: {
                    showingNewNote = true
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
                
                // Notes grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(notesManager.notes) { note in
                        NoteCard(note: note)
                    }
                }
            }
            .padding()
        }
        .sheet(isPresented: $showingNewNote) {
            NoteEditorView(note: .constant(Note(
                title: "",
                content: "",
                color: .yellow
            )))
        }
    }
}

struct NoteCard: View {
    let note: Note
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(note.title)
                .font(.system(size: 12, weight: .semibold))
                .lineLimit(1)
            
            Text(note.content)
                .font(.system(size: 11))
                .lineLimit(3)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(note.lastModified.formatted())
                .font(.system(size: 9))
                .foregroundColor(.tertiary)
        }
        .padding(8)
        .frame(height: 100)
        .frame(maxWidth: .infinity)
        .background(note.color.backgroundColor)
        .cornerRadius(6)
    }
}

struct NoteEditorView: View {
    @Binding var note: Note
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            HStack {
                Text("Edit Note")
                    .font(.headline)
                Spacer()
                Button("Done") {
                    dismiss()
                }
            }
            .padding()
            
            TextField("Title", text: $note.title)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
            
            TextEditor(text: $note.content)
                .padding(.horizontal)
            
            HStack {
                ForEach(NoteColor.allCases, id: \.self) { color in
                    Circle()
                        .fill(color.backgroundColor)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle()
                                .stroke(note.color == color ? Color.accentColor : Color.clear, lineWidth: 2)
                        )
                        .onTapGesture {
                            note.color = color
                        }
                }
            }
            .padding()
        }
        .frame(width: 400, height: 300)
    }
}

#Preview {
    NotesView()
}