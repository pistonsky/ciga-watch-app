//
//  CigaApp.swift
//  Ciga Watch App
//
//  Created by Aleksandr Tsygankov on 4/30/23.
//

import SwiftUI
import SwiftData

@main
struct CigaWatchApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Inhale.self)
    }
}
