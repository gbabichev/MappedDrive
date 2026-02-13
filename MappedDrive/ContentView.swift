//
//  ContentView.swift
//  MappedDrive
//
//  Created by George Babichev on 2/12/26.
//

import SwiftUI
import AppKit
import ServiceManagement

struct ContentView: View {
    @ObservedObject var shareStore: ShareStore
    @Environment(\.openWindow) private var openWindow

    private static let loginHelperIdentifier = "com.georgebabichev.MappedDriveHelper"
    @State private var isChecked: Bool = {
        let loginService = SMAppService.loginItem(identifier: loginHelperIdentifier)
        return loginService.status == .enabled   // True if login item is currently enabled
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mapped Drives")
                .font(.headline)

            if shareStore.shares.isEmpty {
                Text("No shares yet. Add one below.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(shareStore.shares) { share in
                    HStack(spacing: 8) {
                        Button {
                            shareStore.open(share)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(share.name)
                                        .font(.body)
                                    Text(share.displayAddress)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer(minLength: 0)
                            }
                            .contentShape(Rectangle())
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .buttonStyle(.plain)

                        Button {
                            shareStore.startEditing(share)
                        } label: {
                            Image(systemName: "pencil")
                        }
                        .buttonStyle(.borderless)

                        Button(role: .destructive) {
                            shareStore.remove(share)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }

            Divider()

            TextField("Display name", text: $shareStore.newShareName)
                .textFieldStyle(.roundedBorder)

            HStack(spacing: 8) {
                TextField("smb://server/share or server/share", text: $shareStore.newShareAddress)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        shareStore.addShare()
                    }

                Button("Open") {
                    openSharePicker()
                }
            }

            SettingsRow("Start on Login", subtitle: "Starts app during logon.") {
                Toggle("", isOn: $isChecked)
                    .toggleStyle(.switch)             // Makes the toggle look like a checkbox (macOS style)
                    .onChange(of: isChecked) {          // Runs when the checkbox value changes
                        toggleLaunchAtLogin(isChecked)  // Calls function to enable/disable the login item
                    }
            }
            

            
            HStack {
                Button(shareStore.isEditingShare ? "Update Share" : "Add Share") {
                    shareStore.saveEditor()
                }
                .disabled(!shareStore.canAddShare)

                if shareStore.isEditingShare {
                    Button("Cancel") {
                        shareStore.cancelEditing()
                    }
                }

                Spacer()

                Button("About") {
                    NSApp.activate(ignoringOtherApps: true)
                    openWindow(id: "about")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        let aboutWindowID = NSUserInterfaceItemIdentifier("mappedDrive.aboutWindow")
                        NSApp.windows
                            .first(where: { $0.identifier == aboutWindowID })?
                            .makeKeyAndOrderFront(nil)
                    }
                }

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
            }

            if let errorMessage = shareStore.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .frame(minWidth: 340)
    }
    
    // Handles enabling or disabling the login helper at login
    private func toggleLaunchAtLogin(_ enabled: Bool) {
        // Create a reference to the login item service using the static identifier
        let loginService = SMAppService.loginItem(identifier: Self.loginHelperIdentifier)
        do {
            if enabled {
                // If enabled, try to register the login helper so it launches at login
                try loginService.register()
            } else {
                // If disabled, try to unregister it
                try loginService.unregister()
            }
        } catch {
            // If anything fails, show a user-facing alert dialog with error info
            showErrorAlert(message: "Failed to update Login Item.", info: error.localizedDescription)
        }
    }

    // Utility to show an error alert dialog to the user
    private func showErrorAlert(message: String, info: String? = nil) {
        let alert = NSAlert()                  // Create a new alert
        alert.messageText = message            // Set the main alert message
        if let info = info {                   // Optionally set additional error details
            alert.informativeText = info
        }
        alert.alertStyle = .warning            // Set alert style (yellow exclamation)
        alert.runModal()                       // Display the alert as a modal dialog
    }

    private func openSharePicker() {
        // Menu-bar apps can inherit odd default panel paths; always start from Home.
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        NSApp.activate(ignoringOtherApps: true)

        let panel = NSOpenPanel()
        panel.title = "Select Share"
        panel.message = "Choose a network share folder to save."
        panel.prompt = "Save Share"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = false
        panel.allowsMultipleSelection = false
        panel.directoryURL = homeDirectory

        guard panel.runModal() == .OK, let selectedURL = panel.url else {
            return
        }

        shareStore.addShare(fromSelectedURL: selectedURL)
    }
}
