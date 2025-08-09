//
//  PasteboardService.swift
//  ClipboardApp
//
//  Service for monitoring the system pasteboard
//

import Foundation
import AppKit

class PasteboardService {
    private var timer: Timer?
    private var lastChangeCount: Int
    private var onNewContent: ((String, PasteboardType) -> Void)?
    
    init() {
        self.lastChangeCount = NSPasteboard.general.changeCount
    }
    
    func startMonitoring(onNewContent: @escaping (String, PasteboardType) -> Void) {
        self.onNewContent = onNewContent
        
        // Check pasteboard every 0.5 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkPasteboard()
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    private func checkPasteboard() {
        let pasteboard = NSPasteboard.general
        let currentChangeCount = pasteboard.changeCount
        
        // Check if pasteboard has changed
        if currentChangeCount != lastChangeCount {
            lastChangeCount = currentChangeCount
            
            // Get content from pasteboard
            if let string = pasteboard.string(forType: .string) {
                let type = detectType(for: string)
                onNewContent?(string, type)
            } else if let url = pasteboard.string(forType: .URL) {
                onNewContent?(url, .url)
            } else if pasteboard.canReadItem(withDataConformingToTypes: ["public.image"]) {
                // For now, just indicate an image was copied
                onNewContent?("[Image]", .image)
            }
        }
    }
    
    private func detectType(for string: String) -> PasteboardType {
        // Simple type detection
        if string.hasPrefix("http://") || string.hasPrefix("https://") {
            return .url
        } else if string.contains("\n") || string.count > 200 {
            return .richText
        } else {
            return .text
        }
    }
    
    deinit {
        stopMonitoring()
    }
}