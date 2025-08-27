import SwiftUI

@main
struct PinboardApp: App {
    @StateObject private var clipboardManager = ClipboardManager()
    
    var body: some Scene {
        MenuBarExtra("Pinboard", systemImage: "paperclip") {
            PinboardView()
                .environmentObject(clipboardManager)
        }
        // keeps the panel open while interacting
        .menuBarExtraStyle(.window)
    }
}

struct PinboardView: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    @State private var expanded: Set<UUID> = []
    
    var body: some View {
        VStack(spacing: 8) {
            if clipboardManager.items.isEmpty {
                Text("No items yet")
                    .foregroundColor(.secondary)
                    .padding(.vertical, 12)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(clipboardManager.items) { item in
                            itemRow(item)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 4)
                    .padding(.bottom, 6)
                }
                .frame(maxHeight: 360)
            }
            
            Divider()
            
            HStack {
                Button("Clear All") { clipboardManager.clear() }
                    .buttonStyle(.borderless)
                    .foregroundColor(.red)
                    .focusable(false)
                Spacer()
                Button("Quit") { NSApplication.shared.terminate(nil) }
                    .buttonStyle(.borderless)
                    .focusable(false)
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 8)
        }
        .frame(width: 300)
        .padding(.top, 8)
    }
    
    @ViewBuilder
    private func itemRow(_ item: ClipboardItem) -> some View {
        let isExpanded = expanded.contains(item.id)
        
        DisclosureGroup(
            isExpanded: Binding(
                get: { isExpanded },
                set: { newValue in
                    if newValue {
                        expanded.insert(item.id)
                    } else {
                        expanded.remove(item.id)
                    }
                }
            )
        ) {
            if let text = item.text {
                VStack(alignment: .leading, spacing: 6) {
                    ScrollView(.vertical) {
                        Text(text)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.primary)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                    }
                    .frame(height: 120) // limit expanded height
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.1)))
                    
                    HStack(spacing: 8) {
                        Button {
                            clipboardManager.copyToClipboard(item)
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                        .buttonStyle(.borderless)
                        .focusable(false)
                        
                        Spacer()
                        
                        Button {
                            withAnimation {
                                _ = expanded.remove(item.id) // ignore return
                            }
                        } label: {
                            Label("Collapse", systemImage: "chevron.up")
                        }
                        .buttonStyle(.borderless)
                        .focusable(false)
                    }
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                }
                .padding(.top, 4)
            } else if let image = item.image {
                VStack(alignment: .leading, spacing: 6) {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 180)
                        .cornerRadius(6)
                    HStack {
                        Button {
                            clipboardManager.copyToClipboard(item)
                        } label: {
                            Label("Copy Image", systemImage: "doc.on.doc")
                        }
                        .buttonStyle(.borderless)
                        .focusable(false)
                        
                        Spacer()
                        
                        Button {
                            withAnimation {
                                _ = expanded.remove(item.id) // same fix
                            }
                        } label: {
                            Label("Collapse", systemImage: "chevron.up")
                        }
                        .buttonStyle(.borderless)
                        .focusable(false)
                    }
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                }
                .padding(.top, 4)
            }
        } label: {
            HStack(alignment: .center, spacing: 8) {
                if let image = item.image {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 28, height: 28)
                        .clipped()
                        .cornerRadius(4)
                } else if let text = item.text {
                    Text(text)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.primary)
                }
                Spacer()
                Button {
                    clipboardManager.copyToClipboard(item)
                } label: {
                    Image(systemName: "doc.on.doc")
                        .imageScale(.small)
                }
                .buttonStyle(.borderless)
                .focusable(false)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.15)))
        }
    }
}


