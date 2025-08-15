//
//  final_ai_day_workApp.swift
//  final_ai_day_work
//
//  Created by 慧誉 on 2025/8/15.
//

import SwiftUI

@main
struct final_ai_day_workApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
