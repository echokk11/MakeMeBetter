//
//  UserProfile.swift
//  MakeMeBetter
//
//  Created by watchman on 2025/5/28.
//

import Foundation
import SwiftData

@Model
final class UserProfile {
    var gender: String // "男" 或 "女"
    var height: Double // 身高，单位：cm
    var birthDate: Date // 出生日期
    
    // 目标设定
    var targetWeight: Double? // 目标体重，单位：kg
    var targetBodyFat: Double? // 目标体脂，单位：%
    var targetWaistline: Double? // 目标腰围，单位：cm
    
    var createdAt: Date
    var updatedAt: Date
    
    init(gender: String = "男", height: Double = 170.0, birthDate: Date? = nil) {
        self.gender = gender
        self.height = height
        self.birthDate = birthDate ?? Calendar.current.date(from: DateComponents(year: 1990, month: 1, day: 1)) ?? Date()
        self.targetWeight = nil
        self.targetBodyFat = nil
        self.targetWaistline = nil
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    func updateProfile(gender: String? = nil, height: Double? = nil, birthDate: Date? = nil) {
        if let gender = gender { self.gender = gender }
        if let height = height { self.height = height }
        if let birthDate = birthDate { self.birthDate = birthDate }
        self.updatedAt = Date()
    }
    
    func updateTargets(weight: Double? = nil, bodyFat: Double? = nil, waistline: Double? = nil) {
        if let weight = weight { self.targetWeight = weight }
        if let bodyFat = bodyFat { self.targetBodyFat = bodyFat }
        if let waistline = waistline { self.targetWaistline = waistline }
        self.updatedAt = Date()
    }
} 