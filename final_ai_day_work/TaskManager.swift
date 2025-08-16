//
//  TaskManager.swift
//  final_ai_day_work
//
//  Created by 慧誉 on 2025/8/16.
//

import Foundation
import CoreData

@MainActor
public class TaskManager: ObservableObject {
    private let viewContext: NSManagedObjectContext
    
    public init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
    }
    
    // 创建新任务
    public func createTask(title: String, description: String? = nil, dueDate: Date? = nil) -> Task {
        let newTask = Task(context: viewContext)
        newTask.id = UUID()
        newTask.title = title
        newTask.desc = description
        newTask.isCompleted = false
        newTask.createdAt = Date()
        newTask.dueDate = dueDate
        
        // 设置任务顺序为未完成任务中的最大值+1
        let activeTasks = fetchAllTasks().filter { !$0.isCompleted }
        newTask.order = Int32(activeTasks.count)
        
        saveContext()
        return newTask
    }
    
    // 更新任务
    public func updateTask(_ task: Task, title: String? = nil, description: String? = nil, dueDate: Date? = nil, isCompleted: Bool? = nil, order: Int32? = nil) {
        if let title = title {
            task.title = title
        }
        
        if let description = description {
            task.desc = description
        }
        
        if let dueDate = dueDate {
            task.dueDate = dueDate
        }
        
        if let isCompleted = isCompleted {
            task.isCompleted = isCompleted
        }
        
        if let order = order {
            task.order = order
        }
        
        saveContext()
    }
    
    // 删除任务
    public func deleteTask(_ task: Task) {
        viewContext.delete(task)
        saveContext()
    }
    
    // 批量删除任务
    public func deleteTasks(_ tasks: [Task]) {
        for task in tasks {
            viewContext.delete(task)
        }
        saveContext()
    }
    
    // 获取所有任务
    public func fetchAllTasks() -> [Task] {
        let request: NSFetchRequest<Task> = Task.fetchRequest()
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching tasks: \(error)")
            return []
        }
    }
    
    // 根据ID获取任务
    public func fetchTask(with id: UUID) -> Task? {
        let request: NSFetchRequest<Task> = Task.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            let results = try viewContext.fetch(request)
            return results.first
        } catch {
            print("Error fetching task with id \(id): \(error)")
            return nil
        }
    }
    
    // 更新任务顺序（保持向后兼容）
    public func updateTaskOrder(_ tasks: [Task]) {
        Task { @MainActor in
            await MainActor.run {
                for (index, task) in tasks.enumerated() {
                    task.order = Int32(index)
                }
                saveContext()
            }
        }
    }
    
    // 根据显示过滤器更新任务顺序
    public func updateTaskOrderForDisplay(_ displayTasks: [Task], allTasks: [Task], filter: TaskFilter) {
        // 在主线程中执行更新操作以避免并发访问问题
        Task { @MainActor in
            await MainActor.run {
                // 创建所有任务的副本并按当前顺序排序
                var allTasksSorted = allTasks.sorted { task1, task2 in
                    if task1.isCompleted == task2.isCompleted {
                        return task1.order < task2.order
                    }
                    return !task1.isCompleted && task2.isCompleted
                }
                
                // 根据过滤器类型更新顺序
                switch filter {
                case .all:
                    // 在"全部"视图中，需要分别处理未完成和已完成的任务
                    updateTaskOrderForAllView(displayTasks: displayTasks, allTasks: &allTasksSorted)
                case .active:
                    // 在"进行中"视图中，只更新未完成任务的顺序
                    updateTaskOrderForActiveView(displayTasks: displayTasks, allTasks: &allTasksSorted)
                case .completed:
                    // 在"已完成"视图中，只更新已完成任务的顺序
                    updateTaskOrderForCompletedView(displayTasks: displayTasks, allTasks: &allTasksSorted)
                }
                
                // 保存更改
                saveContext()
            }
        }
    }
    
    // 更新"全部"视图中的任务顺序
    private func updateTaskOrderForAllView(displayTasks: [Task], allTasks: inout [Task]) {
        // 分离未完成和已完成的任务
        let activeTasks = displayTasks.filter { !$0.isCompleted }
        let completedTasks = displayTasks.filter { $0.isCompleted }
        
        // 更新未完成任务的顺序
        var activeOrder = 0
        for task in activeTasks {
            if let index = allTasks.firstIndex(where: { $0.id == task.id }) {
                allTasks[index].order = Int32(activeOrder)
                activeOrder += 1
            }
        }
        
        // 更新已完成任务的顺序
        var completedOrder = 0
        for task in completedTasks {
            if let index = allTasks.firstIndex(where: { $0.id == task.id }) {
                allTasks[index].order = Int32(completedOrder)
                completedOrder += 1
            }
        }
    }
    
    // 更新"进行中"视图中的任务顺序
    private func updateTaskOrderForActiveView(displayTasks: [Task], allTasks: inout [Task]) {
        var order = 0
        for task in displayTasks {
            if let index = allTasks.firstIndex(where: { $0.id == task.id && !$0.isCompleted }) {
                allTasks[index].order = Int32(order)
                order += 1
            }
        }
    }
    
    // 更新"已完成"视图中的任务顺序
    private func updateTaskOrderForCompletedView(displayTasks: [Task], allTasks: inout [Task]) {
        var order = 0
        for task in displayTasks {
            if let index = allTasks.firstIndex(where: { $0.id == task.id && $0.isCompleted }) {
                allTasks[index].order = Int32(order)
                order += 1
            }
        }
    }
    
    // 保存上下文
    private func saveContext() {
        guard viewContext.hasChanges else { return }
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            let nsError = error as NSError
            print("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}