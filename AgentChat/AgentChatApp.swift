//
//  AgentChatApp.swift
//  AgentChat
//
//  Created by Mario Moschetta on 04/07/25.
//

import SwiftUI

@main
struct AgentChatApp: App {
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
    }
}
