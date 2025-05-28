//
//  ExerciseDataSection.swift
//  MakeMeBetter
//
//  Created by watchman on 2025/5/28.
//

import SwiftUI
import SwiftData

struct ExerciseDataSection: View {
    @Binding var exerciseData: [ExerciseData]
    let selectedDate: Date
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("锻炼数据")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
                .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                ForEach(ExerciseType.allCases, id: \.self) { type in
                    ExerciseTypeCard(
                        exerciseType: type,
                        exerciseData: exerciseDataForType(type),
                        selectedDate: selectedDate,
                        onDataChanged: { data in
                            updateExerciseData(for: type, with: data)
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 12)
    }
    
    private func exerciseDataForType(_ type: ExerciseType) -> ExerciseData? {
        return exerciseData.first { $0.exerciseType == type }
    }
    
    private func updateExerciseData(for type: ExerciseType, with data: ExerciseData?) {
        // 移除旧数据
        if let existingIndex = exerciseData.firstIndex(where: { $0.exerciseType == type }) {
            exerciseData.remove(at: existingIndex)
        }
        
        // 添加新数据
        if let data = data {
            exerciseData.append(data)
        }
    }
}

struct ExerciseTypeCard: View {
    let exerciseType: ExerciseType
    let exerciseData: ExerciseData?
    let selectedDate: Date
    let onDataChanged: (ExerciseData?) -> Void
    
    @Environment(\.modelContext) private var modelContext
    @State private var duration: Double?
    
    private let quickDurations: [Double] = [20, 30, 40, 50, 60]
    
    private var backgroundColor: Color {
        switch exerciseType {
        case .cardio:
            return Color.green.opacity(0.08)
        case .strength:
            return Color.orange.opacity(0.08)
        case .hiit:
            return Color.red.opacity(0.08)
        }
    }
    
    private var accentColor: Color {
        switch exerciseType {
        case .cardio:
            return Color.green
        case .strength:
            return Color.orange
        case .hiit:
            return Color.red
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(exerciseType.rawValue)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(accentColor)
            
            SliderInputView(
                title: "时长",
                unit: "m",
                value: $duration,
                range: 0.0...120.0,
                step: 1.0
            )
            
            // 快捷按钮
            HStack(spacing: 8) {
                Text("快捷:")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                
                ForEach(quickDurations, id: \.self) { minutes in
                    Button(action: {
                        duration = minutes
                    }) {
                        Text("\(Int(minutes))")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(duration == minutes ? .white : accentColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(duration == minutes ? accentColor : accentColor.opacity(0.1))
                            .cornerRadius(6)
                    }
                }
                
                Spacer()
            }
        }
        .padding(12)
        .background(backgroundColor)
        .cornerRadius(10)
        .onAppear {
            loadData()
        }
        .onChange(of: exerciseData) { _ in
            loadData()
        }
        .onChange(of: duration) { _ in saveData() }
    }
    
    private func loadData() {
        duration = exerciseData?.duration
    }
    
    private func saveData() {
        if duration == nil || duration == 0 {
            // 如果时长为空或0，删除数据
            if let data = exerciseData {
                modelContext.delete(data)
                onDataChanged(nil)
            }
        } else {
            // 创建或更新数据
            let data = exerciseData ?? ExerciseData(date: selectedDate, type: exerciseType)
            if exerciseData == nil {
                modelContext.insert(data)
            }
            
            data.updateData(duration: duration, intensity: nil, calories: nil)
            onDataChanged(data)
        }
        
        do {
            try modelContext.save()
        } catch {
            print("保存锻炼数据失败: \(error)")
        }
    }
}

#Preview {
    @State var exerciseData: [ExerciseData] = []
    return ExerciseDataSection(exerciseData: $exerciseData, selectedDate: Date())
        .modelContainer(for: ExerciseData.self, inMemory: true)
        .padding()
} 