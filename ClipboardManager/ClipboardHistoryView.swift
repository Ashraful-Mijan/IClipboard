//
//  ClipboardHistoryView.swift
//  ClipboardManager
//
//  Created by Ashraful Mijan on 4/8/26.
//
import SwiftUI
import Carbon

struct ClipboardHistoryView: View {
    @ObservedObject var monitor: ClipboardMonitor
    var windowManager: WindowManager
    
    @StateObject private var launchManager = LaunchAtLoginManager()
    
    @AppStorage("hotkeyCode") private var storedKeyCode: Int = 9
    @AppStorage("hotkeyModifiers") private var storedModifiers: Int = Int(optionKey)

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Clipboard")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                
                Menu {
                    // --- Added Launch At Login Toggle Link ---
                    Toggle("Launch at Login", isOn: $launchManager.isEnabled)
                    
                    Divider()
                    
                    Button("Option + V (Default)") { updateHotkey(code: 9, mod: optionKey) }
                    Button("Option + C") { updateHotkey(code: 8, mod: optionKey) }
                    Button("Option + Space") { updateHotkey(code: 49, mod: optionKey) }
                    Button("Control + V") { updateHotkey(code: 9, mod: controlKey) }
                } label: {
                    Text(currentHotkeyLabel)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.primary.opacity(0.1))
                        .cornerRadius(4)
                }
                
                Button(action: { monitor.history.removeAll() }) {
                    Image(systemName: "trash")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Clear History")
            }
            .padding()
            .background(VisualEffectView(material: .headerView, blendingMode: .withinWindow))

            Divider()

            ScrollView {
                LazyVStack(spacing: 4) {
                    if monitor.history.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "clipboard")
                                .font(.system(size: 24))
                                .foregroundColor(.secondary.opacity(0.5))
                            Text("No items copied yet")
                                .font(.callout)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 60)
                    } else {
                        ForEach(monitor.history) { item in
                            ClipboardRow(item: item) {
                                monitor.pasteItem(item)
                                windowManager.togglePanel()
                            }
                        }
                    }
                }
                .padding(8)
            }
        }
        .frame(width: 320, height: 450)
        .background(VisualEffectView(material: .hudWindow, blendingMode: .withinWindow))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    private var currentHotkeyLabel: String {
        let modStr = storedModifiers == Int(controlKey) ? "⌃" : "⌥"
        var keyStr = "V"
        if storedKeyCode == 8 { keyStr = "C" }
        if storedKeyCode == 49 { keyStr = "Space" }
        return "\(modStr)\(keyStr)"
    }

    private func updateHotkey(code: Int, mod: Int) {
        storedKeyCode = code
        storedModifiers = mod
        windowManager.setupHotkey()
    }
}

struct ClipboardRow: View {
    let item: ClipboardItem
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                typeIcon
                    .frame(width: 32, height: 32)
                    .background(Color.primary.opacity(0.05))
                    .cornerRadius(6)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.displayString)
                        .font(.body)
                        .lineLimit(2)
                        .foregroundColor(.primary)
                    Text(item.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(8)
            .contentShape(Rectangle())
            .background(isHovered ? Color.primary.opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in isHovered = hovering }
    }

    @ViewBuilder
    private var typeIcon: some View {
        if item.image != nil {
            Image(systemName: "photo").foregroundColor(.purple)
        } else if item.fileURLs != nil {
            Image(systemName: "doc.on.doc").foregroundColor(.blue)
        } else {
            Image(systemName: "doc.text").foregroundColor(.green)
        }
    }
}

struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

