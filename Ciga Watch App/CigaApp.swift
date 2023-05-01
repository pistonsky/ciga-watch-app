//
//  CigaApp.swift
//  Ciga Watch App
//
//  Created by Aleksandr Tsygankov on 4/30/23.
//

import SwiftUI

@main
struct CigaWatchApp: App {
    
    @StateObject var itemListModel = InhaleRecordModel()
    
    @SceneBuilder var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(itemListModel)
        }
    }
}
