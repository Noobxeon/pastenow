import SwiftUI
import AppKit
import Combine

struct ClipboardItem: Identifiable, Codable, Equatable {
    let id: UUID
    var content: String
    let timestamp: Date
    var imageData: Data?
    var isPinned: Bool

    init(id: UUID = UUID(), content: String, timestamp: Date = Date(), imageData: Data? = nil, isPinned: Bool = false) {
        self.id = id
        self.content = content
        self.timestamp = timestamp
        self.imageData = imageData
        self.isPinned = isPinned
    }

    var image: NSImage? {
        guard let data = imageData else { return nil }
        return NSImage(data: data)
    }

    static func == (lhs: ClipboardItem, rhs: ClipboardItem) -> Bool {
        return lhs.content == rhs.content && lhs.imageData == rhs.imageData
    }
}

class ClipboardViewModel: ObservableObject {
    @Published var items: [ClipboardItem] = []
    @Published var searchText: String = ""

    private var lastChangeCount = NSPasteboard.general.changeCount
    private var timer: Timer?

    init() {
        loadClipboardHistory()
        startMonitoringClipboard()
    }

    deinit {
        timer?.invalidate()
    }

    func startMonitoringClipboard() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }

    func checkClipboard() {
        let pasteboard = NSPasteboard.general
        if pasteboard.changeCount != lastChangeCount {
            lastChangeCount = pasteboard.changeCount
            var newItem: ClipboardItem?

            if let image = NSImage(pasteboard: pasteboard) {
                let imageData = image.tiffRepresentation
                newItem = ClipboardItem(content: "[图片]", timestamp: Date(), imageData: imageData)
            } else if let text = pasteboard.string(forType: .string) {
                newItem = ClipboardItem(content: text, timestamp: Date(), imageData: nil)
            }

            if let item = newItem, !items.contains(item) {
                DispatchQueue.main.async {
                    self.items.insert(item, at: 0)
                    self.saveClipboardHistory()
                }
            }
        }
    }

    func copy(_ item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        if let image = item.image {
            pasteboard.writeObjects([image])
        } else {
            pasteboard.setString(item.content, forType: .string)
        }
    }

    func togglePin(_ item: ClipboardItem) {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[idx].isPinned.toggle()
        sortItemsWithPinnedFirst()
        saveClipboardHistory()
    }

    private func sortItemsWithPinnedFirst() {
        items.sort { (a, b) -> Bool in
            if a.isPinned != b.isPinned { return a.isPinned && !b.isPinned }
            return a.timestamp > b.timestamp
        }
    }

    func delete(_ item: ClipboardItem) {
        if item.isPinned {
            let alert = NSAlert()
            alert.messageText = "确认删除已固定的剪贴项？"
            alert.informativeText = "此项已被固定，删除后将无法恢复。确认要删除吗？"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "删除")
            alert.addButton(withTitle: "取消")

            let response = alert.runModal()
            if response != .alertFirstButtonReturn {
                return
            }
        }

        items.removeAll { $0.id == item.id }
        saveClipboardHistory()
    }

    func clearAll() {
        let alert = NSAlert()
        alert.messageText = "确认清空剪贴板历史？"
        alert.informativeText = "这会删除所有剪贴记录，包括已固定的项。"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "清空")
        alert.addButton(withTitle: "取消")

        let response = alert.runModal()
        if response != .alertFirstButtonReturn {
            return
        }

        items.removeAll()
        saveClipboardHistory()
    }

    func saveClipboardHistory() {
        sortItemsWithPinnedFirst()
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: "clipboardHistory")
        }
    }

    func loadClipboardHistory() {
        if let data = UserDefaults.standard.data(forKey: "clipboardHistory"),
           let decoded = try? JSONDecoder().decode([ClipboardItem].self, from: data) {
            items = decoded
            sortItemsWithPinnedFirst()
        }
    }

    var filteredItems: [ClipboardItem] {
        let base: [ClipboardItem]
        if searchText.isEmpty {
            base = items
        } else {
            base = items.filter { $0.content.localizedCaseInsensitiveContains(searchText) }
        }

        return base.sorted { (a, b) -> Bool in
            if a.isPinned != b.isPinned { return a.isPinned && !b.isPinned }
            return a.timestamp > b.timestamp
        }
    }
}
