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
        guard let waistType = HKObjectType.quantityType(forIdentifier: .waistCircumference) else {
            return false
        }
        
        let quantity = HKQuantity(unit: .meterUnit(with: .centi), doubleValue: value)
        let sample = HKQuantitySample(
            type: waistType,
            quantity: quantity,
            start: date,
            end: date
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
} 