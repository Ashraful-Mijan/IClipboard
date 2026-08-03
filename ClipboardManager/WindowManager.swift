//
//  WindowManager.swift
//  ClipboardManager
//
//  Created by Ashraful Mijan on 4/8/26.
//
import SwiftUI
import Cocoa
import Carbon
import Combine

class WindowManager: ObservableObject {
    var panel: NSPanel?
    private let monitor: ClipboardMonitor

    init(monitor: ClipboardMonitor) {
        self.monitor = monitor
        setupInitialSettings()
        setupHotkey()
    }

    private func setupInitialSettings() {
        UserDefaults.standard.register(defaults: [
            "hotkeyCode": UInt32(9), // Keycode 9 represents 'V'
            "hotkeyModifiers": UInt32(optionKey) // Custom system modifier values map
        ])
    }

    func setupHotkey() {
        let keyCode = UInt32(UserDefaults.standard.integer(forKey: "hotkeyCode"))
        let modifiers = UInt32(UserDefaults.standard.integer(forKey: "hotkeyModifiers"))
        
        GlobalHotkeyManager.shared.registerGlobalShortcut(keyCode: keyCode, modifiers: modifiers)
        GlobalHotkeyManager.shared.onHotkeyTriggered = { [weak self] in
            DispatchQueue.main.async { self?.togglePanel() }
        }
    }

    func togglePanel() {
        if let panel = panel, panel.isVisible {
            panel.orderOut(nil)
        } else {
            showPanel()
        }
    }

    private func showPanel() {
        if panel == nil {
            let newPanel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 320, height: 450),
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered, defer: false
            )
            newPanel.level = .statusBar
            newPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            newPanel.backgroundColor = .clear
            newPanel.isMovableByWindowBackground = true
            
            let contentView = ClipboardHistoryView(monitor: monitor, windowManager: self)
            newPanel.contentView = NSHostingView(rootView: contentView)
            self.panel = newPanel
        }

        let mouse = NSEvent.mouseLocation
        panel?.setFrameOrigin(NSPoint(x: mouse.x - 160, y: mouse.y - 225))
        panel?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

