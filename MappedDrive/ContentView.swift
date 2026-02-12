//
//  ContentView.swift
//  MappedDrive
//
//  Created by George Babichev on 2/12/26.
//

import SwiftUI
import AppKit

struct ContentView: View {
    @ObservedObject var shareStore: ShareStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SMB Shares")
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
                            VStack(alignment: .leading, spacing: 2) {
                                Text(share.name)
                                    .font(.body)
                                Text(share.displayAddress)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)

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

            TextField("smb://server/share or server/share", text: $shareStore.newShareAddress)
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    shareStore.addShare()
                }

            HStack {
                Button("Add Share") {
                    shareStore.addShare()
                }
                .disabled(!shareStore.canAddShare)

                Spacer()

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
}
