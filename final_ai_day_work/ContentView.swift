import SwiftUI
import CoreData
import _Concurrency

public struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var taskManager: TaskManager
    @State private var newTaskTitle = ""
    @State private var selectedFilter: TaskFilter = .all
    @State private var showingAddTask = false
    
    // 根据过滤器获取任务
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \TaskItem.isCompleted, ascending: true), 
                         NSSortDescriptor(keyPath: \TaskItem.order, ascending: true)],
        predicate: NSPredicate(format: "markAsDeleted == false"),
        animation: .default)
    private var allTasks: FetchedResults<TaskItem>
    
    private var filteredTasks: [TaskItem] {
        switch selectedFilter {
        case .all:
            return Array(allTasks)
        case .active:
            return allTasks.filter { !$0.isCompleted }
        case .completed:
            return allTasks.filter { $0.isCompleted }
        case .history:
            // 历史记录视图使用专门的HistoryView显示
            return []
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
                
                Button(action: {
                    addTask()
                }) {
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
                        .foregroundColor(selectedFilter == filter ? .blue : .primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                    }
                    .background(selectedFilter == filter ? Color.blue : Color.gray.opacity(0.2))
                    .cornerRadius(20)
                    .animation(.easeInOut, value: selectedFilter)
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            
            // 任务列表
            if selectedFilter == .history {
                // 显示历史记录视图
                HistoryView()
                    .environmentObject(taskManager)
            } else {
                List {
                    ForEach(filteredTasks) { task in
                        TaskRowView(task: task, onUpdate: { updatedTask in
                            // 更新任务状态
                            taskManager.updateTask(updatedTask, isCompleted: updatedTask.isCompleted)
                        }, onDelete: {
                            // 删除单个任务
                            taskManager.deleteTask(task)
                        }, taskManager: taskManager)
                    }
                    .onDelete(perform: { indexSet in
                        // 在后台队列中执行删除操作
                        DispatchQueue.global(qos: .userInitiated).async {
                            DispatchQueue.main.async {
                                deleteTasks(offsets: indexSet)
                            }
                        }
                    })
                    .onMove(perform: { source, destination in
                        // 在后台队列中执行移动操作
                        DispatchQueue.global(qos: .userInitiated).async {
                            DispatchQueue.main.async {
                                moveTasks(source: source, destination: destination)
                            }
                        }
                    })
                }
                .animation(.default, value: filteredTasks.count)
            }
            
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
                
                Button(action: {
                    // 在后台队列中执行清除操作
                    DispatchQueue.global(qos: .userInitiated).async {
                        DispatchQueue.main.async {
                            clearCompletedTasks()
                        }
                    }
                }) {
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
        .frame(minWidth: 320, idealWidth: 360, maxWidth: .infinity, minHeight: 400, idealHeight: 540, maxHeight: .infinity)
        .aspectRatio(3/4, contentMode: .fit)
        .onAppear {
            // 添加一些示例任务用于演示
            if allTasks.isEmpty {
                addSampleTasks()
            }
        }
    }
    
    @MainActor private func addTask() {
        guard !newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        withAnimation {
            _ = taskManager.createTask(title: newTaskTitle)
            newTaskTitle = ""
        }
    }
    
    @MainActor private func deleteTasks(offsets: IndexSet) {
        withAnimation {
            let tasksToDelete = offsets.map { filteredTasks[$0] }
            taskManager.deleteTasks(tasksToDelete)
        }
    }
    
    @MainActor private func clearCompletedTasks() {
        withAnimation {
            let completedTasks = allTasks.filter { $0.isCompleted }
            taskManager.deleteTasks(completedTasks)
        }
    }
    
    // 拖拽移动任务
    @MainActor private func moveTasks(source: IndexSet, destination: Int) {
        // 创建当前显示任务的标识符数组，避免直接引用对象
        let taskIdentifiers = self.filteredTasks.map { $0.objectID }
        
        // 确保目标位置在有效范围内
        let validDestination = min(max(0, destination), taskIdentifiers.count)
        
        // 执行移动操作
        var updatedIdentifiers = taskIdentifiers
        updatedIdentifiers.move(fromOffsets: source, toOffset: validDestination)
        
        // 使用对象ID重新获取任务对象，确保在正确的上下文中访问
        let reorderedTasks = updatedIdentifiers.compactMap { objectID in
            self.viewContext.object(with: objectID) as? TaskItem
        }
        
        // 使用批量更新方法更新任务顺序
        self.taskManager.updateTaskOrderForDisplay(reorderedTasks, allTasks: Array(self.allTasks), filter: self.selectedFilter)
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
    
    @MainActor private func addSampleTasks() {
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
                
                // 进度条颜色根据进度变化
                Rectangle()
                    .fill(progress <= 0.35 ? Color.red : progress <= 0.7 ? Color.orange : Color.green)
                    .frame(width: CGFloat(progress) * geometry.size.width, height: 12)
                    .cornerRadius(6)
            }
        }
        .frame(height: 12)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}