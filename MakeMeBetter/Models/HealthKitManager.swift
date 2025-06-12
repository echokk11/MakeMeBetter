//
//  HealthKitManager.swift
//  MakeMeBetter
//
//  Created by watchman on 2025/5/28.
//

import Foundation
import HealthKit

@MainActor
class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    private let healthStore = HKHealthStore()
    
    @Published var isAuthorized = false
    @Published var authorizationError: String?
    
    private init() {}
    
    // MARK: - 权限管理
    
    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            authorizationError = "HealthKit在此设备上不可用"
            return
        }
        
        // 定义需要读取的数据类型
        let readTypes: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,        // 体重
            HKObjectType.quantityType(forIdentifier: .height)!,          // 身高
            HKObjectType.quantityType(forIdentifier: .bodyFatPercentage)!, // 体脂率
            HKObjectType.quantityType(forIdentifier: .waistCircumference)! // 腰围
        ]
        
        // 定义需要写入的数据类型（只有腰围）
        let writeTypes: Set<HKSampleType> = [
            HKObjectType.quantityType(forIdentifier: .waistCircumference)! // 腰围
        ]
        
        do {
            try await healthStore.requestAuthorization(toShare: writeTypes, read: readTypes)
            isAuthorized = true
        } catch {
            isAuthorized = false
            authorizationError = "请求权限时发生错误: \(error.localizedDescription)"
        }
    }
    
    // MARK: - 读取数据
    
    func fetchLatestBodyWeight() async -> Double? {
        return await fetchLatestQuantity(for: .bodyMass, unit: .gramUnit(with: .kilo))
    }
    
    func fetchLatestHeight() async -> Double? {
        return await fetchLatestQuantity(for: .height, unit: .meterUnit(with: .centi))
    }
    
    func fetchLatestBodyFatPercentage() async -> Double? {
        return await fetchLatestQuantity(for: .bodyFatPercentage, unit: .percent())
    }
    
    func fetchLatestWaistCircumference() async -> Double? {
        return await fetchLatestQuantity(for: .waistCircumference, unit: .meterUnit(with: .centi))
    }
    
    private func fetchLatestQuantity(for identifier: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double? {
        guard let quantityType = HKObjectType.quantityType(forIdentifier: identifier) else {
            return nil
        }
        
        // 创建查询，获取最近30天的数据
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -30, to: endDate) ?? endDate
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: quantityType,
                predicate: predicate,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    print("获取\(identifier.rawValue)数据失败: \(error.localizedDescription)")
                    continuation.resume(returning: nil)
                    return
                }
                
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let value = sample.quantity.doubleValue(for: unit)
                continuation.resume(returning: value)
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - 写入数据
    
    func saveWaistCircumference(_ value: Double) async -> Bool {
        guard let waistType = HKObjectType.quantityType(forIdentifier: .waistCircumference) else {
            return false
        }
        
        let quantity = HKQuantity(unit: .meterUnit(with: .centi), doubleValue: value)
        let sample = HKQuantitySample(
            type: waistType,
            quantity: quantity,
            start: Date(),
            end: Date()
        )
        
        return await withCheckedContinuation { continuation in
            healthStore.save(sample) { success, error in
                if let error = error {
                    print("保存腰围数据失败: \(error.localizedDescription)")
                }
                continuation.resume(returning: success)
            }
        }
    }
    
    func saveWaistCircumferenceForDate(_ value: Double, date: Date) async -> Bool {
        print("开始保存腰围数据: \(value)cm，日期: \(date)")
        
        // 先检查是否已有当天的数据
        let existingValue = await fetchWaistCircumferenceForDate(date)
        
        // 只有当新值与现有值不同时才删除旧数据
        if let existing = existingValue, abs(existing - value) > 0.1 {
            print("发现当天已有腰围数据: \(existing)cm，将删除后保存新值: \(value)cm")
            let deleteSuccess = await deleteWaistCircumferenceForDate(date)
            if !deleteSuccess {
                print("删除当天旧腰围数据失败，但继续保存新数据")
            }
        } else if existingValue == nil {
            print("当天没有腰围数据，直接保存新值")
        } else {
            print("新值与现有值相同，跳过保存")
            return true
        }
        
        guard let waistType = HKObjectType.quantityType(forIdentifier: .waistCircumference) else {
            print("无法获取腰围数据类型")
            return false
        }
        
        // 确保使用当天的开始时间
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        let quantity = HKQuantity(unit: .meterUnit(with: .centi), doubleValue: value)
        let sample = HKQuantitySample(
            type: waistType,
            quantity: quantity,
            start: startOfDay,
            end: startOfDay
        )
        
        return await withCheckedContinuation { continuation in
            healthStore.save(sample) { success, error in
                if let error = error {
                    print("保存腰围数据失败: \(error.localizedDescription)")
                } else if success {
                    print("成功保存腰围数据到Apple Health: \(value)cm，日期: \(startOfDay)")
                } else {
                    print("保存腰围数据失败，但没有错误信息")
                }
                continuation.resume(returning: success)
            }
        }
    }
    
    // MARK: - 删除数据
    
    private func deleteWaistCircumferenceForDate(_ date: Date) async -> Bool {
        guard let waistType = HKObjectType.quantityType(forIdentifier: .waistCircumference) else {
            return false
        }
        
        // 创建查询，获取指定日期的所有腰围数据
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: waistType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { [weak self] _, samples, error in
                guard let self = self else {
                    continuation.resume(returning: false)
                    return
                }
                
                if let error = error {
                    print("查询当天腰围数据失败: \(error.localizedDescription)")
                    continuation.resume(returning: false)
                    return
                }
                
                guard let samples = samples, !samples.isEmpty else {
                    // 没有数据需要删除，返回成功
                    continuation.resume(returning: true)
                    return
                }
                
                // 删除找到的所有样本
                self.healthStore.delete(samples) { success, error in
                    if let error = error {
                        print("删除当天腰围数据失败: \(error.localizedDescription)")
                    } else {
                        print("成功删除当天的\(samples.count)条腰围数据")
                    }
                    continuation.resume(returning: success)
                }
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - 批量获取数据
    
    func fetchAllLatestData() async -> (weight: Double?, height: Double?, bodyFat: Double?, waist: Double?) {
        async let weight = fetchLatestBodyWeight()
        async let height = fetchLatestHeight()
        async let bodyFat = fetchLatestBodyFatPercentage()
        async let waist = fetchLatestWaistCircumference()
        
        return await (weight, height, bodyFat, waist)
    }
    
    // MARK: - 按日期读取数据
    
    func fetchBodyWeightForDate(_ date: Date) async -> Double? {
        return await fetchQuantityForDate(for: .bodyMass, unit: .gramUnit(with: .kilo), date: date)
    }
    
    func fetchHeightForDate(_ date: Date) async -> Double? {
        return await fetchQuantityForDate(for: .height, unit: .meterUnit(with: .centi), date: date)
    }
    
    func fetchBodyFatPercentageForDate(_ date: Date) async -> Double? {
        return await fetchQuantityForDate(for: .bodyFatPercentage, unit: .percent(), date: date)
    }
    
    func fetchWaistCircumferenceForDate(_ date: Date) async -> Double? {
        return await fetchQuantityForDate(for: .waistCircumference, unit: .meterUnit(with: .centi), date: date)
    }
    
    private func fetchQuantityForDate(for identifier: HKQuantityTypeIdentifier, unit: HKUnit, date: Date) async -> Double? {
        guard let quantityType = HKObjectType.quantityType(forIdentifier: identifier) else {
            return nil
        }
        
        // 创建查询，获取指定日期的数据
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: quantityType,
                predicate: predicate,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    print("获取\(identifier.rawValue)数据失败: \(error.localizedDescription)")
                    continuation.resume(returning: nil)
                    return
                }
                
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let value = sample.quantity.doubleValue(for: unit)
                continuation.resume(returning: value)
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - 按日期批量获取数据
    
    func fetchAllDataForDate(_ date: Date) async -> (weight: Double?, height: Double?, bodyFat: Double?, waist: Double?) {
        async let weight = fetchBodyWeightForDate(date)
        async let height = fetchHeightForDate(date)
        async let bodyFat = fetchBodyFatPercentageForDate(date)
        async let waist = fetchWaistCircumferenceForDate(date)
        
        return await (weight, height, bodyFat, waist)
    }
    
    // MARK: - 测试和调试
    
    func testHealthKitConnection() async -> String {
        var result = "HealthKit测试结果:\n"
        
        // 检查设备支持
        if !HKHealthStore.isHealthDataAvailable() {
            result += "❌ 设备不支持HealthKit\n"
            return result
        }
        result += "✅ 设备支持HealthKit\n"
        
        // 检查权限
        guard let waistType = HKObjectType.quantityType(forIdentifier: .waistCircumference) else {
            result += "❌ 无法获取腰围数据类型\n"
            return result
        }
        
        let authStatus = healthStore.authorizationStatus(for: waistType)
        switch authStatus {
        case .notDetermined:
            result += "⚠️ 权限未确定，需要请求权限\n"
        case .sharingDenied:
            result += "❌ 用户拒绝了写入权限\n"
        case .sharingAuthorized:
            result += "✅ 已获得写入权限\n"
        @unknown default:
            result += "❓ 未知权限状态\n"
        }
        
        // 测试保存功能
        if authStatus == .sharingAuthorized {
            result += "正在测试保存功能...\n"
            let testValue = 80.0
            let success = await saveWaistCircumferenceForDate(testValue, date: Date())
            if success {
                result += "✅ 测试保存成功\n"
                
                // 测试读取功能
                let readValue = await fetchWaistCircumferenceForDate(Date())
                if let value = readValue, abs(value - testValue) < 0.1 {
                    result += "✅ 测试读取成功，值: \(value)cm\n"
                } else {
                    result += "⚠️ 测试读取失败或值不匹配\n"
                }
            } else {
                result += "❌ 测试保存失败\n"
            }
        }
        
        return result
    }
} 