//
//  ContentView.swift
//  Ciga Watch App
//
//  Created by Aleksandr Tsygankov on 4/30/23.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var model: InhaleRecordModel
    
    var body: some View {
        TabView {
            NavigationStack {
                TrackerView()
            }
            NavigationStack {
                ChartView()
            }
        }.tabViewStyle(.page)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(InhaleRecordModel.init())
    }
}
