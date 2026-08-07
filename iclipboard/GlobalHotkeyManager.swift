//
//  GlobalHotkeyManager.swift
//  ClipboardManager
//
//  Created by Ashraful Mijan on 4/8/26.
//

import Cocoa
import Carbon

class GlobalHotkeyManager {
    static let shared = GlobalHotkeyManager()
    private var hotKeyRef: EventHotKeyRef?
    var onHotkeyTriggered: (() -> Void)?

    func registerGlobalShortcut(keyCode: UInt32, modifiers: UInt32) {
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType(0x4d594150) // Unique 4-character ID tag ('MYAP')
        hotKeyID.id = 1

        let eventSpec = EventTypeSpec(
            eventClass: UInt32(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        var eventHandler: EventHandlerRef?
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { (nextHandler, event, userData) -> OSStatus in
                if let pointer = userData {
                    let manager = Unmanaged<GlobalHotkeyManager>.fromOpaque(pointer).takeUnretainedValue()
                    manager.onHotkeyTriggered?()
                }
                return noErr
            },
            1,
            [eventSpec],
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler
        )

        if status == noErr {
            RegisterEventHotKey(
                keyCode,
                modifiers,
                hotKeyID,
                GetApplicationEventTarget(),
                0,
                &hotKeyRef
            )
        }
    }
}


