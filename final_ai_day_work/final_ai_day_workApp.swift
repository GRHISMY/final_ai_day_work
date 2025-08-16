//
//  final_ai_day_workApp.swift
//  final_ai_day_work
//
//  Created by 慧誉 on 2025/8/15.
//

import SwiftUI
import AppKit
import CoreData

@main
struct final_ai_day_workApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var taskManager: TaskManager
    @State private var statusBarController: StatusBarController?
    
    init() {
        let persistenceController = PersistenceController.shared
        _taskManager = StateObject(wrappedValue: TaskManager(viewContext: persistenceController.container.viewContext))
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(taskManager)
                .onAppear {
                    setupStatusBar()
                }
        }
        .commands {
            // 添加命令以支持状态栏菜单
            CommandGroup(after: .appInfo) {
                Button("显示主窗口") {
                    showMainWindow()
                }
                .keyboardShortcut("1", modifiers: [.command])
            }
        }
    }
    
    private func setupStatusBar() {
        // 创建状态栏控制器
        statusBarController = StatusBarController(taskManager: taskManager)
        
        // 监听任务变化以更新状态栏
        NotificationCenter.default.addObserver(
            forName: NSManagedObjectContext.didSaveObjectsNotification,
            object: persistenceController.container.viewContext,
            queue: .main
        ) { [weak statusBarController] _ in
            DispatchQueue.main.async {
                statusBarController?.refreshStatusBar()
            }
        }
    }
    
    private func showMainWindow() {
        if let window = NSApp.windows.first {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
