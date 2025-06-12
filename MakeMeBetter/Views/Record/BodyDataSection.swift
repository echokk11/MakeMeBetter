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
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appStateManager: AppStateManager
    
    @State private var weight: Double?
    @State private var bodyFat: Double?
    @State private var waistline: Double?
    
    // 历史数据状态
    @State private var yesterdayData: BodyData?
    @State private var last7DaysData: [BodyData] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题和趋势提示
            VStack(alignment: .leading, spacing: 8) {
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
                
                // 趋势提示
                if let trendTip = generateTrendTip() {
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundColor(.blue)
                            .font(.caption)
                        
                        Text(trendTip)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 4)
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
                    yesterdayValue: yesterdayData?.weight,
                    smartRange: calculateSmartRange(for: .weight)
                )
                
                SliderInputView(
                    title: "体脂",
                    unit: "%",
                    value: $bodyFat,
                    range: 8.0...35.0,
                    displayValue: bodyFat != nil ? String(format: "%.1f", bodyFat!) : "N/A",
                    yesterdayValue: yesterdayData?.bodyFat,
                    smartRange: calculateSmartRange(for: .bodyFat)
                )
                
                SliderInputView(
                    title: "腰围",
                    unit: "cm",
                    value: $waistline,
                    range: 60.0...120.0,
                    displayValue: waistline != nil ? String(format: "%.1f", waistline!) : "N/A",
                    yesterdayValue: yesterdayData?.waistline,
                    smartRange: calculateSmartRange(for: .waistline)
                )
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 12)
        .onAppear {
            loadData()
            loadHistoricalData()
        }
        .onChange(of: bodyData) { oldData, newData in
            print("BodyData变化: \(oldData != nil) -> \(newData != nil)")
            // 只有当数据确实发生变化时才加载
            if oldData !== newData {
                loadData()
            }
        }
        .onChange(of: selectedDate) { _, _ in
            loadHistoricalData()
        }
        .onChange(of: weight) { _, _ in 
            saveData()
        }
        .onChange(of: bodyFat) { _, _ in 
            saveData() 
        }
        .onChange(of: waistline) { _, _ in 
            saveData()
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
    
    // 数据类型枚举
    private enum DataType {
        case weight, bodyFat, waistline
    }
    
    // 计算智能范围
    private func calculateSmartRange(for type: DataType) -> ClosedRange<Double>? {
        let values: [Double]
        let defaultRange: ClosedRange<Double>
        let buffer: Double
        
        switch type {
        case .weight:
            values = last7DaysData.compactMap { $0.weight }
            defaultRange = 40.0...120.0
            buffer = 5.0 // ±5kg的缓冲
        case .bodyFat:
            values = last7DaysData.compactMap { $0.bodyFat }
            defaultRange = 8.0...35.0
            buffer = 3.0 // ±3%的缓冲
        case .waistline:
            values = last7DaysData.compactMap { $0.waistline }
            defaultRange = 60.0...120.0
            buffer = 5.0 // ±5cm的缓冲
        }
        
        guard !values.isEmpty else { return nil }
        
        let min = values.min()! - buffer
        let max = values.max()! + buffer
        
        // 确保智能范围在默认范围内
        let adjustedMin = Swift.max(min, defaultRange.lowerBound)
        let adjustedMax = Swift.min(max, defaultRange.upperBound)
        
        // 确保范围至少有合理的宽度
        let minWidth = buffer * 2
        if adjustedMax - adjustedMin < minWidth {
            let center = (adjustedMin + adjustedMax) / 2
            let newMin = Swift.max(center - minWidth/2, defaultRange.lowerBound)
            let newMax = Swift.min(center + minWidth/2, defaultRange.upperBound)
            return newMin...newMax
        }
        
        return adjustedMin...adjustedMax
    }
    
    // 生成趋势提示
    private func generateTrendTip() -> String? {
        guard last7DaysData.count >= 3 else { return nil }
        
        let weightTrend = calculateTrend(values: last7DaysData.compactMap { $0.weight })
        let bodyFatTrend = calculateTrend(values: last7DaysData.compactMap { $0.bodyFat })
        let waistTrend = calculateTrend(values: last7DaysData.compactMap { $0.waistline })
        
        var tips: [String] = []
        
        if abs(weightTrend) > 0.2 {
            let direction = weightTrend > 0 ? "上升" : "下降"
            tips.append("体重呈\(direction)趋势")
        }
        
        if abs(bodyFatTrend) > 0.3 {
            let direction = bodyFatTrend > 0 ? "上升" : "下降"
            tips.append("体脂呈\(direction)趋势")
        }
        
        if abs(waistTrend) > 0.5 {
            let direction = waistTrend > 0 ? "增加" : "减少"
            tips.append("腰围呈\(direction)趋势")
        }
        
        return tips.isEmpty ? nil : tips.joined(separator: " · ")
    }
    
    // 计算趋势（简单线性回归斜率）
    private func calculateTrend(values: [Double]) -> Double {
        guard values.count >= 2 else { return 0 }
        
        let n = Double(values.count)
        let sumX = (0..<values.count).reduce(0) { $0 + Double($1) }
        let sumY = values.reduce(0, +)
        let sumXY = values.enumerated().reduce(0) { $0 + Double($1.offset) * $1.element }
        let sumX2 = (0..<values.count).reduce(0) { $0 + Double($1) * Double($1) }
        
        let slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX)
        return slope
    }
    
    // 加载历史数据
    private func loadHistoricalData() {
        let calendar = Calendar.current
        
        // 加载昨天的数据
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: selectedDate) {
            let yesterdayStart = calendar.startOfDay(for: yesterday)
            let yesterdayDescriptor = FetchDescriptor<BodyData>(
                predicate: #Predicate { $0.date == yesterdayStart }
            )
            
            do {
                let results = try modelContext.fetch(yesterdayDescriptor)
                yesterdayData = results.first
            } catch {
                print("加载昨天数据失败: \(error)")
                yesterdayData = nil
            }
        }
        
        // 加载过去7天的数据
        if let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: selectedDate) {
            let sevenDaysAgoStart = calendar.startOfDay(for: sevenDaysAgo)
            let selectedStart = calendar.startOfDay(for: selectedDate)
            
            let last7DaysDescriptor = FetchDescriptor<BodyData>(
                predicate: #Predicate { data in
                    data.date >= sevenDaysAgoStart && data.date < selectedStart
                },
                sortBy: [SortDescriptor(\.date, order: .forward)]
            )
            
            do {
                last7DaysData = try modelContext.fetch(last7DaysDescriptor)
            } catch {
                print("加载7天数据失败: \(error)")
                last7DaysData = []
            }
        }
    }
    
    private func loadData() {
        // 从传入的 bodyData 加载数据到UI状态
        weight = bodyData?.weight
        bodyFat = bodyData?.bodyFat
        waistline = bodyData?.waistline
        
        print("📊 加载身体数据 - 日期: \(selectedDate), 体重: \(weight ?? 0), 体脂: \(bodyFat ?? 0), 腰围: \(waistline ?? 0)")
    }
    
    private func saveData() {
        
        // 验证日期有效性
        guard !selectedDate.timeIntervalSince1970.isNaN,
              selectedDate.timeIntervalSince1970 > 0,
              selectedDate < Date().addingTimeInterval(86400) else {
            print("❌ 错误：selectedDate无效，无法保存身体数据 - \(selectedDate)")
            return
        }
        
        // 确保使用当天开始时间
        let startOfDay = Calendar.current.startOfDay(for: selectedDate)
        
        // 如果没有bodyData，创建新的
        if bodyData == nil {
            let newBodyData = BodyData(date: startOfDay)
            modelContext.insert(newBodyData)
            bodyData = newBodyData
        }
        
        // 更新数据
        bodyData?.updateData(weight: weight, bodyFat: bodyFat, waistline: waistline)
        
        do {
            try modelContext.save()
            print("✅ 保存身体数据成功 - 日期: \(startOfDay)")
        } catch {
            print("❌ 保存身体数据失败: \(error)")
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
    
    private func resetUIStates() {
        // 重置所有UI状态变量
        weight = nil
        bodyFat = nil
        waistline = nil
        yesterdayData = nil
        last7DaysData = []
        
        print("🔄 身体数据UI状态已重置")
    }
}

#Preview {
    @Previewable @State var bodyData: BodyData? = nil
    return BodyDataSection(bodyData: $bodyData, selectedDate: Date())
        .modelContainer(for: BodyData.self, inMemory: true)
        .padding()
} 
