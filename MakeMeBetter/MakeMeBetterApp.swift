//
//  MakeMeBetterApp.swift
//  MakeMeBetter
//
//  Created by watchman on 2025/5/28.
//

import SwiftUI
import SwiftData

// 全局状态管理器
class AppStateManager: ObservableObject {
    @Published var dataResetTrigger = UUID()
    
    static let shared = AppStateManager()
    
    private init() {}
    
    func triggerDataReset() {
        DispatchQueue.main.async {
            self.dataResetTrigger = UUID()
        }
    }
}

@main
struct MakeMeBetterApp: App {
    @StateObject private var appStateManager = AppStateManager.shared
    
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
            MainTabView()
                .environmentObject(appStateManager)
                .modelContainer(sharedModelContainer)
        }
    }
}
