import AppKit
import SwiftUI

struct ClipboardItem: Identifiable, Equatable {
    let id = UUID()
    let text: String?
    let image: NSImage?
    
    static func == (lhs: ClipboardItem, rhs: ClipboardItem) -> Bool {
        return lhs.text == rhs.text &&
               lhs.image?.tiffRepresentation == rhs.image?.tiffRepresentation
    }
}

class ClipboardManager: ObservableObject {
    @Published var items: [ClipboardItem] = []
    private var changeCount: Int = NSPasteboard.general.changeCount
    private var timer: Timer?
    
    init() {
        startMonitoring()
    }
    
    private func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            let pb = NSPasteboard.general
            if pb.changeCount != self.changeCount {
                self.changeCount = pb.changeCount
                self.readClipboard()
            }
        }
    }
    
    private func readClipboard() {
        let pb = NSPasteboard.general
        
        if let types = pb.types {
            if types.contains(.string), let str = pb.string(forType: .string) {
                let newItem = ClipboardItem(text: str, image: nil)
                if !items.contains(newItem) {
                    items.insert(newItem, at: 0)
                }
            } else if types.contains(.tiff), let data = pb.data(forType: .tiff), let img = NSImage(data: data) {
                let newItem = ClipboardItem(text: nil, image: img)
                if !items.contains(newItem) {
                    items.insert(newItem, at: 0)
                }
            }
        }
    }
    
    func copyToClipboard(_ item: ClipboardItem) {
        let pb = NSPasteboard.general
        pb.clearContents()
        
        if let text = item.text {
            pb.setString(text, forType: .string)
        } else if let image = item.image {
            if let data = image.tiffRepresentation {
                pb.setData(data, forType: .tiff)
            }
        }
    }
    
    func clear() {
        items.removeAll()
    }
}

