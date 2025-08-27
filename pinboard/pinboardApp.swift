import SwiftUI

@main
struct PinboardApp: App {
    @StateObject private var clipboardManager = ClipboardManager()
    
    var body: some Scene {
        MenuBarExtra("Pinboard", systemImage: "paperclip") {
            VStack(alignment: .leading, spacing: 8) {
                if clipboardManager.items.isEmpty {
                    Text("No items yet")
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                        .padding(.vertical, 6)
                } else {
                    ForEach(clipboardManager.items) { item in
                        Button(action: {
                            clipboardManager.copyToClipboard(item)
                        }) {
                            HStack {
                                if let image = item.image {
                                    Image(nsImage: image)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 30, height: 30)
                                        .cornerRadius(4)
                                } else if let text = item.text {
                                    Text(text)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                }
                                Spacer()
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                        }
                        .buttonStyle(.plain)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.gray.opacity(0.15))
                        )
                    }
                }
                
                Divider()
                
                HStack {
                    Button("Clear All") {
                        clipboardManager.clear()
                    }
                    .foregroundColor(.red)
                    
//                    Spacer()
                    
                    Button("Quit") {
                        NSApplication.shared.terminate(nil)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
            }
            .frame(width: 250)
            .padding(.vertical, 6)
        }
    }
}
