//
//  MainTabView.swift
//  MakeMeBetter
//
//  Created by watchman on 2025/5/28.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            RecordView()
                .tabItem {
                    Image(systemName: "pencil.and.list.clipboard")
                    Text("记录")
                }
                .tag(0)
            
            TrendView()
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("趋势")
                }
                .tag(1)
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.circle")
                    Text("我")
                }
                .tag(2)
        }
        .accentColor(.blue)
        .onChange(of: selectedTab) { oldTab, newTab in
            if newTab == 0 { // 切换到记录tab
                // 发送通知触发记录页面重新加载数据
                NotificationCenter.default.post(name: Notification.Name("recordTabSelected"), object: nil)
            }
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [BodyData.self, ExerciseData.self, UserProfile.self], inMemory: true)
} 