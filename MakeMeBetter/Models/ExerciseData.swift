//
//  ExerciseData.swift
//  MakeMeBetter
//
//  Created by watchman on 2025/5/28.
//

import Foundation
import SwiftData

enum ExerciseType: String, CaseIterable, Codable {
    case cardio = "有氧"
    case strength = "力量"
    case hiit = "HIIT"
}

@Model
final class ExerciseData {
    var date: Date
    var type: String // ExerciseType的rawValue
    var duration: Double? // 时长，单位：分钟
    var intensity: Double? // 强度，1-10级
    var calories: Double? // 消耗卡路里
    var notes: String? // 备注
    var createdAt: Date
    var updatedAt: Date
    
    init(date: Date = Date(), type: ExerciseType, duration: Double? = nil, intensity: Double? = nil, calories: Double? = nil, notes: String? = nil) {
        self.date = Calendar.current.startOfDay(for: date)
        self.type = type.rawValue
        self.duration = duration
        self.intensity = intensity
        self.calories = calories
        self.notes = notes
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    var exerciseType: ExerciseType {
        return ExerciseType(rawValue: type) ?? .cardio
    }
    
    func updateData(duration: Double? = nil, intensity: Double? = nil, calories: Double? = nil, notes: String? = nil) {
        if let duration = duration { self.duration = duration }
        if let intensity = intensity { self.intensity = intensity }
        if let calories = calories { self.calories = calories }
        if let notes = notes { self.notes = notes }
        self.updatedAt = Date()
    }
} 