//
//  ClipboardManagerApp.swift
//  ClipboardManager
//
//  Created by Ashraful Mijan on 3/8/26.
//

import SwiftUI
import Cocoa

@main
struct ClipboardManagerApp: App {
    // Hooks up our custom App Delegate lifecycle control center
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView() // Structural placement so SwiftUI compiles without generating a base window
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var monitor: ClipboardMonitor!
    var windowManager: WindowManager!
    var launchManager: LaunchAtLoginManager!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize core mechanics immediately on launch
        self.monitor = ClipboardMonitor()
        self.windowManager = WindowManager(monitor: monitor)
        self.launchManager = LaunchAtLoginManager()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false // Prevents the background process from dying if a UI window closes
    }
}
