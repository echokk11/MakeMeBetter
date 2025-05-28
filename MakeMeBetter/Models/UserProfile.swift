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
    var birthDate: Date
    var height: Double // 身高，单位：cm
    var avatar: String? // 头像图标名称
    var createdAt: Date
    var updatedAt: Date
    
    init(gender: String = "男", birthDate: Date = Date(), height: Double = 170.0) {
        self.gender = gender
        self.birthDate = birthDate
        self.height = height
        self.avatar = "person.circle.fill"
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    func updateProfile(gender: String? = nil, birthDate: Date? = nil, height: Double? = nil) {
        if let gender = gender { self.gender = gender }
        if let birthDate = birthDate { self.birthDate = birthDate }
        if let height = height { self.height = height }
        self.updatedAt = Date()
    }
} 