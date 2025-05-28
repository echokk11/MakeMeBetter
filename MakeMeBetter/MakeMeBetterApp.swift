//
//  MakeMeBetterApp.swift
//  MakeMeBetter
//
//  Created by watchman on 2025/5/28.
//

import SwiftUI
import SwiftData

@main
struct MakeMeBetterApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            BodyData.self,
            ExerciseData.self,
            UserProfile.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            // 临时显示图标导出工具，用于生成应用图标
            // 生成完图标后请改回 MainTabView()
            IconExportView()
                .modelContainer(sharedModelContainer)
        }
    }
}
