//
//  RecordView.swift
//  MakeMeBetter
//
//  Created by watchman on 2025/5/28.
//

import SwiftUI
import SwiftData

// 扩展Notification.Name
extension Notification.Name {
    static let recordTabSelected = Notification.Name("recordTabSelected")
    static let dataCleared = Notification.Name("dataCleared")
    static let resetUIStates = Notification.Name("resetUIStates")
}

struct RecordView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appStateManager: AppStateManager
    @State private var selectedDate = Date()
    @State private var bodyData: BodyData?
    @State private var exerciseData: [ExerciseData] = []

    @State private var consecutiveDays = 0
    @State private var showFireworks = false
    @State private var refreshKey = UUID() // 强制刷新key
    @State private var shouldShowEncouragement = false // 新增：控制是否显示鼓励横幅
    
    // 判断是否是历史日期（当天之前）
    private var isHistoricalDate: Bool {
        !Calendar.current.isDate(selectedDate, inSameDayAs: Date()) && 
        selectedDate < Date()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 固定的日期选择器
            VStack(spacing: 0) {
                // 日期选择器
                HStack {
                    DateSelectorView(selectedDate: $selectedDate)
                }
                .padding(.top, 8)
                .padding(.bottom, 16)
                .background(
                    LinearGradient(
                        colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                
                // 分隔线
                Divider()
                    .opacity(0.3)
            }
            
            // 可滚动的内容区域
            ScrollView {
                VStack(spacing: 12) {
                    BodyDataSection(
                        bodyData: $bodyData,
                        selectedDate: selectedDate
                    )
                    .id("body-\(selectedDate.timeIntervalSince1970)-\(refreshKey)")
                    
                    // 鼓励横幅 - 只在有数据且连续天数>=2时显示
                    if shouldShowEncouragement && consecutiveDays >= 2 {
                        EncouragementView(consecutiveDays: consecutiveDays, showFireworks: $showFireworks)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 8)
                    }
                    
                    ExerciseDataSection(
                        exerciseData: $exerciseData,
                        selectedDate: selectedDate
                    )
                    .id("exercise-\(selectedDate.timeIntervalSince1970)-\(refreshKey)")
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 16)
            }
            .background(
                LinearGradient(
                    colors: [.blue.opacity(0.05), .purple.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
        .id(refreshKey)
        .background(
            LinearGradient(
                colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .onAppear {
            loadDataForDate()
            checkConsecutiveDaysAndEncouragement()
        }
        .onChange(of: selectedDate) { _, _ in
            // 更新refreshKey强制重建子组件
            refreshKey = UUID()
            loadDataForDate()
            checkConsecutiveDaysAndEncouragement()
        }
        .onReceive(NotificationCenter.default.publisher(for: .recordTabSelected)) { _ in
            print("切换到记录tab，重新加载数据")
            loadDataForDate()
            checkConsecutiveDaysAndEncouragement()
        }
        .onReceive(NotificationCenter.default.publisher(for: .dataCleared)) { _ in
            print("收到数据清空通知，重置所有UI状态")
            resetAllUIStates()
            loadDataForDate()
            checkConsecutiveDaysAndEncouragement()
        }
        .onChange(of: appStateManager.dataResetTrigger) { _, _ in
            print("检测到全局数据重置，强制重置所有UI状态")
            resetAllUIStates()
            loadDataForDate()
            checkConsecutiveDaysAndEncouragement()
        }
    }
    
    private func loadDataForDate() {
        guard !selectedDate.timeIntervalSince1970.isNaN else {
            print("错误：selectedDate无效")
            return
        }
        
        let startOfDay = Calendar.current.startOfDay(for: selectedDate)
        
        print("🔄 开始加载日期数据: \(startOfDay)")
        print("📅 当前选择日期: \(selectedDate)")
        print("📅 标准化日期: \(startOfDay)")
        
        // 临时存储新数据
        var newBodyData: BodyData? = nil
        var newExerciseData: [ExerciseData] = []
        
        // 加载身体数据
        let bodyDataDescriptor = FetchDescriptor<BodyData>(
            predicate: #Predicate { $0.date == startOfDay }
        )
        
        do {
            let bodyDataResults = try modelContext.fetch(bodyDataDescriptor)
            newBodyData = bodyDataResults.first
            print("💪 身体数据查询结果: 找到 \(bodyDataResults.count) 条记录")
            if let data = newBodyData {
                print("💪 身体数据详情: 体重=\(data.weight ?? 0), 体脂=\(data.bodyFat ?? 0), 腰围=\(data.waistline ?? 0)")
            }
        } catch {
            print("❌ 加载身体数据失败: \(error)")
            newBodyData = nil
        }
        
        // 加载锻炼数据
        let exerciseDataDescriptor = FetchDescriptor<ExerciseData>(
            predicate: #Predicate { $0.date == startOfDay }
        )
        
        do {
            newExerciseData = try modelContext.fetch(exerciseDataDescriptor)
            print("🏃 锻炼数据查询结果: 找到 \(newExerciseData.count) 条记录")
            for data in newExerciseData {
                print("🏃 锻炼数据详情: 类型=\(data.exerciseType.rawValue), 时长=\(data.duration ?? 0)分钟")
            }
        } catch {
            print("❌ 加载锻炼数据失败: \(error)")
            newExerciseData = []
        }
        
        // 一次性更新所有数据
        withAnimation(.easeInOut(duration: 0.2)) {
            bodyData = newBodyData
            exerciseData = newExerciseData
        }
        
        print("✅ 加载完成 - 日期: \(startOfDay), 身体数据: \(bodyData != nil), 锻炼数据: \(exerciseData.count)条")
    }
    
    private func loadDataForDateAsync() async {
        await MainActor.run {
            loadDataForDate()
        }
    }
    
    private func checkConsecutiveDaysAndEncouragement() {
        let calendar = Calendar.current
        let selectedDayStart = calendar.startOfDay(for: selectedDate)
        
        // 1. 检查当前选择日期是否有任何数据（身体数据或锻炼数据）
        let hasDataOnSelectedDate = hasAnyDataOnDate(selectedDayStart)
        
        // 2. 计算连续锻炼天数（从今天开始往前计算）
        var currentDate = Date()
        var days = 0
        
        // 从今天开始往前检查连续锻炼天数
        while true {
            let dayStart = calendar.startOfDay(for: currentDate)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
            
            // 查询当天是否有锻炼数据
            let descriptor = FetchDescriptor<ExerciseData>(
                predicate: #Predicate<ExerciseData> { exercise in
                    exercise.date >= dayStart && exercise.date < dayEnd && 
                    exercise.duration != nil && (exercise.duration ?? 0) > 0
                }
            )
            
            do {
                let dayExercises = try modelContext.fetch(descriptor)
                if dayExercises.isEmpty {
                    break // 没有锻炼数据，中断连续计数
                }
                days += 1
                
                // 往前推一天
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
                
                // 防止无限循环，最多检查30天
                if days >= 30 {
                    break
                }
            } catch {
                print("查询锻炼数据失败: \(error)")
                break
            }
        }
        
        consecutiveDays = days
        
        // 3. 判断是否显示鼓励横幅
        let isToday = calendar.isDate(selectedDate, inSameDayAs: Date())
        let isYesterday = calendar.isDate(selectedDate, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date())
        
        if isToday {
            // 今天：有数据就显示
            shouldShowEncouragement = hasDataOnSelectedDate
        } else if isYesterday {
            // 昨天：有数据且有连续记录就显示
            shouldShowEncouragement = hasDataOnSelectedDate && days >= 1
        } else {
            // 其他历史日期：有数据就显示（但不会有烟花效果）
            shouldShowEncouragement = hasDataOnSelectedDate
        }
        
        // 4. 如果连续天数>=2且是今天，触发烟花效果
        if days >= 2 && isToday && shouldShowEncouragement {
            withAnimation(.easeInOut(duration: 0.5)) {
                showFireworks = true
            }
            
            // 2秒后隐藏烟花
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showFireworks = false
                }
            }
        } else {
            showFireworks = false
        }
        
        print("🎉 鼓励横幅逻辑: 选择日期=\(selectedDate), 有数据=\(hasDataOnSelectedDate), 连续天数=\(days), 显示横幅=\(shouldShowEncouragement)")
    }
    
    // 检查指定日期是否有任何数据（身体数据或锻炼数据）
    private func hasAnyDataOnDate(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
        
        // 检查身体数据
        let bodyDataDescriptor = FetchDescriptor<BodyData>(
            predicate: #Predicate<BodyData> { body in
                body.date >= dayStart && body.date < dayEnd &&
                (body.weight != nil || body.bodyFat != nil || body.waistline != nil)
            }
        )
        
        // 检查锻炼数据
        let exerciseDataDescriptor = FetchDescriptor<ExerciseData>(
            predicate: #Predicate<ExerciseData> { exercise in
                exercise.date >= dayStart && exercise.date < dayEnd &&
                exercise.duration != nil && (exercise.duration ?? 0) > 0
            }
        )
        
        do {
            let bodyDataResults = try modelContext.fetch(bodyDataDescriptor)
            let exerciseDataResults = try modelContext.fetch(exerciseDataDescriptor)
            
            let hasData = !bodyDataResults.isEmpty || !exerciseDataResults.isEmpty
            print("📊 日期 \(dayStart) 数据检查: 身体数据=\(bodyDataResults.count)条, 锻炼数据=\(exerciseDataResults.count)条, 有数据=\(hasData)")
            return hasData
        } catch {
            print("❌ 检查数据失败: \(error)")
            return false
        }
    }
    
    private func resetAllUIStates() {
        // 重置所有状态变量
        bodyData = nil
        exerciseData = []
        consecutiveDays = 0
        showFireworks = false
        shouldShowEncouragement = false
        
        // 确保selectedDate保持有效
        if selectedDate.timeIntervalSince1970.isNaN || selectedDate.timeIntervalSince1970 <= 0 {
            selectedDate = Date()
            print("selectedDate无效，重置为当前日期")
        }
        
        // 更新refreshKey强制重新创建整个视图
        refreshKey = UUID()
        
        // 发送通知给子组件，让它们也重置状态
        NotificationCenter.default.post(name: .resetUIStates, object: nil)
        
        print("强制重置所有UI状态，refreshKey已更新，selectedDate: \(selectedDate)")
    }
}

