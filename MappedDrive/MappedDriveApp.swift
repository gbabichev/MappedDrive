//
//  MappedDriveApp.swift
//  MappedDrive
//
//  Created by George Babichev on 2/12/26.
//

import SwiftUI

@main
struct MappedDriveApp: App {
    @StateObject private var shareStore = ShareStore()

    var body: some Scene {
        MenuBarExtra("MappedDrive", systemImage: "externaldrive.connected.to.line.below") {
            ContentView(shareStore: shareStore)
        }
        .menuBarExtraStyle(.window)
    }
}
