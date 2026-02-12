#if os(macOS)
import SwiftUI
import AppKit

struct AboutView: View {
    var body: some View {
        VStack(spacing: 18) {
            
            LiveAppIconView()
            
            VStack(spacing: 4) {
                Text("Mapped Drive")
                    .font(.title.weight(.semibold))
                Text("Access SMB Shares from Your Mac")
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                AboutRow(label: "Version", value: appVersion)
                AboutRow(label: "Build", value: appBuild)
                AboutRow(label: "Developer", value: "George Babichev")
                AboutRow(label: "Copyright", value: "© \(Calendar.current.component(.year, from: Date())) George Babichev")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            if let devPhoto = NSImage(named: "gbabichev") {
                HStack(spacing: 12) {
                    Image(nsImage: devPhoto)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 64, height: 64)
                        .offset(y: 6)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.secondary.opacity(0.2), lineWidth: 1))
                    VStack(alignment: .leading, spacing: 4) {
                        Text("George Babichev")
                            .font(.headline)
                        Link("georgebabichev.com", destination: URL(string: "https://georgebabichev.com")!)
                            .font(.subheadline)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(24)
        .frame(width: 380)
        .background(AboutWindowConfigurator())
    }
    
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "–"
    }
    
    private var appBuild: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "–"
    }
}

private struct AboutRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }
}

struct LiveAppIconView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var refreshID = UUID()
    
    var body: some View {
        Image(nsImage: NSApp.applicationIconImage)
            .resizable()
            .scaledToFit()
            .id(refreshID) // force SwiftUI to re-evaluate the image
            .frame(width: 72, height: 72)
            .onChange(of: colorScheme) { _,_ in
                // Let AppKit update its icon, then refresh the view
                DispatchQueue.main.async {
                    refreshID = UUID()
                }
            }
    }
}

private struct AboutWindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            configure(window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            guard let window = nsView.window else { return }
            configure(window)
        }
    }

    private func configure(_ window: NSWindow) {
        window.styleMask.insert([.titled, .closable, .fullSizeContentView])
        window.styleMask.remove([.resizable, .miniaturizable])
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true

        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        window.standardWindowButton(.closeButton)?.isHidden = false
    }
}
#endif
