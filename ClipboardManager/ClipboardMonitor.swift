//
//  ClipboardMonitor.swift
//  ClipboardManager
//
//  Created by Ashraful Mijan on 4/8/26.
//

import AppKit
import SwiftUI
import Combine

struct ClipboardItem: Identifiable, Equatable {
    let id = UUID()
    let timestamp: Date
    let text: String?
    let image: NSImage?
    let fileURLs: [URL]?
    
    var displayString: String {
        if let text = text { return text }
        if let urls = fileURLs { return urls.map { $0.lastPathComponent }.joined(separator: ", ") }
        if image != nil { return "[Copied Image Asset]" }
        return "Unknown Content Type"
    }
}

class ClipboardMonitor: ObservableObject {
    @Published var history: [ClipboardItem] = []
    private let pasteboard = NSPasteboard.general
    private var lastChangeCount = NSPasteboard.general.changeCount
    private var timer: Timer?

    init() {
        startMonitoring()
    }

    func startMonitoring() {
        // High frequency loop to securely grab text/file data without impacting system speed
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkPasteboard()
        }
    }

    private func checkPasteboard() {
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount

        var text: String?
        var image: NSImage?
        var fileURLs: [URL]?

        if let types = pasteboard.types, types.contains(.fileURL),
           let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] {
            fileURLs = urls
        }
        else if pasteboard.canReadObject(forClasses: [NSImage.self], options: nil),
                let img = pasteboard.readObjects(forClasses: [NSImage.self], options: nil)?.first as? NSImage {
            image = img
        }
        else if let str = pasteboard.string(forType: .string) {
            text = str
        }

        let newItem = ClipboardItem(timestamp: Date(), text: text, image: image, fileURLs: fileURLs)
        
        DispatchQueue.main.async {
            self.history.insert(newItem, at: 0)
            if self.history.count > 50 { self.history.removeLast() }
        }
    }
    
    func pasteItem(_ item: ClipboardItem) {
        pasteboard.clearContents()
        if let text = item.text {
            pasteboard.setString(text, forType: .string)
        } else if let image = item.image {
            pasteboard.writeObjects([image])
        } else if let urls = item.fileURLs {
            pasteboard.writeObjects(urls as [NSURL])
        }
    }
}


