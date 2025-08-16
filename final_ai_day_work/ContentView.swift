//
//  ContentView.swift
//  final_ai_day_work
//
//  Created by 慧誉 on 2025/8/15.
//

import SwiftUI
import CoreData

public struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var taskManager: TaskManager
    @State private var newTaskTitle = ""
    @State private var selectedFilter: TaskFilter = .all
    @State private var showingAddTask = false
    
    // 根据过滤器获取任务
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Task.isCompleted, ascending: true), 
                         NSSortDescriptor(keyPath: \Task.order, ascending: true)],
        animation: .default)
    private var allTasks: FetchedResults<Task>
    
    private var filteredTasks: [Task] {
        switch selectedFilter {
        case .all:
            return Array(allTasks)
        case .active:
            return allTasks.filter { !$0.isCompleted }
        case .completed:
            return allTasks.filter { $0.isCompleted }
        }
    }
    
    private var completionProgress: Double {
        guard !allTasks.isEmpty else { return 0.0 }
        let completedCount = allTasks.filter { $0.isCompleted }.count
        return Double(completedCount) / Double(allTasks.count)
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            // 标题区域
            HStack {
                Text("任务管理器 ✨")
                    .font(.title)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding(.horizontal)
            
            // 添加任务区域
            HStack {
                TextField("输入新任务...", text: $newTaskTitle, onCommit: {
                    addTask()
                })
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onSubmit {
                    addTask()
                }
                
                Button(action: addTask) {
                    HStack {
                        Image(systemName: "plus")
                        Text("添加")
                    }
                }
                .disabled(newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal)
            
            // 筛选器
            HStack {
                ForEach(TaskFilter.allCases, id: \.self) { filter in
                    Button(action: {
                        withAnimation {
                            selectedFilter = filter
                        }
                    }) {
                        HStack {
                            Text(filter.icon)
                            Text(filter.title)
                        }
                        .foregroundColor(selectedFilter == filter ? .white : .primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                    }
                    .background(selectedFilter == filter ? Color.blue : Color.gray.opacity(0.2))
                    .cornerRadius(20)
                    .animation(.easeInOut, value: selectedFilter)
                }
                Spacer()
            }
            .padding(.horizontal)
            
            // 任务列表
            List {
                ForEach(filteredTasks) { task in
                    TaskRowView(task: task, onUpdate: { updatedTask in
                        // 更新任务状态
                        taskManager.updateTask(updatedTask, isCompleted: updatedTask.isCompleted)
                    }, taskManager: taskManager)
                }
                .onDelete(perform: deleteTasks)
                .onMove(perform: moveTasks)
            }
            .animation(.default, value: filteredTasks.count)
            
            // 进度条区域
            VStack(spacing: 8) {
                HStack {
                    progressEmoji(for: completionProgress)
                        .font(.caption)
                    ProgressView(value: completionProgress, total: 1.0)
                        .progressViewStyle(GradientProgressViewStyle(progress: completionProgress))
                    Text("\(Int(completionProgress * 100))%")
                        .font(.caption)
                        .frame(width: 30, alignment: .trailing)
                }
                
                Button(action: clearCompletedTasks) {
                    HStack {
                        Image(systemName: "trash")
                        Text("🧹 清除已完成任务")
                    }
                }
                .disabled(!allTasks.contains { $0.isCompleted })
                .padding(.top, 4)
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .frame(minWidth: 320, idealWidth: 360, maxWidth: 420, minHeight: 400, idealHeight: 540, maxHeight: 700)
        .onAppear {
            // 添加一些示例任务用于演示
            if allTasks.isEmpty {
                addSampleTasks()
            }
        }
    }
    
    private func addTask() {
        guard !newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        withAnimation {
            let newTask = taskManager.createTask(title: newTaskTitle)
            newTaskTitle = ""
        }
    }
    
    private func deleteTasks(offsets: IndexSet) {
        withAnimation {
            let tasksToDelete = offsets.map { filteredTasks[$0] }
            taskManager.deleteTasks(tasksToDelete)
        }
    }
    
    private func clearCompletedTasks() {
        withAnimation {
            let completedTasks = allTasks.filter { $0.isCompleted }
            taskManager.deleteTasks(completedTasks)
        }
    }
    
    // 拖拽移动任务
    private func moveTasks(source: IndexSet, destination: Int) {
        // 在"全部"视图中，分别处理未完成和已完成任务
        if selectedFilter == .all {
            moveTasksInAllView(source: source, destination: destination)
        } else {
            // 在筛选视图中，只允许在同类型任务间移动
            moveTasksInFilteredView(source: source, destination: destination)
        }
    }
    
    // 在"全部"视图中移动任务
    private func moveTasksInAllView(source: IndexSet, destination: Int) {
        // 分别处理未完成和已完成任务
        let activeTasks = filteredTasks.filter { !$0.isCompleted }
        let completedTasks = filteredTasks.filter { $0.isCompleted }
        
        // 获取源任务的索引
        let sourceIndices = Array(source)
        
        // 检查是否所有源任务都是同一类型
        let sourceTasks = sourceIndices.map { filteredTasks[$0] }
        let areAllActive = sourceTasks.allSatisfy { !$0.isCompleted }
        let areAllCompleted = sourceTasks.allSatisfy { $0.isCompleted }
        
        // 只有当所有源任务都是同一类型时才允许移动
        guard areAllActive || areAllCompleted else { return }
        
        if areAllActive {
            // 移动未完成任务
            moveActiveTasks(source: source, destination: destination, activeTasks: activeTasks)
        } else if areAllCompleted {
            // 移动已完成任务
            moveCompletedTasks(source: source, destination: destination, completedTasks: completedTasks)
        }
    }
    
    // 移动未完成任务
    private func moveActiveTasks(source: IndexSet, destination: Int, activeTasks: [Task]) {
        // 创建未完成任务数组副本
        var activeTasksArray = activeTasks
        
        // 计算在filteredTasks中的实际索引
        let activeTaskIndices = filteredTasks.enumerated().compactMap { index, task in
            !task.isCompleted ? index : nil
        }
        
        // 转换源索引到未完成任务数组中的索引
        let sourceInActive = source.compactMap { sourceIndex in
            activeTaskIndices.firstIndex(of: sourceIndex)
        }
        
        // 确保目标位置在有效范围内
        let activeDestination = min(destination, activeTasksArray.count)
        
        // 执行移动操作
        activeTasksArray.move(fromOffsets: IndexSet(sourceInActive), toOffset: activeDestination)
        
        // 更新未完成任务的顺序
        for (index, task) in activeTasksArray.enumerated() {
            taskManager.updateTask(task, order: Int32(index))
        }
    }
    
    // 移动已完成任务
    private func moveCompletedTasks(source: IndexSet, destination: Int, completedTasks: [Task]) {
        // 创建已完成任务数组副本
        var completedTasksArray = completedTasks
        
        // 计算在filteredTasks中的实际索引
        let completedTaskIndices = filteredTasks.enumerated().compactMap { index, task in
            task.isCompleted ? index : nil
        }
        
        // 转换源索引到已完成任务数组中的索引
        let sourceInCompleted = source.compactMap { sourceIndex in
            completedTaskIndices.firstIndex(of: sourceIndex)
        }
        
        // 确保目标位置在有效范围内
        let completedDestination = min(destination, completedTasksArray.count)
        
        // 执行移动操作
        completedTasksArray.move(fromOffsets: IndexSet(sourceInCompleted), toOffset: completedDestination)
        
        // 更新已完成任务的顺序
        for (index, task) in completedTasksArray.enumerated() {
            taskManager.updateTask(task, order: Int32(index))
        }
    }
    
    // 在筛选视图中移动任务
    private func moveTasksInFilteredView(source: IndexSet, destination: Int) {
        // 在筛选视图中，所有任务都是同一类型的，所以可以直接移动
        var tasksArray = Array(filteredTasks)
        
        // 确保目标位置在有效范围内
        let validDestination = min(destination, tasksArray.count)
        
        // 执行移动操作
        tasksArray.move(fromOffsets: source, toOffset: validDestination)
        
        // 更新任务顺序
        for (index, task) in tasksArray.enumerated() {
            taskManager.updateTask(task, order: Int32(index))
        }
    }
    
    private func progressEmoji(for progress: Double) -> Text {
        switch progress {
        case 0..<0.25:
            return Text("🌱")
        case 0.25..<0.5:
            return Text("🌿")
        case 0.5..<0.75:
            return Text("🌳")
        case 0.75..<1.0:
            return Text("🎯")
        case 1.0:
            return Text("🎉")
        default:
            return Text("📋")
        }
    }
    
    private func addSampleTasks() {
        let sampleTasks = [
            "完成项目计划书",
            "准备会议材料",
            "回复客户邮件",
            "学习新技术"
        ]
        
        for (index, title) in sampleTasks.enumerated() {
            let newTask = taskManager.createTask(title: title)
            // 设置一些任务为已完成状态
            if index % 3 == 0 {
                taskManager.updateTask(newTask, isCompleted: true)
            }
        }
    }
}

// 任务筛选枚举
enum TaskFilter: CaseIterable {
    case all, active, completed
    
    var title: String {
        switch self {
        case .all: return "全部"
        case .active: return "进行中"
        case .completed: return "已完成"
        }
    }
    
    var icon: String {
        switch self {
        case .all: return "📋"
        case .active: return "⏳"
        case .completed: return "✅"
        }
    }
}

// 任务行视图
struct TaskRowView: View {
    @ObservedObject var task: Task
    @State private var showingEditView = false
    @State private var isHovering = false
    var onUpdate: (Task) -> Void
    var taskManager: TaskManager
    
    var body: some View {
        HStack {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    // 切换完成状态
                    task.isCompleted.toggle()
                    onUpdate(task)
                }
            }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .primary)
                    .font(.title3)
                    .scaleEffect(isHovering ? 1.1 : 1.0)
            }
            .buttonStyle(PlainButtonStyle())
            .onHover { hovering in
                isHovering = hovering
            }
            
            VStack(alignment: .leading) {
                Text(task.title ?? "未命名任务")
                    .strikethrough(task.isCompleted)
                    .foregroundColor(task.isCompleted ? .secondary : .primary)
                    .animation(.none, value: task.isCompleted)
                
                if let dueDate = task.dueDate {
                    Text("截止时间: \(dueDate, formatter: dateFormatter)")
                        .font(.caption)
                        .foregroundColor(dueDate < Date() ? .red : .secondary)
                }
            }
            
            Spacer()
            
            if task.isCompleted {
                Text("✅")
                    .transition(.scale)
            } else if let dueDate = task.dueDate, dueDate < Date() {
                Text("⏰")
                    .transition(.scale)
            } else if let dueDate = task.dueDate, Calendar.current.isDateInToday(dueDate) {
                Text("🎯")
                    .transition(.scale)
            }
            
            // 编辑按钮
            Button(action: {
                showingEditView = true
            }) {
                Image(systemName: "pencil")
                    .foregroundColor(.blue)
            }
            .buttonStyle(PlainButtonStyle())
            .opacity(isHovering ? 1.0 : 0.0)
            .animation(.easeInOut(duration: 0.2), value: isHovering)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle()) // 使整个区域可响应悬停
        .onHover { hovering in
            isHovering = hovering
        }
        .sheet(isPresented: $showingEditView) {
            TaskEditView(task: task, taskManager: taskManager)
        }
    }
}

// 渐变进度条样式
struct GradientProgressViewStyle: ProgressViewStyle {
    let progress: Double
    
    func makeBody(configuration: Configuration) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // 背景
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 12)
                    .cornerRadius(6)
                
                // 渐变进度
                Rectangle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [
                            Color.red,
                            Color.orange,
                            Color.green
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(width: CGFloat(progress) * geometry.size.width, height: 12)
                    .cornerRadius(6)
            }
        }
        .frame(height: 12)
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter
}()

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}