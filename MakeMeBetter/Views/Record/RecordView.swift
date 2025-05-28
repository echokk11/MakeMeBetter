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
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                DateSelectorView(selectedDate: $selectedDate)
                
                VStack(spacing: 12) {
                    BodyDataSection(
                        bodyData: $bodyData,
                        selectedDate: selectedDate
                    )
                    .id("body-\(selectedDate.timeIntervalSince1970)")
                    
                    ExerciseDataSection(
                        exerciseData: $exerciseData,
                        selectedDate: selectedDate
                    )
                    .id("exercise-\(selectedDate.timeIntervalSince1970)")
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 16)
        }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            loadDataForDate()
        }
        .onChange(of: selectedDate) { _ in
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