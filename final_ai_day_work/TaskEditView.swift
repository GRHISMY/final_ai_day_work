//
//  TaskEditView.swift
//  final_ai_day_work
//
//  Created by 慧誉 on 2025/8/16.
//

import SwiftUI
import CoreData

public struct TaskEditView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var task: Task
    @State private var title: String
    @State private var description: String
    @State private var dueDate: Date
    @State private var showingDatePicker = false
    
    private let taskManager: TaskManager
    
    public init(task: Task, taskManager: TaskManager) {
        self.task = task
        self.taskManager = taskManager
        _title = State(initialValue: task.title ?? "")
        _description = State(initialValue: task.desc ?? "")
        _dueDate = State(initialValue: task.dueDate ?? Date())
    }
    
    public var body: some View {
        VStack {
            Form {
                Section(header: Text("任务信息")) {
                    TextField("任务标题", text: $title)
                    TextField("任务描述", text: $description)
                        .lineLimit(3)
                }
                
                Section(header: Text("截止日期")) {
                    Button(action: {
                        showingDatePicker.toggle()
                    }) {
                        HStack {
                            Text("截止日期")
                            Spacer()
                            Text("\(dueDate, formatter: dateFormatter)")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if showingDatePicker {
                        DatePicker(
                            "截止日期",
                            selection: $dueDate,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    }
                }
                
                Section {
                    Button("删除任务", role: .destructive) {
                        deleteTask()
                    }
                }
            }
            
            HStack {
                Button("取消") {
                    dismiss()
                }
                
                Spacer()
                
                Button("保存") {
                    saveTask()
                }
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
        }
        .frame(minWidth: 300, minHeight: 400)
    }
    
    private func saveTask() {
        taskManager.updateTask(task, title: title, description: description, dueDate: dueDate)
        dismiss()
    }
    
    private func deleteTask() {
        taskManager.deleteTask(task)
        dismiss()
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .full
    formatter.timeStyle = .short
    return formatter
}()