//
//  SliderInputView.swift
//  MakeMeBetter
//
//  Created by watchman on 2025/5/28.
//

import SwiftUI

// 触觉反馈工具类
class HapticFeedback {
    static let shared = HapticFeedback()
    
    private init() {}
    
    func lightImpact() {
        #if os(iOS)
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        #endif
    }
    
    func mediumImpact() {
        #if os(iOS)
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        #endif
    }
}

struct SliderInputView: View {
    let title: String
    let unit: String
    @Binding var value: Double?
    let range: ClosedRange<Double>
    let step: Double
    let displayValue: String?
    let yesterdayValue: Double? // 昨天的数据
    let smartRange: ClosedRange<Double>? // 智能范围
    
    @State private var sliderValue: Double
    @State private var lastFeedbackValue: Double = 0
    @State private var showingTextInput = false
    @State private var textInput = ""
    
    init(title: String, unit: String, value: Binding<Double?>, range: ClosedRange<Double>, step: Double = 0.1, displayValue: String? = nil, yesterdayValue: Double? = nil, smartRange: ClosedRange<Double>? = nil) {
        self.title = title
        self.unit = unit
        self._value = value
        self.range = range
        self.step = step
        self.displayValue = displayValue
        self.yesterdayValue = yesterdayValue
        self.smartRange = smartRange
        self._sliderValue = State(initialValue: value.wrappedValue ?? range.lowerBound)
    }
    
    // 使用智能范围或默认范围
    private var effectiveRange: ClosedRange<Double> {
        return smartRange ?? range
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                if !title.isEmpty {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(width: 40, alignment: .leading)
                }
                
                Slider(value: $sliderValue, in: effectiveRange, step: step)
                    .accentColor(.blue)
                    .onChange(of: sliderValue) { oldValue, newValue in
                        if oldValue != newValue {
                            value = newValue
                            
                            // 添加触觉反馈
                            // 只有当值变化超过一定阈值时才触发反馈，避免过于频繁
                            let threshold = step >= 1.0 ? 1.0 : 0.5
                            if abs(newValue - lastFeedbackValue) >= threshold {
                                HapticFeedback.shared.lightImpact()
                                lastFeedbackValue = newValue
                            }
                        }
                    }
                
                // 点击数值可以直接编辑
                Button(action: {
                    textInput = value != nil ? formatValue(value!) : ""
                    showingTextInput = true
                }) {
                    if let displayValue = displayValue {
                        Text(displayValue + (displayValue != "N/A" ? unit : ""))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(displayValue != "N/A" ? .blue : .secondary)
                            .frame(width: 60, alignment: .trailing)
                    } else {
                        Text(formatValue(sliderValue) + unit)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.blue)
                            .frame(width: 60, alignment: .trailing)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // 显示昨天的数据和变化趋势
            if let yesterdayValue = yesterdayValue, let currentValue = value {
                let change = currentValue - yesterdayValue
                let changeText = change >= 0 ? "+\(formatValue(abs(change)))" : "-\(formatValue(abs(change)))"
                let changeColor: Color = change > 0 ? .red : (change < 0 ? .green : .gray)
                
                HStack(spacing: 4) {
                    Spacer()
                    Text("昨天: \(formatValue(yesterdayValue))\(unit)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("(\(changeText))")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(changeColor)
                    
                    Image(systemName: change > 0 ? "arrow.up" : (change < 0 ? "arrow.down" : "minus"))
                        .font(.caption)
                        .foregroundColor(changeColor)
                }
            }
        }
        .onAppear {
            if let currentValue = value {
                sliderValue = currentValue
                lastFeedbackValue = currentValue
            }
        }
        .onChange(of: value) { oldValue, newValue in
            if let newValue = newValue, oldValue != newValue, abs(sliderValue - newValue) > 0.01 {
                sliderValue = newValue
                lastFeedbackValue = newValue
            }
        }
        .alert("输入\(title)", isPresented: $showingTextInput) {
            TextField("\(title)", text: $textInput)
                .keyboardType(.decimalPad)
            
            Button("确定") {
                if let inputValue = Double(textInput), effectiveRange.contains(inputValue) {
                    value = inputValue
                    sliderValue = inputValue
                    HapticFeedback.shared.mediumImpact()
                }
            }
            
            Button("取消", role: .cancel) {}
        } message: {
            Text("请输入\(formatValue(effectiveRange.lowerBound))到\(formatValue(effectiveRange.upperBound))之间的值")
        }
    }
    
    private func formatValue(_ value: Double) -> String {
        if step >= 1.0 {
            return String(format: "%.0f", value)
        } else {
            return String(format: "%.1f", value)
        }
    }
}

#Preview {
    @Previewable @State var weight: Double? = 65.0
    return VStack(spacing: 20) {
        SliderInputView(
            title: "体重",
            unit: "kg",
            value: $weight,
            range: 40.0...120.0,
            yesterdayValue: 64.5,
            smartRange: 60.0...75.0
        )
        
        SliderInputView(
            title: "腰围",
            unit: "cm",
            value: $weight,
            range: 60.0...120.0
        )
    }
    .padding()
} 