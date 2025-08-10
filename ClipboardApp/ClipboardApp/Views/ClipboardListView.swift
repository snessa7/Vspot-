//
//  ClipboardListView.swift
//  ClipboardApp
//
//  Display list of clipboard items
//

import SwiftUI

struct ClipboardListView: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    let searchText: String
    
    var filteredItems: [ClipboardItem] {
        if searchText.isEmpty {
            return clipboardManager.items
        } else {
            return clipboardManager.items.filter {
                $0.content.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 2) {
                if filteredItems.isEmpty {
                    EmptyStateView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.vertical, 50)
                } else {
                    ForEach(filteredItems) { item in
                        ClipboardItemRow(item: item)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
}

struct ClipboardItemRow: View {
    let item: ClipboardItem
    @EnvironmentObject var clipboardManager: ClipboardManager
    @State private var isHovered = false
    
    var body: some View {
        HStack {
            // Type icon
            Image(systemName: item.type.icon)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .frame(width: 20)
            
            // Content preview
            VStack(alignment: .leading, spacing: 2) {
                Text(item.preview)
                    .font(.system(size: 13))
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(item.timestamp.formatted())
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            
            // Actions
            if isHovered {
                HStack(spacing: 4) {
                    Button(action: {
                        clipboardManager.copyToPasteboard(item)
                    }) {
                        Image(systemName: "doc.on.clipboard")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        clipboardManager.toggleFavorite(item)
                    }) {
                        Image(systemName: item.isFavorite ? "star.fill" : "star")
                            .font(.system(size: 11))
                            .foregroundColor(item.isFavorite ? .yellow : .secondary)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        clipboardManager.deleteItem(item)
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(isHovered ? Color.gray.opacity(0.1) : Color.clear)
        .cornerRadius(4)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "clipboard")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("No clipboard items")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            Text("Copy something to get started")
                .font(.system(size: 12))
                .foregroundColor(Color.secondary.opacity(0.7))
        }
    }
}

#Preview {
    ClipboardListView(searchText: "")
        .environmentObject(ClipboardManager())
}