//
//  ShareStore.swift
//  MappedDrive
//
//  Created by Codex on 2/12/26.
//

import AppKit
import Combine
import Foundation

@MainActor
final class ShareStore: ObservableObject {
    @Published private(set) var shares: [SMBShare] = []
    @Published var newShareName = ""
    @Published var newShareAddress = ""
    @Published var errorMessage: String?

    private let defaultsKey = "mappedDrive.smbShares"

    var canAddShare: Bool {
        !newShareName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !newShareAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    init() {
        loadShares()
    }

    func addShare() {
        let name = newShareName.trimmingCharacters(in: .whitespacesAndNewlines)
        let address = newShareAddress.trimmingCharacters(in: .whitespacesAndNewlines)

        addShare(name: name, address: address, bookmarkData: nil, clearDrafts: true)
    }

    func addShare(fromSelectedURL url: URL) {
        let typedName = newShareName.trimmingCharacters(in: .whitespacesAndNewlines)
        let defaultName = url.lastPathComponent.isEmpty ? "Network Share" : url.lastPathComponent
        let resolvedName = typedName.isEmpty ? defaultName : typedName
        let address = persistentAddress(for: url)
        let bookmarkData = try? url.bookmarkData(
            options: [.withSecurityScope],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        addShare(name: resolvedName, address: address, bookmarkData: bookmarkData, clearDrafts: false)
    }

    func remove(_ share: SMBShare) {
        shares.removeAll { $0.id == share.id }
        errorMessage = nil
        saveShares()
    }

    func open(_ share: SMBShare) {
        guard let url = share.url else {
            errorMessage = "Invalid SMB address for '\(share.name)'."
            return
        }

        let success = NSWorkspace.shared.open(url)
        if success {
            errorMessage = nil
        } else {
            errorMessage = "Couldn't open '\(share.displayAddress)' in Finder."
        }
    }

    private func saveShares() {
        do {
            let data = try JSONEncoder().encode(shares)
            UserDefaults.standard.set(data, forKey: defaultsKey)
        } catch {
            errorMessage = "Couldn't save shares. \(error.localizedDescription)"
        }
    }

    private func addShare(name: String, address: String, bookmarkData: Data?, clearDrafts: Bool) {
        guard !name.isEmpty, !address.isEmpty else {
            errorMessage = "Both name and share address are required."
            return
        }

        shares.append(SMBShare(name: name, address: address, bookmarkData: bookmarkData))
        if clearDrafts {
            newShareName = ""
            newShareAddress = ""
        }
        errorMessage = nil
        saveShares()
    }

    private func persistentAddress(for selectedURL: URL) -> String {
        guard selectedURL.isFileURL else {
            return selectedURL.absoluteString
        }

        guard
            let resourceValues = try? selectedURL.resourceValues(forKeys: [.volumeURLForRemountingKey]),
            let remountURL = resourceValues.volumeURLForRemounting,
            let scheme = remountURL.scheme?.lowercased(),
            scheme == "smb"
        else {
            return selectedURL.absoluteString
        }

        let pathComponents = selectedURL.standardizedFileURL.pathComponents
        let relativeComponents: ArraySlice<String>
        if pathComponents.count >= 3 && pathComponents[1] == "Volumes" {
            relativeComponents = pathComponents.dropFirst(3)
        } else {
            relativeComponents = []
        }

        var fullURL = remountURL
        for component in relativeComponents where !component.isEmpty && component != "/" {
            fullURL.appendPathComponent(component)
        }

        return fullURL.absoluteString
    }

    private func loadShares() {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey) else {
            return
        }

        do {
            shares = try JSONDecoder().decode([SMBShare].self, from: data)
        } catch {
            errorMessage = "Couldn't load saved shares. \(error.localizedDescription)"
        }
    }
}
