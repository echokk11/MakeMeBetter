//
//  TrendView.swift
//  MakeMeBetter
//
//  Created by watchman on 2025/5/28.
//

import SwiftUI
import SwiftData
import Charts

struct TrendView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var bodyDataList: [BodyData] = []
    @State private var exerciseDataList: [ExerciseData] = []
    @State private var selectedMetric: MetricType = .weight
    @State private var dateRange: DateRange = .week
    @State private var userProfile: UserProfile?
    
    enum MetricType: String, CaseIterable {
        case weight = "体重"
        case bodyFat = "体脂"
        case waistline = "腰围"
        case cardio = "有氧时长"
        case strength = "力量时长"
        case hiit = "HIIT时长"
        
        var unit: String {
            switch self {
            case .weight: return "kg"
            case .bodyFat: return "%"
            case .waistline: return "cm"
            case .cardio, .strength, .hiit: return "分钟"
            }
        }
        
        var color: Color {
            switch self {
            case .weight: return .blue
            case .bodyFat: return .orange
            case .waistline: return .purple
            case .cardio: return .green
            case .strength: return .orange
            case .hiit: return .red
            }
        }
    }
    
    enum DateRange: String, CaseIterable {
        case week = "7天"
        case twoWeeks = "14天"
        case month = "30天"
        
        var days: Int {
            switch self {
            case .week: return 7
            case .twoWeeks: return 14
            case .month: return 30
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 选择器区域
                VStack(spacing: 20) {
                    // 指标选择
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 80), spacing: 12)
                    ], spacing: 12) {
                        ForEach(MetricType.allCases, id: \.self) { metric in
                            Button(action: {
                                selectedMetric = metric
                            }) {
                                VStack(spacing: 4) {
                                    Image(systemName: iconForMetric(metric))
                                        .font(.system(size: 16, weight: .medium))
                                    
                                    Text(metric.rawValue)
                                        .font(.system(size: 12, weight: .medium))
                                }
                                .foregroundColor(selectedMetric == metric ? .white : metric.color)
                                .frame(height: 50)
                                .frame(maxWidth: .infinity)
                                .background(selectedMetric == metric ? metric.color : metric.color.opacity(0.1))
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // 日期范围选择
                    Picker("时间范围", selection: $dateRange) {
                        ForEach(DateRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                )
                .padding(.horizontal, 16)
                
                // 图表区域
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(selectedMetric.rawValue)趋势")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Text("最近\(dateRange.rawValue)数据")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(selectedMetric.color)
                                    .frame(width: 8, height: 8)
                                
                                Text(selectedMetric.unit)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(selectedMetric.color)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedMetric.color.opacity(0.1))
                            .cornerRadius(12)
                            
                            // 显示目标值
                            if let targetValue = currentTargetValue {
                                HStack(spacing: 4) {
                                    Text("目标:")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                    
                                    Text("\(formatValue(targetValue))\(selectedMetric.unit)")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    if chartData.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 50))
                                .foregroundColor(selectedMetric.color.opacity(0.6))
                            
                            VStack(spacing: 8) {
                                Text("暂无数据")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                Text("开始记录\(selectedMetric.rawValue)数据后\n这里将显示趋势图表")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(2)
                            }
                        }
                        .frame(height: 220)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedMetric.color.opacity(0.05))
                        )
                        .padding(.horizontal, 20)
                    } else {
                        Chart {
                            // 数据曲线
                            ForEach(chartData, id: \.date) { item in
                                LineMark(
                                    x: .value("日期", item.date),
                                    y: .value(selectedMetric.rawValue, item.value)
                                )
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [selectedMetric.color, selectedMetric.color.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                                
                                AreaMark(
                                    x: .value("日期", item.date),
                                    y: .value(selectedMetric.rawValue, item.value)
                                )
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [selectedMetric.color.opacity(0.3), selectedMetric.color.opacity(0.05)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                
                                PointMark(
                                    x: .value("日期", item.date),
                                    y: .value(selectedMetric.rawValue, item.value)
                                )
                                .foregroundStyle(selectedMetric.color)
                                .symbolSize(40)
                            }
                            
                            // 目标线（虚线）
                            if let targetValue = currentTargetValue {
                                RuleMark(y: .value("目标", targetValue))
                                    .foregroundStyle(.orange)
                                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                                    .annotation(position: .topTrailing) {
                                        Text("目标: \(formatValue(targetValue))")
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(.orange.opacity(0.1))
                                            .foregroundColor(.orange)
                                            .cornerRadius(8)
                                    }
                            }
                        }
                        .frame(height: 220)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day)) { value in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                    .foregroundStyle(.gray.opacity(0.3))
                                AxisValueLabel(format: .dateTime.month().day())
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .chartYAxis {
                            AxisMarks(values: .automatic(desiredCount: 5)) { value in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                    .foregroundStyle(.gray.opacity(0.3))
                                AxisValueLabel()
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .chartYScale(domain: yAxisRange)
                        .chartPlotStyle { plotArea in
                            plotArea
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                        }
                    }
                }
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                )
                .padding(.horizontal, 16)
                
                Spacer(minLength: 20)
            }
            .padding(.top, 10)
        }
        .background(
            LinearGradient(
                colors: [Color(.systemGroupedBackground), Color(.systemBackground).opacity(0.5)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .onAppear {
            loadData()
            loadUserProfile()
        }
        .onChange(of: selectedMetric) { _, _ in
            // 切换指标时不需要重新加载数据，只需要重新计算chartData
        }
        .onChange(of: dateRange) { _, _ in
            // 切换时间范围时不需要重新加载数据，只需要重新计算chartData
        }
    }
    
    // 智能Y轴范围计算
    private var yAxisRange: ClosedRange<Double> {
        guard !chartData.isEmpty else { return 0...100 }
        
        let values = chartData.map { $0.value }
        let minValue = values.min()!
        let maxValue = values.max()!
        
        // 如果有目标值，考虑目标值在范围内
        var rangeMin = minValue
        var rangeMax = maxValue
        
        if let targetValue = currentTargetValue {
            rangeMin = min(rangeMin, targetValue)
            rangeMax = max(rangeMax, targetValue)
        }
        
        // 计算缓冲区（范围的10-20%）
        let range = rangeMax - rangeMin
        let buffer = max(range * 0.15, getMinimumBuffer()) // 至少保持最小缓冲
        
        let finalMin = max(rangeMin - buffer, getAbsoluteMinimum())
        let finalMax = rangeMax + buffer
        
        return finalMin...finalMax
    }
    
    // 获取当前指标的目标值
    private var currentTargetValue: Double? {
        guard let profile = userProfile else { return nil }
        
        switch selectedMetric {
        case .weight: return profile.targetWeight
        case .bodyFat: return profile.targetBodyFat
        case .waistline: return profile.targetWaistline
        case .cardio, .strength, .hiit: return nil // 运动类型暂不支持目标
        }
    }
    
    // 获取最小缓冲值
    private func getMinimumBuffer() -> Double {
        switch selectedMetric {
        case .weight: return 2.0 // kg
        case .bodyFat: return 1.0 // %
        case .waistline: return 2.0 // cm
        case .cardio, .strength, .hiit: return 5.0 // 分钟
        }
    }
    
    // 获取绝对最小值
    private func getAbsoluteMinimum() -> Double {
        switch selectedMetric {
        case .weight: return 40.0
        case .bodyFat: return 5.0
        case .waistline: return 50.0
        case .cardio, .strength, .hiit: return 0.0
        }
    }
    
    private var chartData: [ChartDataPoint] {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -dateRange.days, to: endDate) ?? endDate
        
        switch selectedMetric {
        case .weight, .bodyFat, .waistline:
            return bodyDataList
                .filter { $0.date >= startDate && $0.date <= endDate }
                .compactMap { data -> ChartDataPoint? in
                    let value: Double?
                    let minValue: Double
                    
                    switch selectedMetric {
                    case .weight: 
                        value = data.weight
                        minValue = 40.0
                    case .bodyFat: 
                        value = data.bodyFat
                        minValue = 8.0
                    case .waistline: 
                        value = data.waistline
                        minValue = 60.0
                    default: 
                        value = nil
                        minValue = 0.0
                    }
                    
                    guard let val = value, val > minValue else { return nil }
                    return ChartDataPoint(date: data.date, value: val)
                }
                .sorted { $0.date < $1.date }
                
        case .cardio, .strength, .hiit:
            let exerciseType: ExerciseType
            switch selectedMetric {
            case .cardio: exerciseType = .cardio
            case .strength: exerciseType = .strength
            case .hiit: exerciseType = .hiit
            default: exerciseType = .cardio
            }
            
            return exerciseDataList
                .filter { $0.date >= startDate && $0.date <= endDate && $0.exerciseType == exerciseType }
                .compactMap { data -> ChartDataPoint? in
                    guard let duration = data.duration, duration > 0 else { return nil }
                    return ChartDataPoint(date: data.date, value: duration)
                }
                .sorted { $0.date < $1.date }
        }
    }
    
    private func loadData() {
        // 加载身体数据
        let bodyDataDescriptor = FetchDescriptor<BodyData>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        do {
            bodyDataList = try modelContext.fetch(bodyDataDescriptor)
        } catch {
            print("加载身体数据失败: \(error)")
            bodyDataList = []
        }
        
        // 加载锻炼数据
        let exerciseDataDescriptor = FetchDescriptor<ExerciseData>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        do {
            exerciseDataList = try modelContext.fetch(exerciseDataDescriptor)
        } catch {
            print("加载锻炼数据失败: \(error)")
            exerciseDataList = []
        }
    }
    
    private func loadUserProfile() {
        let profileDescriptor = FetchDescriptor<UserProfile>()
        
        do {
            let profiles = try modelContext.fetch(profileDescriptor)
            userProfile = profiles.first
        } catch {
            print("加载用户资料失败: \(error)")
            userProfile = nil
        }
    }
    
    private func formatValue(_ value: Double) -> String {
        switch selectedMetric {
        case .weight, .bodyFat, .waistline:
            return String(format: "%.1f", value)
        case .cardio, .strength, .hiit:
            return String(format: "%.0f", value)
        }
    }
    
    private func iconForMetric(_ metric: MetricType) -> String {
        switch metric {
        case .weight: return "scalemass"
        case .bodyFat: return "percent"
        case .waistline: return "ruler"
        case .cardio: return "heart.fill"
        case .strength: return "dumbbell.fill"
        case .hiit: return "bolt.fill"
        }
    }
}

struct ChartDataPoint {
    let date: Date
    let value: Double
}

#Preview {
    TrendView()
        .modelContainer(for: [BodyData.self, ExerciseData.self, UserProfile.self], inMemory: true)
} 