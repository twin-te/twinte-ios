//
//  twinte_watchApp.swift
//  twinte-watch Watch App
//
//  Created by Takayuki Ueno on 2025/05/21.
//  Copyright © 2025 tako. All rights reserved.
//

import SwiftUI

@main
struct twinte_watch_Watch_AppApp: App {
    @StateObject var sessionManager = WatchOSSessionManager.shared
    
    init() {
        
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(sessionManager)
        }
    }
}
