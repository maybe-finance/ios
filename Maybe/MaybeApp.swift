//
//  MaybeApp.swift
//  Maybe
//
//  Created by Josh Pigford on 6/13/25.
//

import SwiftUI

@main
struct MaybeApp: App {
    @StateObject private var authManager = MaybeAuthManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
        }
    }
}
