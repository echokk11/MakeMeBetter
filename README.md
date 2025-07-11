# MakeMeBetter - 健身数据记录应用

一个简洁美观的iOS健身数据记录应用，帮助用户跟踪身体数据和锻炼记录，实现健身目标的可视化管理。

## 📱 应用截图

应用采用现代化的iOS设计风格，包含三个主要功能模块，界面简洁直观，操作流畅。

## ✨ 主要功能

### 🏠 记录页面
- **日期选择器**: 顶部日期组件，支持左右滑动切换日期，自动限制不能选择未来日期
- **身体数据记录**: 
  - 体重 (40-120kg) - 支持从Apple Health读取
  - 体脂率 (8-35%) - 支持从Apple Health读取
  - 腰围 (60-120cm) - 支持从Apple Health读取，修改时自动同步到Apple Health
  - 实时BMI计算和健康状态显示
- **锻炼数据记录**:
  - 有氧运动时长
  - 力量训练时长  
  - HIIT训练时长
  - 快捷时间按钮 (20/30/40/50/60分钟)
  - 备注功能
- **实时数据保存**: 滑动组件变化时自动保存数据
- **智能数据加载**: 切换日期时自动加载对应日期的历史数据
- **Apple Health集成**: 自动读取健康数据，腰围数据双向同步

### 📊 趋势页面
- **多指标趋势图**: 使用Charts框架展示6种数据指标的变化曲线
  - 体重趋势
  - 体脂率趋势
  - 腰围趋势
  - 有氧运动时长
  - 力量训练时长
  - HIIT训练时长
- **时间范围选择**: 支持最近7天、14天、30天的数据展示
- **美观的图表设计**: 渐变色彩、面积图、平滑曲线
- **智能数据过滤**: 只显示有记录的日期，过滤无效数据

### 👤 个人信息页面
- **头像选择**: 12种不同风格的头像图标
- **基本信息设置**:
  - 性别选择 (动态图标颜色)
  - 出生日期 (默认1990.01.01)
  - 身高设置 - 支持从Apple Health读取
- **现代化UI设计**: 渐变背景、卡片布局、适配刘海屏
- **Apple Health连接**: 一键连接健康应用，自动同步身高等基础数据

## 🛠 技术特性

### 架构设计
- **组件化架构**: 清晰的代码结构，易于维护和扩展
- **SwiftUI**: 使用最新的SwiftUI框架构建用户界面
- **SwiftData**: 现代化的数据持久化解决方案
- **Charts框架**: 原生图表组件，性能优异
- **HealthKit集成**: 与Apple Health无缝集成，支持健康数据读取和写入

### 数据模型
- **UserProfile**: 用户个人信息 (性别、出生日期、身高、头像)
- **BodyData**: 身体数据 (体重、体脂、腰围、BMI)
- **ExerciseData**: 锻炼数据 (有氧、力量、HIIT时长及备注)
- **HealthKitManager**: Apple Health数据管理器，处理权限和数据同步

### 核心组件
- **SliderInputView**: 通用滑动输入组件
- **DateSelectorView**: 日期选择组件，支持左右切换
- **BMI计算器**: 实时计算并显示健康状态
- **趋势图表**: 多指标数据可视化
- **HealthKitManager**: Apple Health数据管理器，处理权限和数据同步

## 🎨 设计特色

### 用户体验
- **直观操作**: 滑动输入替代键盘输入，操作更流畅
- **实时反馈**: 数据变化立即保存和显示
- **智能限制**: 防止选择未来日期等无效操作
- **快捷操作**: 锻炼时长快捷按钮，提高输入效率

### 视觉设计
- **现代化配色**: 蓝紫渐变主题，视觉舒适
- **卡片式布局**: 清晰的信息层次
- **动态图标**: 根据用户选择变化的图标颜色
- **适配性强**: 支持不同尺寸的iOS设备

## 📋 使用说明

### 首次使用
1. 在"个人信息"页面设置基本信息
2. 在"记录"页面开始记录每日数据
3. 在"趋势"页面查看数据变化

### 日常使用
1. 打开应用自动显示今日记录页面
2. 滑动调整各项数据值
3. 数据自动保存，无需手动操作
4. 查看趋势图了解进步情况

### 数据精度
- 所有数值精确到小数点后1位
- BMI自动计算，实时更新
- 支持历史数据的完整记录和查看

## 🔧 技术要求

- **iOS版本**: iOS 16.0+
- **Xcode版本**: Xcode 15.0+
- **Swift版本**: Swift 5.9+
- **依赖框架**: SwiftUI, SwiftData, Charts, HealthKit
- **权限要求**: 
  - 相册访问权限（图标导出功能）
  - 健康数据读取权限（体重、身高、体脂率、腰围）
  - 健康数据写入权限（腰围数据同步）

## 📦 项目结构

```
MakeMeBetter/
├── Models/                 # 数据模型
│   ├── UserProfile.swift
│   ├── BodyData.swift
│   ├── ExerciseData.swift
│   └── HealthKitManager.swift
├── Views/                  # 页面视图
│   ├── MainTabView.swift
│   ├── RecordView.swift
│   ├── TrendView.swift
│   └── ProfileView.swift
├── Components/             # 通用组件
│   ├── SliderInputView.swift
│   ├── DateSelectorView.swift
│   ├── BodyDataSection.swift
│   ├── ExerciseDataSection.swift
│   ├── AppIconView.swift
│   └── IconExporter.swift
├── MakeMeBetter.entitlements  # 应用权限配置
└── MakeMeBetterApp.swift  # 应用入口
```

## 🚀 安装和运行

1. 克隆项目到本地
2. 使用Xcode打开 `MakeMeBetter.xcodeproj`
3. 选择目标设备或模拟器
4. 点击运行按钮 (⌘+R)

## 🎯 未来规划

- [ ] 添加数据导出功能
- [ ] 支持多种锻炼类型
- [ ] 增加目标设定和提醒
- [ ] 添加数据分析和建议
- [x] 支持Apple Health集成（已完成基础功能）
- [ ] 扩展Apple Health集成（更多健康指标）

## 📄 许可证

本项目仅供学习和个人使用。

---

**MakeMeBetter** - 让每一天都比昨天更好 💪