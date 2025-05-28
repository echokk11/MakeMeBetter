//
//  BodyData.swift
//  MakeMeBetter
//
//  Created by watchman on 2025/5/28.
//

import Foundation
import SwiftData

@Model
final class BodyData {
    var date: Date
    var weight: Double? // 体重，单位：kg
    var bodyFat: Double? // 体脂，单位：%
    var waistline: Double? // 腰围，单位：cm
    var createdAt: Date
    var updatedAt: Date
    
    init(date: Date = Date(), weight: Double? = nil, bodyFat: Double? = nil, waistline: Double? = nil) {
        self.date = Calendar.current.startOfDay(for: date)
        self.weight = weight
        self.bodyFat = bodyFat
        self.waistline = waistline
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    func updateData(weight: Double? = nil, bodyFat: Double? = nil, waistline: Double? = nil) {
        if let weight = weight { self.weight = weight }
        if let bodyFat = bodyFat { self.bodyFat = bodyFat }
        if let waistline = waistline { self.waistline = waistline }
        self.updatedAt = Date()
    }
} 