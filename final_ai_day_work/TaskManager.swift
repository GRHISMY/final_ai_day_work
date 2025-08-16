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
    
    // 更新任务顺序
    public func updateTaskOrder(_ tasks: [Task]) {
        for (index, task) in tasks.enumerated() {
            task.order = Int32(index)
        }
        saveContext()
    }
    
    // 保存上下文
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            let nsError = error as NSError
            print("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}