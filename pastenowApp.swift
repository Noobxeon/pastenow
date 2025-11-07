import SwiftUI
import AppKit
import HotKey

@main
struct PasteApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController?
    var hotKey: HotKey?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 隐藏 Dock 图标
        NSApp.setActivationPolicy(.accessory)

        statusBarController = StatusBarController()
        registerGlobalHotkey()
    }

    private func registerGlobalHotkey() {
        hotKey = HotKey(key: .v, modifiers: [.command, .option])
        hotKey?.keyDownHandler = { [weak self] in
            DispatchQueue.main.async {
                self?.statusBarController?.togglePopover(nil)
            }
        }
    }
}

// ClipboardCard 背景修改，完全不透白色背景
extension Color {
    static let clipboardItemBackground = Color(NSColor.white) // 完全不透白色
}
