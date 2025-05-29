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
    @Query private var profiles: [UserProfile]
    @StateObject private var healthKitManager = HealthKitManager.shared
    
    @State private var selectedGender: String = "男"
    @State private var birthDate = Calendar.current.date(from: DateComponents(year: 1990, month: 1, day: 1)) ?? Date()
    @State private var height: Double? = 170.0
    @State private var showingHealthSync = false
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var avatarImage: UIImage? = nil
    @State private var showingClearDataAlert = false
    
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
                        healthSyncSection
                        basicInfoSection
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
            Task {
                await healthKitManager.requestAuthorization()
            }
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
        .onAppear {
            loadAvatarFromLocal()
        }
    }
    
    private var healthSyncSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "heart.text.square")
                    .foregroundColor(.red)
                    .font(.title2)
                Text("健康数据集成")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            if !healthKitManager.isAuthorized {
                VStack(spacing: 8) {
                    Text("连接健康应用以自动同步身体数据")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button(action: {
                        Task {
                            await healthKitManager.requestAuthorization()
                        }
                    }) {
                        Text("连接健康应用")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.green)
                            )
                    }
                }
            } else {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("已连接健康应用")
                        .font(.caption)
                        .foregroundColor(.green)
                    Spacer()
                }
            }
            
            if let error = healthKitManager.authorizationError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    private var basicInfoSection: some View {
        VStack(spacing: 20) {
            // 性别选择
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: selectedGender == "女" ? "person.dress" : "person")
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
                }
                
                DatePicker("", selection: $birthDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .onChange(of: birthDate) { _, _ in
                        saveProfile()
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
            birthDate = profile.birthDate
            height = profile.height
        }
    }
    
    private func saveProfile() {
        if let existingProfile = currentProfile {
            existingProfile.gender = selectedGender
            existingProfile.birthDate = birthDate
            if let height = height {
                existingProfile.height = height
            }
        } else {
            let newProfile = UserProfile(
                gender: selectedGender,
                birthDate: birthDate,
                height: height ?? 170.0
            )
            modelContext.insert(newProfile)
        }
        
        try? modelContext.save()
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
            
            print("所有本地数据已清空")
        } catch {
            print("清空数据失败: \(error)")
        }
    }
}

#Preview {
    ProfileView()
        .modelContainer(for: [UserProfile.self, BodyData.self, ExerciseData.self])
} 