// 鼓励提示视图
struct EncouragementView: View {
    let consecutiveDays: Int
    @Binding var showFireworks: Bool
    
    private var encouragementText: String {
        switch consecutiveDays {
        case 2...3:
            return "哇！你好棒啊！连续锻炼了\(consecutiveDays)天 💪"
        case 4...6:
            return "太厉害了！坚持锻炼\(consecutiveDays)天，继续加油！🔥"
        case 7...13:
            return "amazing！连续\(consecutiveDays)天锻炼，你就是健身达人！⭐️"
        case 14...20:
            return "不可思议！\(consecutiveDays)天连续锻炼，你已经超越了99%的人！🏆"
        case 21...29:
            return "传奇级别！连续\(consecutiveDays)天锻炼，你就是健身界的超级英雄！🦸‍♂️"
        default:
            return "天哪！连续\(consecutiveDays)天锻炼，你已经是健身界的神话了！👑"
        }
    }
    
    private var backgroundColor: LinearGradient {
        LinearGradient(
            colors: [.orange.opacity(0.8), .pink.opacity(0.8), .purple.opacity(0.8)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    var body: some View {
        ZStack {
            // 背景卡片
            RoundedRectangle(cornerRadius: 16)
                .fill(backgroundColor)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.white)
                        .font(.title2)
                        .scaleEffect(showFireworks ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: showFireworks)
                    
                    Text(encouragementText)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Image(systemName: "star.fill")
                        .foregroundColor(.white)
                        .font(.title2)
                        .scaleEffect(showFireworks ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true).delay(0.3), value: showFireworks)
                }
                
                // 进度条
                HStack {
                    ForEach(0..<min(consecutiveDays, 10), id: \.self) { _ in
                        Circle()
                            .fill(.white)
                            .frame(width: 8, height: 8)
                            .scaleEffect(showFireworks ? 1.3 : 1.0)
                            .animation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true), value: showFireworks)
                    }
                    
                    if consecutiveDays > 10 {
                        Text("+\(consecutiveDays - 10)")
                            .font(.caption)
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            // 烟花效果
            if showFireworks {
                ForEach(0..<6, id: \.self) { index in
                    FireworkParticle(delay: Double(index) * 0.1)
                }
            }
        }
        .scaleEffect(showFireworks ? 1.05 : 1.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showFireworks)
    }
}

// 烟花粒子效果
struct FireworkParticle: View {
    let delay: Double
    @State private var isAnimating = false
    
    var body: some View {
        Circle()
            .fill(Color.yellow)
            .frame(width: 6, height: 6)
            .scaleEffect(isAnimating ? 0 : 1)
            .opacity(isAnimating ? 0 : 1)
            .offset(
                x: isAnimating ? CGFloat.random(in: -100...100) : 0,
                y: isAnimating ? CGFloat.random(in: -100...100) : 0
            )
            .onAppear {
                withAnimation(.easeOut(duration: 1.5).delay(delay)) {
                    isAnimating = true
                }
            }
            .onDisappear {
                isAnimating = false
            }
    }
}

#Preview {
    RecordView()
        .modelContainer(for: [BodyData.self, ExerciseData.self], inMemory: true)
} 