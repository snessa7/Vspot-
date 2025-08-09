# Technical Specifications - ClipboardAppBeta MenuBar App

## 🏗️ Architecture Overview

### Design Pattern: MVVM (Model-View-ViewModel)
- **Models**: Data structures and business logic
- **Views**: SwiftUI user interface components optimized for menubar display
- **ViewModels**: ObservableObject classes managing state and system integration

### Core Technologies
- **Framework**: SwiftUI + Combine with MenuBarExtra
- **Storage**: Core Data + CloudKit (future) + Keychain for secure data
- **Platform**: macOS 13.0+ (required for MenuBarExtra)
- **Language**: Swift 5.7+
- **Architecture**: Pure menubar utility app (no dock icon)

---

## 📊 Data Models

### ClipboardItem
```swift
struct ClipboardItem: Identifiable, Codable {
    let id: UUID
    let content: String
    let type: PasteboardType
    let timestamp: Date
    let preview: String
    var isFavorite: Bool
    var isEncrypted: Bool = false
}

enum PasteboardType: String, CaseIterable {
    case text, image, url, richText, file
}
```

### Note
```swift
struct Note: Identifiable, Codable {
    let id: UUID
    var title: String
    var content: String
    var color: NoteColor
    var timestamp: Date
    var lastModified: Date
    var tags: [String]
    var isEncrypted: Bool = false
}

enum NoteColor: String, CaseIterable {
    case yellow, blue, green, pink, purple, orange, gray
}
```

### CustomTab
```swift
struct CustomTab: Identifiable, Codable {
    let id: UUID
    var name: String
    var icon: String
    var fields: [CustomField]
    var items: [CustomTabItem]
    var isSecure: Bool = false
}

struct CustomField {
    let id: UUID
    var name: String
    var type: FieldType
    var isRequired: Bool
    var placeholder: String
    var isSecure: Bool = false
}

enum FieldType: String, CaseIterable {
    case text, multilineText, password, date, dropdown, number
}
```

### AppState (MenuBar Specific)
```swift
class AppState: ObservableObject {
    @Published var isMenuBarVisible: Bool = true
    @Published var menuBarStyle: MenuBarStyle = .window
    @Published var currentTab: AppTab = .clipboard
    @Published var isLaunchAtLoginEnabled: Bool = false
    @Published var globalShortcutsEnabled: Bool = true
}

enum MenuBarStyle {
    case window, popover, automatic
}

enum AppTab {
    case clipboard, notes, custom(String)
}
```

---

## 🔧 Services Architecture

### PasteboardService
- Monitors NSPasteboard changes with efficient background processing
- Handles different content types with proper memory management
- Implements secure clipboard monitoring within sandbox constraints
- Manages clipboard history with configurable retention policies

### StorageService
- Core Data persistence with encryption for sensitive data
- Keychain integration for secure password and token storage
- Data migration handling between app versions
- Performance optimization with lazy loading and pagination

### MenuBarService
- Manages MenuBarExtra display and behavior
- Handles system appearance changes (dark/light mode)
- Coordinates with system preferences for menu bar customization
- Implements proper menubar icon state management

### AppStoreService (New)
- App Store receipt validation and verification
- Privacy compliance monitoring and reporting
- Update checking and notification systems
- Analytics collection with user consent management

### PermissionsService (New)
- Manages system permission requests (clipboard access, etc.)
- Handles permission state changes and user responses
- Provides permission status checking and error handling
- Implements proper App Store compliance for system access

### SecurityService (New)
- AES-256 encryption for sensitive clipboard items
- Secure data deletion and memory cleanup
- Privacy-compliant data handling and storage
- Audit logging for security-relevant operations

---

## 🎨 MenuBar UI Components

### MenuBar-Optimized Components
- `MenuBarContent`: Main container optimized for menubar space constraints
- `CompactSearchBar`: Minimal search input with smart autocomplete
- `ClipboardItemRow`: Condensed item display with quick actions
- `NoteCard`: Compact sticky note representation
- `TabSelector`: Efficient tab switching within limited space
- `QuickActions`: Essential actions accessible via shortcuts

### Reusable UI Elements
- `CustomIcon`: "v" branded icon with appearance variants
- `StatusIndicator`: System status and connection displays
- `CompactButton`: Space-efficient action buttons
- `MiniColorPicker`: Streamlined color selection for notes
- `SecureField`: Encrypted text input with visual security indicators

