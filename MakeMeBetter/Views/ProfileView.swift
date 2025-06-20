//
//  ProfileView.swift
//  MakeMeBetter
//
//  Created by watchman on 2025/5/28.
//

import SwiftUI
import SwiftData
import PhotosUI

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appStateManager: AppStateManager
    @Query private var profiles: [UserProfile]

    
    @State private var selectedGender: String = "男"
    @State private var birthDate = Calendar.current.date(from: DateComponents(year: 1990, month: 1, day: 1)) ?? Date()
    @State private var height: Double? = 170.0
    @State private var showingHealthSync = false
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var avatarImage: UIImage? = nil
    @State private var showingClearDataAlert = false
    
    // 目标设定相关状态
    @State private var targetWeight: Double?
    @State private var targetBodyFat: Double?
    @State private var targetWaistline: Double?

    
    private let genders = ["男", "女"]
    
    var currentProfile: UserProfile? {
        profiles.first
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // 顶部安全区域
                    Color.clear
                        .frame(height: 1)
                    
                    VStack(spacing: 24) {
                        avatarSelectionSection
                        basicInfoSection
                        targetsSection
                        clearDataSection
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 100)
                }
            }
            .background(
                LinearGradient(
                    colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .navigationBarHidden(true)
        }
        .onAppear {
            loadProfile()
            loadAvatarFromLocal()
        }
    }
    
    private var avatarSelectionSection: some View {
        PhotosPicker(
            selection: $selectedPhoto,
            matching: .images,
            photoLibrary: .shared()
        ) {
            if let avatarImage = avatarImage {
                Image(uiImage: avatarImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.gray.opacity(0.6))
            }
        }
        .padding(.top, 20)
        .onChange(of: selectedPhoto) { _, newPhoto in
            Task {
                if let newPhoto = newPhoto {
                    if let data = try? await newPhoto.loadTransferable(type: Data.self) {
                        if let uiImage = UIImage(data: data) {
                            avatarImage = uiImage
                            saveAvatarToLocal(uiImage)
                        }
                    }
                }
            }
        }
    }
    
    // HealthKit功能已移除，采用纯本地存储
    
    private var basicInfoSection: some View {
        VStack(spacing: 20) {
            // 性别选择
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: selectedGender == "女" ? "person.circle.fill" : "person.circle")
                        .foregroundColor(selectedGender == "女" ? .pink : .blue)
                        .font(.title2)
                    Text("性别")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                }
                
                HStack(spacing: 12) {
                    ForEach(genders, id: \.self) { gender in
                        Button(action: {
                            selectedGender = gender
                            saveProfile()
                            HapticFeedback.shared.mediumImpact()
                        }) {
                            Text(gender)
                                .font(.body)
                                .foregroundColor(selectedGender == gender ? .white : .primary)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(selectedGender == gender ? 
                                              (gender == "女" ? .pink : .blue) : 
                                              .gray.opacity(0.2))
                                )
                        }
                    }
                    Spacer()
                }
            }
            
            // 出生日期
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.orange)
                        .font(.title2)
                    Text("出生日期")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    Text("\(calculateAge())岁")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    DatePicker("", selection: $birthDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .fixedSize()
                        .onChange(of: birthDate) { _, _ in
                            saveProfile()
                        }
                    Spacer()
                }
            }
            
            // 身高
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "ruler")
                        .foregroundColor(.green)
                        .font(.title2)
                    Text("身高")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    Text("\(height ?? 0, specifier: "%.1f") cm")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                SliderInputView(
                    title: "",
                    unit: "cm",
                    value: $height,
                    range: 120...220,
                    step: 0.1
                )
                .onChange(of: height) { _, _ in
                    saveProfile()
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    private var targetsSection: some View {
        VStack(spacing: 20) {
            // 标题
            HStack {
                Image(systemName: "target")
                    .foregroundColor(.orange)
                    .font(.title2)
                Text("目标设定")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            VStack(spacing: 16) {
                // 目标体重
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "scalemass")
                            .foregroundColor(.blue)
                            .font(.body)
                        Text("目标体重")
                            .font(.body)
                            .foregroundColor(.primary)
                        Spacer()
                        if let target = targetWeight {
                            Text("\(target, specifier: "%.1f") kg")
                                .font(.body)
                                .foregroundColor(.secondary)
                        } else {
                            Text("未设置")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    SliderInputView(
                        title: "",
                        unit: "kg",
                        value: $targetWeight,
                        range: 40.0...120.0,
                        displayValue: targetWeight != nil ? String(format: "%.1f", targetWeight!) : "点击设置"
                    )
                    .onChange(of: targetWeight) { _, _ in
                        saveTargets()
                    }
                }
                
                // 目标体脂
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "percent")
                            .foregroundColor(.green)
                            .font(.body)
                        Text("目标体脂")
                            .font(.body)
                            .foregroundColor(.primary)
                        Spacer()
                        if let target = targetBodyFat {
                            Text("\(target, specifier: "%.1f") %")
                                .font(.body)
                                .foregroundColor(.secondary)
                        } else {
                            Text("未设置")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    SliderInputView(
                        title: "",
                        unit: "%",
                        value: $targetBodyFat,
                        range: 8.0...35.0,
                        displayValue: targetBodyFat != nil ? String(format: "%.1f", targetBodyFat!) : "点击设置"
                    )
                    .onChange(of: targetBodyFat) { _, _ in
                        saveTargets()
                    }
                }
                
                // 目标腰围
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "ruler")
                            .foregroundColor(.purple)
                            .font(.body)
                        Text("目标腰围")
                            .font(.body)
                            .foregroundColor(.primary)
                        Spacer()
                        if let target = targetWaistline {
                            Text("\(target, specifier: "%.1f") cm")
                                .font(.body)
                                .foregroundColor(.secondary)
                        } else {
                            Text("未设置")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    SliderInputView(
                        title: "",
                        unit: "cm",
                        value: $targetWaistline,
                        range: 60.0...120.0,
                        displayValue: targetWaistline != nil ? String(format: "%.1f", targetWaistline!) : "点击设置"
                    )
                    .onChange(of: targetWaistline) { _, _ in
                        saveTargets()
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    private var clearDataSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "trash.circle")
                    .foregroundColor(.red)
                    .font(.title2)
                Text("数据管理")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            Button(action: {
                showingClearDataAlert = true
            }) {
                HStack {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 16, weight: .medium))
                    Text("清空所有数据")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.red)
                )
            }
            .alert("确认清空数据", isPresented: $showingClearDataAlert) {
                Button("取消", role: .cancel) { }
                Button("确认清空", role: .destructive) {
                    clearAllData()
                }
            } message: {
                Text("此操作将永久删除所有本地记录的身体数据和锻炼数据，不可恢复。Apple Health中的数据不会受到影响。")
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    private func loadProfile() {
        if let profile = currentProfile {
            selectedGender = profile.gender
            height = profile.height
            birthDate = profile.birthDate
            
            // 加载目标设定
            targetWeight = profile.targetWeight
            targetBodyFat = profile.targetBodyFat
            targetWaistline = profile.targetWaistline
        }
    }
    
    private func saveProfile() {
        if let existingProfile = currentProfile {
            existingProfile.updateProfile(
                gender: selectedGender,
                height: height,
                birthDate: birthDate
            )
        } else {
            let newProfile = UserProfile(
                gender: selectedGender,
                height: height ?? 170.0,
                birthDate: birthDate
            )
            modelContext.insert(newProfile)
        }
        
        try? modelContext.save()
        print("用户资料已保存: 性别=\(selectedGender), 身高=\(height?.description ?? "未设置"), 出生日期=\(birthDate)")
    }
    
    private func saveTargets() {
        if let existingProfile = currentProfile {
            existingProfile.updateTargets(
                weight: targetWeight,
                bodyFat: targetBodyFat,
                waistline: targetWaistline
            )
        } else {
            let newProfile = UserProfile(
                gender: selectedGender,
                height: height ?? 170.0,
                birthDate: birthDate
            )
            newProfile.updateTargets(
                weight: targetWeight,
                bodyFat: targetBodyFat,
                waistline: targetWaistline
            )
            modelContext.insert(newProfile)
        }
        
        try? modelContext.save()
        print("目标设定已保存: 体重=\(targetWeight?.description ?? "未设置"), 体脂=\(targetBodyFat?.description ?? "未设置"), 腰围=\(targetWaistline?.description ?? "未设置")")
    }
    
    private func saveAvatarToLocal(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let avatarURL = documentsPath.appendingPathComponent("avatar.jpg")
        
        try? data.write(to: avatarURL)
    }
    
    private func loadAvatarFromLocal() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let avatarURL = documentsPath.appendingPathComponent("avatar.jpg")
        
        if let data = try? Data(contentsOf: avatarURL),
           let image = UIImage(data: data) {
            avatarImage = image
        }
    }
    
    private func clearAllData() {
        do {
            // 清空所有身体数据
            let bodyDataDescriptor = FetchDescriptor<BodyData>()
            let allBodyData = try modelContext.fetch(bodyDataDescriptor)
            for bodyData in allBodyData {
                modelContext.delete(bodyData)
            }
            
            // 清空所有锻炼数据
            let exerciseDataDescriptor = FetchDescriptor<ExerciseData>()
            let allExerciseData = try modelContext.fetch(exerciseDataDescriptor)
            for exerciseData in allExerciseData {
                modelContext.delete(exerciseData)
            }
            
            // 保存更改
            try modelContext.save()
            
            // 使用全局状态管理器触发UI重置
            appStateManager.triggerDataReset()
            
            print("所有本地数据已清空，UI状态已重置")
        } catch {
            print("清空数据失败: \(error)")
        }
    }
    
    private func calculateAge() -> Int {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: Date())
        return ageComponents.year ?? 0
    }
}

#Preview {
    ProfileView()
        .modelContainer(for: [UserProfile.self, BodyData.self, ExerciseData.self])
} 