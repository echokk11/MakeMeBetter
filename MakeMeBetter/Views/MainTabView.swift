//
//  MainTabView.swift
//  MakeMeBetter
//
//  Created by watchman on 2025/5/28.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            RecordView()
                .tabItem {
                    Image(systemName: "pencil.and.list.clipboard")
                    Text("记录")
                }
            
            TrendView()
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("趋势")
                }
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.circle")
                    Text("我")
                }
        }
        .accentColor(.blue)
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [BodyData.self, ExerciseData.self, UserProfile.self], inMemory: true)
} 