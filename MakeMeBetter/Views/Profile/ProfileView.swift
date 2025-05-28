//
//  ProfileView.swift
//  MakeMeBetter
//
//  Created by watchman on 2025/5/28.
//

import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var userProfile: UserProfile?
    @State private var selectedGender = "男"
    @State private var birthDate: Date = {
        let calendar = Calendar.current
        let components = DateComponents(year: 1990, month: 1, day: 1)
        return calendar.date(from: components) ?? Date()
    }()
    @State private var height: Double? = 170.0
    @State private var showingDatePicker = false
    @State private var selectedAvatar = "person.circle.fill"
    @State private var showingAvatarPicker = false
    
    private let genders = ["男", "女"]
    private let avatarOptions = [
        "person.circle.fill", "person.crop.circle.fill", "person.crop.circle.badge.plus",
        "figure.walk.circle.fill", "figure.run.circle.fill", "figure.strengthtraining.traditional",
        "heart.circle.fill", "star.circle.fill", "sun.max.circle.fill",
        "moon.circle.fill", "leaf.circle.fill", "flame.circle.fill"
    ]
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }
    
    private var ageText: String {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: Date())
        let age = ageComponents.year ?? 0
        return "\(age)岁"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // 顶部背景区域
                VStack(spacing: 20) {
                    // 头像区域
                    VStack(spacing: 16) {
                        Button(action: {
                            showingAvatarPicker = true
                        }) {
                            Image(systemName: selectedAvatar)
                                .font(.system(size: 80, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 120, height: 120)
                                .background(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(.white, lineWidth: 4)
                                )
                                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                        }
                        
                        Text("个人信息")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .padding(.top, 60)
                .padding(.bottom, 60)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        colors: [.blue.opacity(0.8), .purple.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(
                    .rect(
                        topLeadingRadius: 0,
                        bottomLeadingRadius: 30,
                        bottomTrailingRadius: 30,
                        topTrailingRadius: 0
                    )
                )
                
                // 信息卡片区域
                VStack(spacing: 20) {
                    // 性别选择卡片
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 20))
                                .foregroundColor(selectedGender == "女" ? .pink : .blue)
                                .frame(width: 30)
                            
                            Text("性别")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            Spacer()
                        }
                        
                        Picker("性别", selection: $selectedGender) {
                            ForEach(genders, id: \.self) { gender in
                                Text(gender).tag(gender)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    .padding(20)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                    
                    // 出生日期卡片
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "calendar.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.green)
                                .frame(width: 30)
                            
                            Text("出生日期")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            Spacer()
                        }
                        
                        Button(action: {
                            showingDatePicker = true
                        }) {
                            HStack {
                                Text(dateFormatter.string(from: birthDate))
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                HStack(spacing: 8) {
                                    Text(ageText)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.green)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.green.opacity(0.1))
                                        .cornerRadius(8)
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                    .padding(20)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                    
                    // 身高卡片
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "ruler.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.orange)
                                .frame(width: 30)
                            
                            Text("身高")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            Spacer()
                        }
                        
                        SliderInputView(
                            title: "",
                            unit: "cm",
                            value: $height,
                            range: 100.0...220.0
                        )
                    }
                    .padding(20)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                }
                .padding(.horizontal, 20)
                .padding(.top, -40)
                
                Spacer(minLength: 40)
            }
        }
        .background(Color(.systemGroupedBackground))
        .ignoresSafeArea(edges: .bottom)
        .sheet(isPresented: $showingDatePicker) {
            NavigationView {
                VStack {
                    DatePicker(
                        "",
                        selection: $birthDate,
                        in: ...Date(),
                        displayedComponents: .date
                    )
                    .datePickerStyle(WheelDatePickerStyle())
                    .labelsHidden()
                    
                    Spacer()
                }
                .padding()
                .navigationTitle("出生日期")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("取消") {
                            showingDatePicker = false
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("确定") {
                            showingDatePicker = false
                            saveProfile()
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showingAvatarPicker) {
            NavigationView {
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 80), spacing: 20)
                    ], spacing: 20) {
                        ForEach(avatarOptions, id: \.self) { avatar in
                            Button(action: {
                                selectedAvatar = avatar
                                showingAvatarPicker = false
                                saveProfile()
                            }) {
                                Image(systemName: avatar)
                                    .font(.system(size: 40))
                                    .foregroundColor(selectedAvatar == avatar ? .white : .blue)
                                    .frame(width: 80, height: 80)
                                    .background(
                                        selectedAvatar == avatar ? 
                                        LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing) :
                                        LinearGradient(colors: [.blue.opacity(0.1), .purple.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    )
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(selectedAvatar == avatar ? .blue : .clear, lineWidth: 3)
                                    )
                            }
                        }
                    }
                    .padding(20)
                }
                .navigationTitle("选择头像")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("完成") {
                            showingAvatarPicker = false
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
        .onAppear {
            loadProfile()
        }
        .onChange(of: selectedGender) { _ in saveProfile() }
        .onChange(of: height) { _ in saveProfile() }
    }
    
    private func loadProfile() {
        let descriptor = FetchDescriptor<UserProfile>()
        
        do {
            let profiles = try modelContext.fetch(descriptor)
            if let profile = profiles.first {
                userProfile = profile
                selectedGender = profile.gender
                birthDate = profile.birthDate
                height = profile.height
                // 加载头像，如果没有则使用默认值
                selectedAvatar = profile.avatar ?? "person.circle.fill"
            }
        } catch {
            print("加载用户信息失败: \(error)")
        }
    }
    
    private func saveProfile() {
        if userProfile == nil {
            let newProfile = UserProfile(gender: selectedGender, birthDate: birthDate, height: height ?? 170.0)
            newProfile.avatar = selectedAvatar
            modelContext.insert(newProfile)
            userProfile = newProfile
        } else {
            userProfile?.updateProfile(gender: selectedGender, birthDate: birthDate, height: height)
            userProfile?.avatar = selectedAvatar
        }
        
        do {
            try modelContext.save()
        } catch {
            print("保存用户信息失败: \(error)")
        }
    }
}

#Preview {
    ProfileView()
        .modelContainer(for: UserProfile.self, inMemory: true)
} 