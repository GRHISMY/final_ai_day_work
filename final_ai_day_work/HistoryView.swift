import SwiftUI
import CoreData

public struct HistoryView: View {
    @EnvironmentObject private var taskManager: TaskManager
    @State private var deletedTasks: [TaskItem] = []
    @State private var showAlert = false
    @State private var taskToRestore: TaskItem?
    @State private var taskToDeletePermanently: TaskItem?
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
    
    public var body: some View {
        VStack {
            if deletedTasks.isEmpty {
                Text("暂无已删除的任务")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                List(deletedTasks, id: \.id) { task in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(task.title ?? "未命名任务")
                                .strikethrough(true)
                                .foregroundColor(.secondary)
                            
                            if let desc = task.desc, !desc.isEmpty {
                                Text(desc)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            // 显示创建时间
                            if let createdAt = task.createdAt {
                                Text("创建于: \(dateFormatter.string(from: createdAt))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        // 恢复按钮
                        Button(action: {
                            taskToRestore = task
                            showAlert = true
                        }) {
                            Image(systemName: "arrow.counterclockwise")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.trailing, 8)
                        
                        // 永久删除按钮
                        Button(action: {
                            taskToDeletePermanently = task
                            showAlert = true
                        }) {
                            Image(systemName: "trash.fill")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .alert(isPresented: $showAlert) {
            if taskToRestore != nil {
                return Alert(
                    title: Text("恢复任务"),
                    message: Text("确定要恢复任务 \"\(taskToRestore?.title ?? "")\" 吗？"),
                    primaryButton: .default(Text("恢复")) {
                        if let task = taskToRestore {
                            restoreTask(task)
                        }
                        taskToRestore = nil
                    },
                    secondaryButton: .cancel() {
                        taskToRestore = nil
                    }
                )
            } else if taskToDeletePermanently != nil {
                return Alert(
                    title: Text("永久删除"),
                    message: Text("确定要永久删除任务 \"\(taskToDeletePermanently?.title ?? "")\" 吗？此操作无法撤销。"),
                    primaryButton: .destructive(Text("删除")) {
                        if let task = taskToDeletePermanently {
                            permanentlyDeleteTask(task)
                        }
                        taskToDeletePermanently = nil
                    },
                    secondaryButton: .cancel() {
                        taskToDeletePermanently = nil
                    }
                )
            } else {
                return Alert(title: Text("未知操作"))
            }
        }
        .onAppear {
            loadDeletedTasks()
        }
    }
    
    // 获取已删除的任务
    private func loadDeletedTasks() {
        deletedTasks = taskManager.fetchDeletedTasks()
    }
    
    // 恢复任务
    private func restoreTask(_ task: TaskItem) {
        task.markAsDeleted = false
        taskManager.saveContext()
        loadDeletedTasks()
    }
    
    // 永久删除任务
    private func permanentlyDeleteTask(_ task: TaskItem) {
        taskManager.permanentlyDeleteTask(task)
        loadDeletedTasks()
    }
}