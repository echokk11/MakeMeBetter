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
                        Chart(chartData, id: \.date) { item in
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
                            AxisMarks { value in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                    .foregroundStyle(.gray.opacity(0.3))
                                AxisValueLabel()
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            }
                        }
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
        }
        .onChange(of: selectedMetric) { _, _ in
            // 切换指标时不需要重新加载数据，只需要重新计算chartData
        }
        .onChange(of: dateRange) { _, _ in
            // 切换时间范围时不需要重新加载数据，只需要重新计算chartData
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
        .modelContainer(for: [BodyData.self, ExerciseData.self], inMemory: true)
} 