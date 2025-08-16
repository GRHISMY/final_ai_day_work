//
// StatusBarController.swift
// final_ai_day_work
//
// Created by Assistant on 2025/8/16.
//

import SwiftUI
import AppKit
import CoreData

@MainActor
public class StatusBarController: NSObject, NSMenuDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var window: NSWindow?
    private var taskManager: TaskManager
    
    public init(taskManager: TaskManager) {
        self.taskManager = taskManager
        super.init()
        setupStatusBar()
    }
    
    private func setupStatusBar() {
        // 创建状态栏项
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        // 设置状态栏图标
        if let button = statusItem.button {
            updateStatusBarIcon()
            button.action = #selector(statusBarButtonClicked)
            button.target = self
            
            // 添加右键菜单
            let menu = NSMenu()
            menu.delegate = self
            
            let showAppMenuItem = NSMenuItem(title: "显示主窗口", action: #selector(showMainWindow), keyEquivalent: "")
            showAppMenuItem.target = self
            menu.addItem(showAppMenuItem)
            
            menu.addItem(NSMenuItem.separator())
            
            let quitMenuItem = NSMenuItem(title: "退出", action: #selector(quitApp), keyEquivalent: "q")
            quitMenuItem.target = self
            menu.addItem(quitMenuItem)
            
            statusItem.menu = menu
        }
    }
    
    private func updateStatusBarIcon() {
        guard let button = statusItem.button else { return }
        
        // 获取任务进度
        let tasks = taskManager.fetchAllTasks()
        let totalTasks = tasks.count
        let completedTasks = tasks.filter { $0.isCompleted }.count
        let progress = totalTasks > 0 ? Double(completedTasks) / Double(totalTasks) : 0.0
        
        // 创建状态栏图标
        let icon = createStatusBarIcon(progress: progress, totalTasks: totalTasks)
        button.image = icon
        button.image?.isTemplate = true // 使图标适应深色/浅色模式
        
        // 设置工具提示
        button.toolTip = "任务管理器 - \(completedTasks)/\(totalTasks) 任务已完成"
    }
    
    private func createStatusBarIcon(progress: Double, totalTasks: Int) -> NSImage {
        // 创建一个自定义图标来显示进度
        let size = NSSize(width: 22, height: 22)
        let image = NSImage(size: size)
        
        image.lockFocus()
        
        // 设置背景色
        NSColor.clear.set()
        NSBezierPath(rect: NSRect(origin: .zero, size: size)).fill()
        
        // 绘制外圈
        let outerCircleRect = NSRect(x: 2, y: 2, width: 18, height: 18)
        NSColor.gray.withAlphaComponent(0.3).set()
        NSBezierPath(ovalIn: outerCircleRect).fill()
        
        // 绘制进度弧
        if totalTasks > 0 {
            let center = NSPoint(x: size.width / 2, y: size.height / 2)
            let radius = CGFloat(8)
            let startAngle = CGFloat(90) // 从顶部开始
            let endAngle = startAngle - CGFloat(progress * 360)
            
            NSColor.systemBlue.set()
            let path = NSBezierPath()
            path.lineWidth = 2
            path.appendArc(
                withCenter: center,
                radius: radius,
                startAngle: startAngle,
                endAngle: endAngle,
                clockwise: true
            )
            path.stroke()
        }
        
        // 绘制任务数量
        if totalTasks > 0 {
            let attributedString = NSAttributedString(
                string: "\(totalTasks)",
                attributes: [
                    .font: NSFont.systemFont(ofSize: 10, weight: .medium),
                    .foregroundColor: NSColor.labelColor
                ]
            )
            
            let stringSize = attributedString.size()
            let stringRect = NSRect(
                x: (size.width - stringSize.width) / 2,
                y: (size.height - stringSize.height) / 2,
                width: stringSize.width,
                height: stringSize.height
            )
            attributedString.draw(in: stringRect)
        } else {
            // 如果没有任务，显示一个简单的图标
            let attributedString = NSAttributedString(
                string: "✓",
                attributes: [
                    .font: NSFont.systemFont(ofSize: 12, weight: .medium),
                    .foregroundColor: NSColor.labelColor
                ]
            )
            
            let stringSize = attributedString.size()
            let stringRect = NSRect(
                x: (size.width - stringSize.width) / 2,
                y: (size.height - stringSize.height) / 2,
                width: stringSize.width,
                height: stringSize.height
            )
            attributedString.draw(in: stringRect)
        }
        
        image.unlockFocus()
        
        return image
    }
    
    @objc private func statusBarButtonClicked() {
        // 左键单击显示主窗口
        showMainWindow()
    }
    
    @objc private func showMainWindow() {
        // 激活应用并显示主窗口
        NSApp.activate(ignoringOtherApps: true)
        
        // 如果有隐藏的窗口，显示它
        if let window = NSApp.windows.first {
            window.makeKeyAndOrderFront(nil)
        }
    }
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
    
    // 更新状态栏图标（当任务状态改变时调用）
    public func refreshStatusBar() {
        updateStatusBarIcon()
    }
}