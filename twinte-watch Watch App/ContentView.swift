//
//  ContentView.swift
//  twinte-watch Watch App
//
//  Created by Takayuki Ueno on 2025/05/21.
//  Copyright © 2025 tako. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var sessionManager: WatchOSSessionManager
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
            
            if sessionManager.receivedData.isEmpty {
                Text("No data.")
            } else {
                if let data = sessionManager.receivedData["data"] as? String {
                    Text("Data: \(data)")
                } else if let error = sessionManager.receivedData["error"] as? String {
                    Text("Error: \(error)")
                } else {
                    Text("Recived unknown data...")
                }
            }
            
            Button("Fetch Data from App") {
                sessionManager.requestDataFromApp()
            }.padding()
        }
        .padding()
    }
}

#Preview {
    let manager = WatchOSSessionManager.shared
    return ContentView().environmentObject(manager)
}
