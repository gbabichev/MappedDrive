//
//  SMBShare.swift
//  MappedDrive
//
//  Created by Codex on 2/12/26.
//

import Foundation

struct SMBShare: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var address: String
    var bookmarkData: Data?

    init(id: UUID = UUID(), name: String, address: String, bookmarkData: Data? = nil) {
        self.id = id
        self.name = name
        self.address = address
        self.bookmarkData = bookmarkData
    }

    var trimmedAddress: String {
        address.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var displayAddress: String {
        guard !trimmedAddress.isEmpty else { return "-" }
        if trimmedAddress.contains("://") {
            return trimmedAddress
        }
        return "smb://\(trimmedAddress)"
    }

    var url: URL? {
        guard !trimmedAddress.isEmpty else { return nil }
        if trimmedAddress.contains("://") {
            return URL(string: trimmedAddress)
        }
        return URL(string: "smb://\(trimmedAddress)")
    }
}
