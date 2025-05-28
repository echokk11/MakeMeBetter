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
                    range: 40.0...120.0
                )
                
                SliderInputView(
                    title: "体脂",
                    unit: "%",
                    value: $bodyFat,
                    range: 8.0...35.0
                )
                
                SliderInputView(
                    title: "腰围",
                    unit: "cm",
                    value: $waistline,
                    range: 60.0...120.0
                )
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 12)
        .onAppear {
            loadData()
        }
        .onChange(of: bodyData) { _ in
            loadData()
        }
        .onChange(of: weight) { _ in 
            saveData()
        }
        .onChange(of: bodyFat) { _ in saveData() }
        .onChange(of: waistline) { _ in saveData() }
    }
    
    private func loadData() {
        weight = bodyData?.weight
        bodyFat = bodyData?.bodyFat
        waistline = bodyData?.waistline
    }
    
    private func saveData() {
        if bodyData == nil {
            let newBodyData = BodyData(date: selectedDate)
            modelContext.insert(newBodyData)
            bodyData = newBodyData
        }
        
        bodyData?.updateData(weight: weight, bodyFat: bodyFat, waistline: waistline)
        
        do {
            try modelContext.save()
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
}

#Preview {
    @State var bodyData: BodyData? = nil
    return BodyDataSection(bodyData: $bodyData, selectedDate: Date())
        .modelContainer(for: BodyData.self, inMemory: true)
        .padding()
} 