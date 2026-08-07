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

class WindowManager: NSObject, ObservableObject, NSWindowDelegate {
    var panel: NSPanel?
    private let monitor: ClipboardMonitor
    
    private var initialMouseLocation: NSPoint = .zero
    private var initialPanelOrigin: NSPoint = .zero
    private var isDragging = false

    init(monitor: ClipboardMonitor) {
        self.monitor = monitor
        super.init()
        setupInitialSettings()
        setupHotkey()
    }

    private func setupInitialSettings() {
        UserDefaults.standard.register(defaults: [
            "hotkeyCode": UInt32(9),
            "hotkeyModifiers": UInt32(optionKey)
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
                styleMask: [.borderless, .nonactivatingPanel, .hudWindow],
                backing: .buffered, defer: false
            )
            newPanel.level = .statusBar
            newPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            newPanel.backgroundColor = .clear
            
            newPanel.isMovableByWindowBackground = false
            newPanel.delegate = self
            
            let contentView = ClipboardHistoryView(monitor: monitor, windowManager: self)
            newPanel.contentView = NSHostingView(rootView: contentView)
            self.panel = newPanel
            
            setupCustomDragMonitor(for: newPanel)
        }

        if let currentScreen = NSScreen.main {
            let screenFrame = currentScreen.visibleFrame
            let panelWidth: CGFloat = 320
            let panelHeight: CGFloat = 450
            
            let centerX = screenFrame.origin.x + (screenFrame.width - panelWidth) / 2
            let spotlightY = screenFrame.origin.y + (screenFrame.height - panelHeight) * 0.65
            
            panel?.setFrameOrigin(NSPoint(x: centerX, y: spotlightY))
        }

        panel?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func setupCustomDragMonitor(for panel: NSPanel) {
        NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .leftMouseDragged, .leftMouseUp]) { [weak self] event in
            guard let self = self, self.panel?.isVisible == true else { return event }
            
            switch event.type {
            case .leftMouseDown:
                let clickInWindow = event.locationInWindow
                
                if clickInWindow.y > 400 {
                    
                    if clickInWindow.x > 180 {
                        return event
                    }
                    
                    self.isDragging = true
                    self.initialMouseLocation = NSEvent.mouseLocation
                    self.initialPanelOrigin = panel.frame.origin
                    return nil
                }
                
            case .leftMouseDragged:
                if self.isDragging {
                    let currentMouseLocation = NSEvent.mouseLocation
                    let deltaX = currentMouseLocation.x - self.initialMouseLocation.x
                    let deltaY = currentMouseLocation.y - self.initialMouseLocation.y
                    
                    var newOrigin = NSPoint(
                        x: self.initialPanelOrigin.x + deltaX,
                        y: self.initialPanelOrigin.y + deltaY
                    )
                    
                    if let targetScreen = panel.screen {
                        let allowedBounds = targetScreen.visibleFrame
                        let panelFrame = panel.frame
                        
                        newOrigin.x = max(allowedBounds.origin.x, min(newOrigin.x, allowedBounds.origin.x + allowedBounds.width - panelFrame.width))
                        newOrigin.y = max(allowedBounds.origin.y, min(newOrigin.y, allowedBounds.origin.y + allowedBounds.height - panelFrame.height))
                    }
                    
                    panel.setFrameOrigin(newOrigin)
                    return nil
                }
                
            case .leftMouseUp:
                if self.isDragging {
                    self.isDragging = false
                    return nil
                }
                self.isDragging = false
                
            default:
                break
            }
            return event
        }
    }
}