### View Hierarchy (MenuBar Focused)
```
MenuBarExtra("ClipboardApp", systemImage: "v.circle")
├── MenuBarContentView
│   ├── TabNavigationView
│   │   ├── ClipboardTabView
│   │   │   ├── CompactSearchBar
│   │   │   └── ClipboardListView
│   │   ├── NotesTabView
│   │   │   ├── NotesGridView
│   │   │   └── NoteEditorPopover
│   │   └── CustomTabView
│   │       ├── TabConfigView
│   │       └── DynamicFieldsView
│   └── QuickActionsFooter
```

---

## ⚡ Performance Specifications

### MenuBar App Performance Requirements
- **Background Memory Usage**: < 50MB during normal operation
- **Clipboard Monitoring**: < 10ms detection latency
- **Menu Display**: < 100ms from click to content display
- **Search Results**: < 50ms for 1000+ items
- **App Launch**: < 1 second to menubar ready state
- **Battery Impact**: Minimal drain during background monitoring

### Storage & Capacity Limits
- **Maximum clipboard items**: 2000 (configurable, with automatic cleanup)
- **Database size**: < 200MB recommended for optimal performance
- **Note content**: < 5MB per note (enforced with compression)
- **Custom tab items**: < 500KB per item
- **Total app bundle**: < 30MB for App Store compliance

### Background Operation Efficiency
- **CPU Usage**: < 1% during idle monitoring
- **Network Usage**: Zero (local-only operation)
- **Disk I/O**: Batched writes every 30 seconds maximum
- **System Integration**: Efficient NSPasteboard polling with adaptive intervals

---

## 🔒 Security & Privacy (App Store Compliant)

### Data Protection & Encryption
- **AES-256 encryption** for sensitive clipboard items and notes
- **Keychain integration** for secure password storage in custom tabs
- **Local storage only** with no cloud transmission by default
- **Secure deletion** with memory zeroing for sensitive data
- **App Sandbox** fully configured with minimal required entitlements

### Privacy Compliance Framework
- **No data transmission** outside app without explicit user consent
- **Privacy policy** integrated and accessible from app menu
- **Clipboard access permission** properly requested with usage descriptions
- **User-controlled data retention** with configurable cleanup policies
- **No tracking or analytics** without explicit user opt-in

### App Store Security Requirements
- **Code signing** with valid Developer ID certificate
- **Notarization** for distribution outside App Store
- **Entitlements minimization** using only required system access
- **Secure coding practices** with input validation and sanitization
- **Runtime protection** against code injection and tampering

### System Integration Security
- **Clipboard monitoring** within sandbox constraints only
- **No file system access** beyond app container
- **No network access** unless explicitly enabled for future features
- **Proper permission handling** for all system resources
- **Audit logging** for security-relevant operations (local only)

---

## 🧪 Testing Strategy

### Unit Tests
- Model validation tests
- Service layer tests
- Business logic verification
- Error handling validation

### Integration Tests
- Clipboard monitoring accuracy
- Search functionality
- Data persistence
- Cross-tab interactions

### Performance Tests
- Memory usage monitoring
- Search performance benchmarks
- UI responsiveness testing
- Large dataset handling

---

## 📦 Build Configuration & App Store Compliance

### Debug Configuration
- **Comprehensive logging** for development and debugging
- **Debug UI overlays** for performance monitoring
- **Memory leak detection** with Instruments integration
- **Sandbox testing** environment setup

### Release Configuration
- **Optimized builds** with compiler optimizations enabled
- **Minimal logging** for production environment
- **Code signing** with production certificates
- **Notarization** ready for distribution

### App Store Configuration
- **App Sandbox** enabled with required entitlements:
  - `com.apple.security.app-sandbox`: true
  - `com.apple.security.files.user-selected.read-only`: false
  - `com.apple.security.device.clipboard`: true (if needed)
- **Hardened Runtime** enabled with necessary exceptions
- **App Transport Security** configured (no network by default)
- **Privacy usage descriptions** for all system access:
  - `NSClipboardUsageDescription`: "Access clipboard to manage your copy history"
  - `NSSystemAdministrationUsageDescription`: "Optional launch at login functionality"

### MenuBar App Specific Configuration
- **Application Category**: Productivity Utilities
- **LSUIElement**: true (no dock icon)
- **LSBackgroundOnly**: false (user can interact)
- **NSMenuBarExtra**: configured for proper menubar integration
- **Launch Services**: configured for menubar-only operation

### Version Management & Updates
- **Semantic versioning** (major.minor.patch)
- **Build number** auto-incrementing
- **App Store Connect** integration for update delivery
- **Migration scripts** for data model changes
- **Rollback capability** for critical issues

This configuration ensures full App Store compliance while maintaining the utility app nature of the menubar clipboard manager.

