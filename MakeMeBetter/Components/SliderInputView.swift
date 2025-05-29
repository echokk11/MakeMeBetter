//
//  SliderInputView.swift
//  MakeMeBetter
//
//  Created by watchman on 2025/5/28.
//

import SwiftUI

struct SliderInputView: View {
    let title: String
    let unit: String
    @Binding var value: Double?
    let range: ClosedRange<Double>
    let step: Double
    let displayValue: String?
    let isDisabled: Bool
    
    @State private var sliderValue: Double
    
    init(title: String, unit: String, value: Binding<Double?>, range: ClosedRange<Double>, step: Double = 0.1, displayValue: String? = nil, isDisabled: Bool = false) {
        self.title = title
        self.unit = unit
        self._value = value
        self.range = range
        self.step = step
        self.displayValue = displayValue
        self.isDisabled = isDisabled
        self._sliderValue = State(initialValue: value.wrappedValue ?? range.lowerBound)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            if !title.isEmpty {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isDisabled ? .secondary : .primary)
                    .frame(width: 40, alignment: .leading)
            }
            
            Slider(value: $sliderValue, in: range, step: step)
                .accentColor(isDisabled ? .gray : .blue)
                .disabled(isDisabled)
                .onChange(of: sliderValue) { newValue in
                    if !isDisabled {
                        value = newValue
                    }
                }
            
            if let displayValue = displayValue {
                Text(displayValue + (displayValue != "N/A" ? unit : ""))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isDisabled ? .secondary : (displayValue != "N/A" ? .blue : .secondary))
                    .frame(width: 60, alignment: .trailing)
            } else {
                Text(formatValue(sliderValue) + unit)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isDisabled ? .secondary : .blue)
                    .frame(width: 60, alignment: .trailing)
            }
        }
        .opacity(isDisabled ? 0.6 : 1.0)
        .onAppear {
            if let currentValue = value {
                sliderValue = currentValue
            }
        }
        .onChange(of: value) { newValue in
            if let newValue = newValue {
                sliderValue = newValue
            }
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
    @State var weight: Double? = 65.0
    return SliderInputView(
        title: "体重",
        unit: "kg",
        value: $weight,
        range: 30.0...150.0
    )
    .padding()
} 