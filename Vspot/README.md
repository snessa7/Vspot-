# Vspot - Xcode Project

## Opening the Project

1. **Option 1: Open vspot.xcodeproj** (Recommended)
   - Double-click `vspot.xcodeproj` in Finder, or
   - Open Xcode and select File → Open → Navigate to `vspot.xcodeproj`
   - This will open the project

2. **Option 2: Create Xcode Project**
   - Open Xcode
   - File → New → Project
   - Choose macOS → App
   - Product Name: Vspot
   - Interface: SwiftUI
   - Language: Swift
   - Then copy the source files into the new project

## Project Structure

```
VspotApp/
├── VspotApp.swift              # Main app entry with MenuBarExtra
├── Models/                     # Data models
│   ├── AppState.swift
│   ├── ClipboardItem.swift
│   ├── CustomTab.swift
│   └── Note.swift
├── Views/                      # SwiftUI views
│   ├── MenuBarContentView.swift
│   ├── ClipboardListView.swift
│   ├── NotesView.swift
│   └── CustomTabView.swift
├── ViewModels/                 # Business logic
│   ├── ClipboardManager.swift
│   └── NotesManager.swift
├── Services/                   # System services
│   └── PasteboardService.swift
└── Resources/                  # App resources
    ├── Info.plist
    └── Vspot.entitlements
```

## Building and Running

1. Open the project in Xcode
2. Select "My Mac" as the build target
3. Press ⌘+R to build and run
4. The app will appear in your menu bar with a "v" icon

## Requirements

- Xcode 14.0 or later
- macOS 13.0 or later (for MenuBarExtra support)
- Swift 5.7 or later

## Notes

- The app runs as a menubar-only application (no dock icon)
- All data is stored locally for privacy
- Configured for App Store distribution with proper sandboxing