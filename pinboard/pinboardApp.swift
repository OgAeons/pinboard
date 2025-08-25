import SwiftUI
import AppKit

// Model for clipboard items
struct ClipboardItem: Identifiable, Equatable {
    let id = UUID()
    let content: String
    
    static func == (lhs: ClipboardItem, rhs: ClipboardItem) -> Bool {
        return lhs.content == rhs.content
    }
}

// Clipboard manager to monitor changes
class ClipboardManager: ObservableObject {
    @Published var items: [ClipboardItem] = []
    private var changeCount: Int = NSPasteboard.general.changeCount
    private var timer: Timer?
    private var lastCopiedByApp: String? = nil
    
    init() {
        startMonitoring()
    }
    
    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            let pb = NSPasteboard.general
            if pb.changeCount != self.changeCount {
                self.changeCount = pb.changeCount
                if let copiedText = pb.string(forType: .string) {
                    // Avoid re-adding if it was copied by our app
                    if copiedText != self.lastCopiedByApp {
                        DispatchQueue.main.async {
                            // Always move it to the top instead of duplicating
                            if let index = self.items.firstIndex(where: { $0.content == copiedText }) {
                                let existingItem = self.items.remove(at: index)
                                self.items.insert(existingItem, at: 0)
                            } else {
                                self.items.insert(ClipboardItem(content: copiedText), at: 0)
                            }
                            // Keep only the last 50 items
                            if self.items.count > 50 {
                                self.items.removeLast()
                            }
                        }
                    }
                }
            }
        }
    }
    
    func copyToClipboard(_ text: String) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)
        self.lastCopiedByApp = text
    }
}

// Main app entry
@main
struct PinboardApp: App {
    @StateObject private var clipboardManager = ClipboardManager()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings { EmptyView() } // Hide default settings window
    }
}

// AppDelegate for menu bar control
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        let clipboardManager = ClipboardManager()
        let contentView = ContentView().environmentObject(clipboardManager)
        
        popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 400)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: contentView)
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "Clipboard")
            button.action = #selector(togglePopover(_:))
        }
    }
    
    @objc func togglePopover(_ sender: AnyObject?) {
        if let button = statusItem?.button {
            if popover.isShown {
                popover.performClose(sender)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }
}

// SwiftUI view for history display
struct ContentView: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("📋 Pinboard")
                .font(.headline)
                .padding([.top, .leading, .trailing])
            Divider()
            List(clipboardManager.items) { item in
                HStack {
                    Text(item.content)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .onTapGesture {
                            clipboardManager.copyToClipboard(item.content)
                        }
                    Spacer()
                    Button("Copy") {
                        clipboardManager.copyToClipboard(item.content)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
            }
        }
        .frame(minWidth: 300, minHeight: 400)
    }
}
