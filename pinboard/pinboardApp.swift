import SwiftUI
import AppKit

// model for clipboard items
struct ClipboardItem: Identifiable {
    let id = UUID()
    let content: String
}

// clipboard manager to observe changes
class ClipboardManager: ObservableObject {
    @Published var items: [ClipboardItem] = []
    private var changeCount: Int = NSPasteboard.general.changeCount
    private var timer: Timer?
    
    init() {
        startMonitoring()
    }
    
    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            let pb = NSPasteboard.general
            if pb.changeCount != self.changeCount {
                self.changeCount = pb.changeCount
                if let copiedText = pb.string(forType: .string) {
                    DispatchQueue.main.async {
                        self.items.insert(ClipboardItem(content: copiedText), at: 0)
                        // keep only the last 50 items
                        if self.items.count > 50 {
                            self.items.removeLast()
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
    }
}


@main
struct PinboardApp: App {
    @StateObject private var clipboardManager = ClipboardManager()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // hide default settings window
        Settings { EmptyView() }
    }
}

// AppDelegate for menu bar control
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        let contentView = ContentView().environmentObject(ClipboardManager())
        
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
                Button(action: {
                    clipboardManager.copyToClipboard(item.content)
                }) {
                    Text(item.content)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .frame(minWidth: 300, minHeight: 400)
    }
}
