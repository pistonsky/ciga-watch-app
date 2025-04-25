//
//  SettingsView.swift
//  Ciga Watch App
//
//  Created by Aleksandr Tsygankov on 4/30/23.
//

import SwiftUI

struct SettingsView: View {
    @Binding var showInhales: Bool
    
    var body: some View {
        List {
            Section {
                Toggle("Show as Inhales", isOn: $showInhales)
                Text(showInhales ? 
                     "Shows total inhales (8 per cigarette)" : 
                     "Shows equivalent cigarettes (1 cig = 8 inhales)")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            } header: {
                Text("Display Mode")
            } footer: {
                Text("This setting only changes how counts are displayed. Tracking remains the same.")
                    .font(.footnote)
            }
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    SettingsView(showInhales: .constant(true))
} 