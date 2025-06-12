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
    @EnvironmentObject private var appStateManager: AppStateManager
    
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
                    .id("\(type.rawValue)-\(selectedDate.timeIntervalSince1970)")
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 12)
        .onReceive(NotificationCenter.default.publisher(for: .resetUIStates)) { _ in
            print("收到UI重置通知，重置锻炼数据UI状态")
            exerciseData = []
        }
        .onChange(of: appStateManager.dataResetTrigger) { _, _ in
            print("检测到全局数据重置，重置锻炼数据UI状态")
            exerciseData = []
        }
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
                        // 添加触觉反馈
                        HapticFeedback.shared.lightImpact()
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
            duration = exerciseData?.duration
        }

        .onChange(of: exerciseData) { oldData, newData in
            // 数据变化时更新UI状态
            print("数据变化: \(exerciseType.rawValue), 旧数据: \(oldData?.duration ?? 0), 新数据: \(newData?.duration ?? 0)")
            // 只有当数据确实发生变化时才加载，且避免循环触发
            if oldData !== newData, newData?.duration != duration {
                duration = newData?.duration
            }
        }
        .onChange(of: duration) { oldDuration, newDuration in
            // 只有用户主动修改时才保存，且避免加载时触发保存
            if oldDuration != newDuration, newDuration != exerciseData?.duration {
                print("用户修改时长: \(exerciseType.rawValue), \(oldDuration ?? 0) -> \(newDuration ?? 0)")
                saveData()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .resetUIStates)) { _ in
            print("收到UI重置通知，重置\(exerciseType.rawValue)时长状态")
            duration = nil
        }
    }
    

    
    private func saveData() {
        
        // 验证日期有效性 - 更严格的检查
        guard !selectedDate.timeIntervalSince1970.isNaN,
              selectedDate.timeIntervalSince1970 > 0,
              selectedDate < Date().addingTimeInterval(86400) else { // 不能超过明天
            print("错误：selectedDate无效，无法保存锻炼数据 - \(selectedDate)")
            return
        }
        
        // 确保使用当天开始时间，与查询逻辑保持一致
        let startOfDay = Calendar.current.startOfDay(for: selectedDate)
        
        if duration == nil || duration == 0 {
            // 如果时长为空或0，删除数据
            if let data = exerciseData {
                modelContext.delete(data)
                onDataChanged(nil)
            }
        } else {
            // 创建或更新数据
            let data = exerciseData ?? ExerciseData(date: startOfDay, type: exerciseType)
            if exerciseData == nil {
                modelContext.insert(data)
            }
            
            data.updateData(duration: duration, intensity: nil, calories: nil)
            onDataChanged(data)
        }
        
        do {
            try modelContext.save()
            print("保存锻炼数据成功 - 日期: \(startOfDay), 类型: \(exerciseType.rawValue), 时长: \(duration ?? 0)")
        } catch {
            print("保存锻炼数据失败: \(error)")
        }
    }
}

#Preview {
    @Previewable @State var exerciseData: [ExerciseData] = []
    return ExerciseDataSection(exerciseData: $exerciseData, selectedDate: Date())
        .modelContainer(for: ExerciseData.self, inMemory: true)
        .padding()
} 