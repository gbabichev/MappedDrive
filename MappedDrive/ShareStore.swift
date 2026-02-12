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

        guard !name.isEmpty, !address.isEmpty else {
            errorMessage = "Both name and share address are required."
            return
        }

        shares.append(SMBShare(name: name, address: address))
        newShareName = ""
        newShareAddress = ""
        errorMessage = nil
        saveShares()
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
