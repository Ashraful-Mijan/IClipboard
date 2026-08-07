//
//  LaunchAtLoginManager.swift
//  ClipboardManager
//
//  Created by Ashraful Mijan on 4/8/26.
//
import Foundation
import ServiceManagement
import Combine

class LaunchAtLoginManager: ObservableObject {
    // Modern Apple background service controller referencing main app execution target
    private let appService = SMAppService.mainApp
    
    @Published var isEnabled: Bool {
        didSet {
            toggleLaunchAtLogin(enabled: isEnabled)
        }
    }
    
    init() {
        // Read current registration state directly from macOS system settings
        self.isEnabled = (appService.status == .enabled)
    }
    
    private func toggleLaunchAtLogin(enabled: Bool) {
        do {
            if enabled {
                if appService.status != .enabled {
                    try appService.register()
                }
            } else {
                if appService.status == .enabled {
                    try appService.unregister()
                }
            }
        } catch {
            print("Failed to change launch at login configuration status: \(error.localizedDescription)")
            // Revert state if registration fails
            DispatchQueue.main.async {
                self.isEnabled = (self.appService.status == .enabled)
            }
        }
    }
}

