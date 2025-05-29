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
    @State private var isLocked = false
    @State private var consecutiveDays = 0
    @State private var showFireworks = false
    @State private var refreshKey = UUID() // 强制刷新key
    
    // 判断是否是历史日期（当天之前）
    private var isHistoricalDate: Bool {
        !Calendar.current.isDate(selectedDate, inSameDayAs: Date()) && 
        selectedDate < Date()
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // 顶部安全区域 - 与刘海屏融为一体
                Color.clear
                    .frame(height: 1)
                
                // 日期选择器和锁定按钮
                HStack {
                    DateSelectorView(selectedDate: $selectedDate)
                    
                    // 锁定按钮 - 只在历史日期显示
                    if isHistoricalDate {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isLocked.toggle()
                            }
                        }) {
                            Image(systemName: isLocked ? "lock.fill" : "lock.open.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(isLocked ? .red : .green)
                                .frame(width: 32, height: 32)
                                .background((isLocked ? Color.red : Color.green).opacity(0.1))
                                .clipShape(Circle())
                        }
                        .padding(.trailing, 20)
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 16)
                
                VStack(spacing: 12) {
                    BodyDataSection(
                        bodyData: $bodyData,
                        selectedDate: selectedDate,
                        isLocked: isHistoricalDate && isLocked
                    )
                    .id("body-\(selectedDate.timeIntervalSince1970)-\(refreshKey)")
                    
                    // 鼓励横幅 - 放在身体数据和锻炼数据之间
                    if consecutiveDays >= 2 {
                        EncouragementView(consecutiveDays: consecutiveDays, showFireworks: $showFireworks)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 8)
                    }
                    
                    ExerciseDataSection(
                        exerciseData: $exerciseData,
                        selectedDate: selectedDate,
                        isLocked: isHistoricalDate && isLocked
                    )
                    .id("exercise-\(selectedDate.timeIntervalSince1970)-\(refreshKey)")
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 16)
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
            checkConsecutiveDays()
        }
        .onChange(of: selectedDate) { _, _ in
            isLocked = true
            loadDataForDate()
            checkConsecutiveDays()
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)) { _ in
            loadDataForDate()
            checkConsecutiveDays()
        }
        .onReceive(NotificationCenter.default.publisher(for: .recordTabSelected)) { _ in
            print("切换到记录tab，重新加载数据")
            loadDataForDate()
            checkConsecutiveDays()
        }
        .onReceive(NotificationCenter.default.publisher(for: .dataCleared)) { _ in
            print("收到数据清空通知，重置所有UI状态")
            resetAllUIStates()
            loadDataForDate()
            checkConsecutiveDays()
        }
        .onChange(of: appStateManager.dataResetTrigger) { _, _ in
            print("检测到全局数据重置，强制重置所有UI状态")
            resetAllUIStates()
            loadDataForDate()
            checkConsecutiveDays()
        }
    }
    
    private func loadDataForDate() {
        guard !selectedDate.timeIntervalSince1970.isNaN else {
            print("错误：selectedDate无效")
            return
        }
        
        let startOfDay = Calendar.current.startOfDay(for: selectedDate)
        
        print("开始加载日期数据: \(startOfDay)")
        
        // 先清空当前数据，避免脏数据
        bodyData = nil
        exerciseData = []
        
        // 加载身体数据
        let bodyDataDescriptor = FetchDescriptor<BodyData>(
            predicate: #Predicate { $0.date == startOfDay }
        )
        
        do {
            let bodyDataResults = try modelContext.fetch(bodyDataDescriptor)
            bodyData = bodyDataResults.first
        } catch {
            print("加载身体数据失败: \(error)")
            bodyData = nil
        }
        
        // 加载锻炼数据
        let exerciseDataDescriptor = FetchDescriptor<ExerciseData>(
            predicate: #Predicate { $0.date == startOfDay }
        )
        
        do {
            let newExerciseData = try modelContext.fetch(exerciseDataDescriptor)
            exerciseData = newExerciseData
        } catch {
            print("加载锻炼数据失败: \(error)")
            exerciseData = []
        }
        
        print("加载完成 - 日期: \(startOfDay), 身体数据: \(bodyData != nil), 锻炼数据: \(exerciseData.count)条")
    }
    
    private func checkConsecutiveDays() {
        let calendar = Calendar.current
        var currentDate = Date() // 始终以今天为准
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
        
        // 如果连续天数>=2，触发烟花效果
        if days >= 2 {
            withAnimation(.easeInOut(duration: 0.5)) {
                showFireworks = true
            }
            
            // 2秒后隐藏烟花
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showFireworks = false
                }
            }
        }
    }
    
    private func resetAllUIStates() {
        // 重置所有状态变量
        bodyData = nil
        exerciseData = []
        consecutiveDays = 0
        showFireworks = false
        
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