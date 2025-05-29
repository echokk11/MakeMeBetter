//
//  BodyDataSection.swift
//  MakeMeBetter
//
//  Created by watchman on 2025/5/28.
//

import SwiftUI
import SwiftData

struct BodyDataSection: View {
    @Binding var bodyData: BodyData?
    let selectedDate: Date
    let isLocked: Bool
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appStateManager: AppStateManager
    @StateObject private var healthKitManager = HealthKitManager.shared
    
    @State private var weight: Double?
    @State private var bodyFat: Double?
    @State private var waistline: Double?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("身体数据")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                if let bmi = calculateBMI() {
                    HStack(spacing: 6) {
                        Text("BMI")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Text(String(format: "%.1f", bmi))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(bmiColor(bmi))
                        
                        Text(bmiCategory(bmi))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(bmiColor(bmi))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(bmiColor(bmi).opacity(0.1))
                    .cornerRadius(15)
                }
            }
            .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                SliderInputView(
                    title: "体重",
                    unit: "kg",
                    value: $weight,
                    range: 40.0...120.0,
                    displayValue: weight != nil ? String(format: "%.1f", weight!) : "N/A",
                    isDisabled: isLocked
                )
                
                SliderInputView(
                    title: "体脂",
                    unit: "%",
                    value: $bodyFat,
                    range: 8.0...35.0,
                    displayValue: bodyFat != nil ? String(format: "%.1f", bodyFat!) : "N/A",
                    isDisabled: isLocked
                )
                
                SliderInputView(
                    title: "腰围",
                    unit: "cm",
                    value: $waistline,
                    range: 60.0...120.0,
                    displayValue: waistline != nil ? String(format: "%.1f", waistline!) : "N/A",
                    isDisabled: isLocked
                )
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 12)
        .onAppear {
            loadData()
            Task {
                await autoSyncHealthDataForDate()
            }
        }
        .onChange(of: bodyData) { oldData, newData in
            print("BodyData变化: \(oldData != nil) -> \(newData != nil)")
            loadData()
        }
        .onChange(of: selectedDate) { _, _ in
            Task {
                await autoSyncHealthDataForDate()
            }
        }
        .onChange(of: weight) { _, _ in 
            saveData()
        }
        .onChange(of: bodyFat) { _, _ in 
            saveData() 
        }
        .onChange(of: waistline) { _, newValue in 
            saveData()
            // 腰围修改后自动写入Apple Health（仅在非锁定状态）
            if !isLocked, let waistValue = newValue {
                Task {
                    await saveWaistToHealthKit(waistValue)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)) { _ in
            print("收到数据库变化通知，重新加载身体数据")
            loadData()
        }
        .onReceive(NotificationCenter.default.publisher(for: .resetUIStates)) { _ in
            print("收到UI重置通知，重置身体数据UI状态")
            resetUIStates()
        }
        .onChange(of: appStateManager.dataResetTrigger) { _, _ in
            print("检测到全局数据重置，重置身体数据UI状态")
            resetUIStates()
        }
    }
    
    private func loadData() {
        // 确保当bodyData为nil时，所有状态都被重置
        weight = bodyData?.weight
        bodyFat = bodyData?.bodyFat
        waistline = bodyData?.waistline
        
        print("加载身体数据 - 日期: \(selectedDate), 体重: \(weight ?? 0), 体脂: \(bodyFat ?? 0), 腰围: \(waistline ?? 0)")
    }
    
    private func saveData() {
        // 如果锁定状态，不保存数据
        if isLocked {
            return
        }
        
        // 验证日期有效性 - 更严格的检查
        guard !selectedDate.timeIntervalSince1970.isNaN,
              selectedDate.timeIntervalSince1970 > 0,
              selectedDate < Date().addingTimeInterval(86400) else { // 不能超过明天
            print("错误：selectedDate无效，无法保存身体数据 - \(selectedDate)")
            return
        }
        
        // 确保使用当天开始时间
        let startOfDay = Calendar.current.startOfDay(for: selectedDate)
        
        if bodyData == nil {
            let newBodyData = BodyData(date: startOfDay)
            modelContext.insert(newBodyData)
            bodyData = newBodyData
        }
        
        bodyData?.updateData(weight: weight, bodyFat: bodyFat, waistline: waistline)
        
        do {
            try modelContext.save()
            print("保存身体数据成功 - 日期: \(startOfDay)")
        } catch {
            print("保存身体数据失败: \(error)")
        }
    }
    
    private func calculateBMI() -> Double? {
        guard let weight = weight, let height = getUserHeight() else { return nil }
        let heightInMeters = height / 100.0
        return weight / (heightInMeters * heightInMeters)
    }
    
    private func getUserHeight() -> Double? {
        // 从用户资料中获取身高
        let descriptor = FetchDescriptor<UserProfile>()
        do {
            let profiles = try modelContext.fetch(descriptor)
            return profiles.first?.height
        } catch {
            return nil
        }
    }
    
    private func bmiColor(_ bmi: Double) -> Color {
        switch bmi {
        case ..<18.5:
            return .blue
        case 18.5..<24:
            return .green
        case 24..<28:
            return .orange
        default:
            return .red
        }
    }
    
    private func bmiCategory(_ bmi: Double) -> String {
        switch bmi {
        case ..<18.5:
            return "偏瘦"
        case 18.5..<24:
            return "正常"
        case 24..<28:
            return "偏胖"
        default:
            return "肥胖"
        }
    }
    
    private func autoSyncHealthDataForDate() async {
        // 只有在本地没有数据时才从Apple Health自动同步
        guard bodyData == nil || (bodyData?.weight == nil && bodyData?.bodyFat == nil && bodyData?.waistline == nil) else {
            return
        }
        
        guard healthKitManager.isAuthorized else {
            await healthKitManager.requestAuthorization()
            return
        }
        
        let healthData = await healthKitManager.fetchAllDataForDate(selectedDate)
        
        // 只更新本地没有的数据
        var hasUpdates = false
        
        if bodyData?.weight == nil, let healthWeight = healthData.weight {
            weight = healthWeight
            hasUpdates = true
        }
        
        if bodyData?.bodyFat == nil, let healthBodyFat = healthData.bodyFat {
            bodyFat = healthBodyFat * 100 // 转换为百分比
            hasUpdates = true
        }
        
        if bodyData?.waistline == nil, let healthWaist = healthData.waist {
            waistline = healthWaist
            hasUpdates = true
        }
        
        // 如果有更新，保存数据
        if hasUpdates {
            saveData()
            print("自动同步健康数据完成 - 日期: \(selectedDate)")
        }
    }
    
    private func saveWaistToHealthKit(_ waist: Double) async {
        guard healthKitManager.isAuthorized else {
            return
        }
        
        // 创建带有指定日期的腰围数据
        let success = await healthKitManager.saveWaistCircumferenceForDate(waist, date: selectedDate)
        if success {
            print("腰围数据已保存到Apple Health: \(waist)cm，日期: \(selectedDate)")
        } else {
            print("保存腰围数据到Apple Health失败")
        }
    }
    
    private func resetUIStates() {
        // 重置所有UI状态变量
        weight = nil
        bodyFat = nil
        waistline = nil
        print("身体数据UI状态已重置")
    }
}

#Preview {
    @Previewable @State var bodyData: BodyData? = nil
    return BodyDataSection(bodyData: $bodyData, selectedDate: Date(), isLocked: false)
        .modelContainer(for: BodyData.self, inMemory: true)
        .padding()
} 
