//
//  TaskManager.swift
//  final_ai_day_work
//
//  Created by 慧誉 on 2025/8/16.
//

import Foundation
import CoreData

// 创建一个类型别名来避免与Swift的Task冲突
public typealias TaskItem = Task

@MainActor
public class TaskManager: ObservableObject {
    private let viewContext: NSManagedObjectContext
    
    public init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
    }
    
    // 创建新任务
    public func createTask(title: String, description: String? = nil, dueDate: Date? = nil) -> TaskItem {
        let newTask = TaskItem(context: viewContext)
        newTask.id = UUID()
        newTask.title = title
        newTask.desc = description
        newTask.isCompleted = false
        newTask.markAsDeleted = false
        newTask.createdAt = Date()
        newTask.dueDate = dueDate
        
        // 设置任务顺序为未完成任务中的最大值+1
        let activeTasks = fetchAllTasks().filter { !$0.isCompleted }
        newTask.order = Int32(activeTasks.count)
        
        saveContext()
        return newTask
    }
    
    // 更新任务
    public func updateTask(_ task: TaskItem, title: String? = nil, description: String? = nil, dueDate: Date? = nil, isCompleted: Bool? = nil, order: Int32? = nil) {
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
    
    // 删除任务（假删除）
    public func deleteTask(_ task: TaskItem) {
        task.markAsDeleted = true
        saveContext()
    }
    
    // 批量删除任务（假删除）
    public func deleteTasks(_ tasks: [TaskItem]) {
        for task in tasks {
            task.markAsDeleted = true
        }
        saveContext()
    }
    
    // 永久删除任务
    public func permanentlyDeleteTask(_ task: TaskItem) {
        viewContext.delete(task)
        saveContext()
    }
    
    // 批量永久删除任务
    public func permanentlyDeleteTasks(_ tasks: [TaskItem]) {
        for task in tasks {
            viewContext.delete(task)
        }
        saveContext()
    }
    
    // 获取所有任务（排除已删除的）
    public func fetchAllTasks() -> [TaskItem] {
        let request: NSFetchRequest<TaskItem> = TaskItem.fetchRequest()
        request.predicate = NSPredicate(format: "markAsDeleted == false")
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching tasks: \(error)")
            return []
        }
    }
    
    // 获取已完成的任务（排除已删除的，按完成时间排序）
    public func fetchCompletedTasks() -> [TaskItem] {
        let request: NSFetchRequest<TaskItem> = TaskItem.fetchRequest()
        request.predicate = NSPredicate(format: "isCompleted == true AND markAsDeleted == false")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TaskItem.createdAt, ascending: false)]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching completed tasks: \(error)")
            return []
        }
    }
    
    // 根据ID获取任务（排除已删除的）
    public func fetchTask(with id: UUID) -> TaskItem? {
        let request: NSFetchRequest<TaskItem> = TaskItem.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@ AND markAsDeleted == false", id as CVarArg)
        
        do {
            let results = try viewContext.fetch(request)
            return results.first
        } catch {
            print("Error fetching task with id \(id): \(error)")
            return nil
        }
    }
    
    // 获取已删除的任务
    public func fetchDeletedTasks() -> [TaskItem] {
        let request: NSFetchRequest<TaskItem> = TaskItem.fetchRequest()
        request.predicate = NSPredicate(format: "markAsDeleted == true")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TaskItem.createdAt, ascending: false)]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching deleted tasks: \(error)")
            return []
        }
    }
    
    // 更新任务顺序（保持向后兼容）
    public func updateTaskOrder(_ tasks: [TaskItem]) {
        DispatchQueue.main.async {
            for (index, task) in tasks.enumerated() {
                task.order = Int32(index)
            }
            self.saveContext()
        }
    }
    
    // 根据显示过滤器更新任务顺序
    public func updateTaskOrderForDisplay(_ displayTasks: [TaskItem], allTasks: [TaskItem], filter: TaskFilter) {
        DispatchQueue.main.async {
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
                self.updateTaskOrderForAllView(displayTasks: displayTasks, allTasks: &allTasksSorted)
            case .active:
                // 在"进行中"视图中，只更新未完成任务的顺序
                self.updateTaskOrderForActiveView(displayTasks: displayTasks, allTasks: &allTasksSorted)
            case .completed:
                // 在"已完成"视图中，只更新已完成任务的顺序
                self.updateTaskOrderForCompletedView(displayTasks: displayTasks, allTasks: &allTasksSorted)
            case .history:
                // 历史记录视图不需要更新任务顺序
                break
            }
            
            // 保存更改
            self.saveContext()
        }
    }
    
    // 更新"全部"视图中的任务顺序
    private func updateTaskOrderForAllView(displayTasks: [TaskItem], allTasks: inout [TaskItem]) {
        // 分离未完成和已完成的任务
        let activeTasks = displayTasks.filter { !$0.isCompleted }
        let completedTasks = displayTasks.filter { $0.isCompleted }
        
        // 更新未完成任务的顺序
        for (index, task) in activeTasks.enumerated() {
            if let allTasksIndex = allTasks.firstIndex(where: { $0.id == task.id && !$0.isCompleted }) {
                allTasks[allTasksIndex].order = Int32(index)
            }
        }
        
        // 更新已完成任务的顺序
        for (index, task) in completedTasks.enumerated() {
            if let allTasksIndex = allTasks.firstIndex(where: { $0.id == task.id && $0.isCompleted }) {
                allTasks[allTasksIndex].order = Int32(index)
            }
        }
    }
    
    // 更新"进行中"视图中的任务顺序
    private func updateTaskOrderForActiveView(displayTasks: [TaskItem], allTasks: inout [TaskItem]) {
        for (index, task) in displayTasks.enumerated() {
            if let allTasksIndex = allTasks.firstIndex(where: { $0.id == task.id && !$0.isCompleted }) {
                allTasks[allTasksIndex].order = Int32(index)
            }
        }
    }
    
    // 更新"已完成"视图中的任务顺序
    private func updateTaskOrderForCompletedView(displayTasks: [TaskItem], allTasks: inout [TaskItem]) {
        for (index, task) in displayTasks.enumerated() {
            if let allTasksIndex = allTasks.firstIndex(where: { $0.id == task.id && $0.isCompleted }) {
                allTasks[allTasksIndex].order = Int32(index)
            }
        }
    }
    
    // 保存上下文
    public func saveContext() {
        DispatchQueue.main.async {
            guard self.viewContext.hasChanges else { return }
            do {
                try self.viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                let nsError = error as NSError
                print("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}