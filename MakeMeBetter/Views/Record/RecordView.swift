//
//  RecordView.swift
//  MakeMeBetter
//
//  Created by watchman on 2025/5/28.
//

import SwiftUI
import SwiftData

struct RecordView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedDate = Date()
    @State private var bodyData: BodyData?
    @State private var exerciseData: [ExerciseData] = []
    @State private var isLocked = false
    
    // 判断是否是历史日期（当天之前）
    private var isHistoricalDate: Bool {
        !Calendar.current.isDate(selectedDate, inSameDayAs: Date()) && 
        selectedDate < Date()
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // 顶部安全区域 - 与刘海屏融为一体
                Color.clear
                    .frame(height: 1)
                
                // 日期选择器和锁定按钮
                HStack {
                    DateSelectorView(selectedDate: $selectedDate)
                    
                    // 锁定按钮 - 只在历史日期显示
                    if isHistoricalDate {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isLocked.toggle()
                            }
                        }) {
                            Image(systemName: isLocked ? "lock.fill" : "lock.open.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(isLocked ? .red : .green)
                                .frame(width: 32, height: 32)
                                .background((isLocked ? Color.red : Color.green).opacity(0.1))
                                .clipShape(Circle())
                        }
                        .padding(.trailing, 20)
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 16)
                
                VStack(spacing: 12) {
                    BodyDataSection(
                        bodyData: $bodyData,
                        selectedDate: selectedDate,
                        isLocked: isHistoricalDate && isLocked
                    )
                    .id("body-\(selectedDate.timeIntervalSince1970)")
                    
                    ExerciseDataSection(
                        exerciseData: $exerciseData,
                        selectedDate: selectedDate,
                        isLocked: isHistoricalDate && isLocked
                    )
                    .id("exercise-\(selectedDate.timeIntervalSince1970)")
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 16)
        }
        .background(
            LinearGradient(
                colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .onAppear {
            loadDataForDate()
        }
        .onChange(of: selectedDate) { _ in
            // 切换日期时重新锁定
            isLocked = true
            loadDataForDate()
        }
    }
    
    private func loadDataForDate() {
        let startOfDay = Calendar.current.startOfDay(for: selectedDate)
        
        // 加载身体数据
        let bodyDataDescriptor = FetchDescriptor<BodyData>(
            predicate: #Predicate { $0.date == startOfDay }
        )
        
        do {
            let bodyDataResults = try modelContext.fetch(bodyDataDescriptor)
            bodyData = bodyDataResults.first
        } catch {
            print("加载身体数据失败: \(error)")
            bodyData = nil
        }
        
        // 加载锻炼数据
        let exerciseDataDescriptor = FetchDescriptor<ExerciseData>(
            predicate: #Predicate { $0.date == startOfDay }
        )
        
        do {
            exerciseData = try modelContext.fetch(exerciseDataDescriptor)
        } catch {
            print("加载锻炼数据失败: \(error)")
            exerciseData = []
        }
        
        print("加载日期: \(startOfDay), 身体数据: \(bodyData != nil), 锻炼数据: \(exerciseData.count)")
    }
}

#Preview {
    RecordView()
        .modelContainer(for: [BodyData.self, ExerciseData.self], inMemory: true)
} 