//
//  IconExporter.swift
//  MakeMeBetter
//
//  Created by watchman on 2025/5/28.
//

import SwiftUI
import UIKit
import Photos

struct IconExporter {
    static func exportIcons() {
        // 请求相册访问权限
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized, .limited:
                    generateAndSaveIcons()
                case .denied, .restricted:
                    print("相册访问权限被拒绝")
                case .notDetermined:
                    print("相册访问权限未确定")
                @unknown default:
                    print("未知的权限状态")
                }
            }
        }
    }
    
    private static func generateAndSaveIcons() {
        let sizes: [CGFloat] = [
            20, 29, 40, 58, 60, 76, 80, 87, 120, 152, 167, 180, 1024
        ]
        
        for size in sizes {
            let view = AppIconGenerator(size: size)
            let image = view.asUIImage(size: CGSize(width: size, height: size))
            saveImageToPhotos(image, name: "AppIcon_\(Int(size))x\(Int(size))")
        }
    }
    
    private static func saveImageToPhotos(_ image: UIImage, name: String) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }) { success, error in
            DispatchQueue.main.async {
                if success {
                    print("已保存图标: \(name)")
                } else if let error = error {
                    print("保存图标失败: \(error.localizedDescription)")
                }
            }
        }
    }
}

extension View {
    func asUIImage(size: CGSize) -> UIImage {
        let controller = UIHostingController(rootView: self)
        controller.view.bounds = CGRect(origin: .zero, size: size)
        controller.view.backgroundColor = UIColor.clear
        
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
}

// 用于在应用中预览和导出图标的视图
struct IconExportView: View {
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    Text("MakeMeBetter")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("应用图标设计")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    // 主图标预览
                    AppIconView()
                    
                    Text("设计理念")
                        .font(.headline)
                        .padding(.top)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• 蓝紫渐变背景代表科技感和活力")
                        Text("• 哑铃图标象征健身和力量训练")
                        Text("• 上升箭头表示进步和提升")
                        Text("• 装饰圆点增加设计层次感")
                    }
                    .font(.body)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    // 不同尺寸预览
                    Text("不同尺寸预览")
                        .font(.headline)
                        .padding(.top)
                    
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 80), spacing: 15)
                    ], spacing: 15) {
                        ForEach([40, 60, 80, 120], id: \.self) { size in
                            VStack {
                                AppIconGenerator(size: CGFloat(size))
                                Text("\(size)pt")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Button(action: {
                        IconExporter.exportIcons()
                        alertMessage = "正在生成并保存图标到相册..."
                        showingAlert = true
                    }) {
                        Text("导出所有尺寸图标到相册")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                    }
                    .padding(.top)
                    
                    VStack(spacing: 8) {
                        Text("使用说明")
                            .font(.headline)
                        
                        Text("1. 点击上方按钮导出图标到相册")
                        Text("2. 从相册中获取生成的图标文件")
                        Text("3. 在Xcode中添加到AppIcon.appiconset")
                        Text("4. 完成后将应用入口改回MainTabView()")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
        .alert("图标导出", isPresented: $showingAlert) {
            Button("确定") { }
        } message: {
            Text(alertMessage)
        }
    }
}

#Preview {
    IconExportView()
} 