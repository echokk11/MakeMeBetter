//
//  AppIconView.swift
//  MakeMeBetter
//
//  Created by watchman on 2025/5/28.
//

import SwiftUI

struct AppIconView: View {
    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                colors: [
                    Color(red: 0.2, green: 0.6, blue: 1.0),
                    Color(red: 0.6, green: 0.3, blue: 0.9)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // 主要图标元素
            VStack(spacing: 8) {
                // 哑铃图标
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
                
                // 上升趋势箭头
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .opacity(0.9)
            }
            .offset(y: -5)
            
            // 装饰性元素
            VStack {
                HStack {
                    Circle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 12, height: 12)
                    Spacer()
                }
                Spacer()
                HStack {
                    Spacer()
                    Circle()
                        .fill(.white.opacity(0.15))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(16)
        }
        .frame(width: 120, height: 120)
        .cornerRadius(26)
        .overlay(
            RoundedRectangle(cornerRadius: 26)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

// 用于生成不同尺寸的图标
struct AppIconGenerator: View {
    let size: CGFloat
    
    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                colors: [
                    Color(red: 0.2, green: 0.6, blue: 1.0),
                    Color(red: 0.6, green: 0.3, blue: 0.9)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // 主要图标元素
            VStack(spacing: size * 0.067) {
                // 哑铃图标
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: size * 0.33, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: size * 0.017, x: 0, y: size * 0.017)
                
                // 上升趋势箭头
                Image(systemName: "arrow.up.right")
                    .font(.system(size: size * 0.167, weight: .bold))
                    .foregroundColor(.white)
                    .opacity(0.9)
            }
            .offset(y: -size * 0.042)
            
            // 装饰性元素
            VStack {
                HStack {
                    Circle()
                        .fill(.white.opacity(0.2))
                        .frame(width: size * 0.1, height: size * 0.1)
                    Spacer()
                }
                Spacer()
                HStack {
                    Spacer()
                    Circle()
                        .fill(.white.opacity(0.15))
                        .frame(width: size * 0.067, height: size * 0.067)
                }
            }
            .padding(size * 0.133)
        }
        .frame(width: size, height: size)
        .cornerRadius(size * 0.217)
        .overlay(
            RoundedRectangle(cornerRadius: size * 0.217)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview("App Icon Preview") {
    VStack(spacing: 20) {
        Text("MakeMeBetter App Icon")
            .font(.title2)
            .fontWeight(.bold)
        
        AppIconView()
        
        HStack(spacing: 15) {
            AppIconGenerator(size: 60)
            AppIconGenerator(size: 80)
            AppIconGenerator(size: 100)
        }
        
        Text("不同尺寸预览")
            .font(.caption)
            .foregroundColor(.secondary)
    }
    .padding()
} 