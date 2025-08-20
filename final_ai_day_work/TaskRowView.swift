import SwiftUI
import CoreData

public struct TaskRowView: View {
    @ObservedObject var task: TaskItem
    var onUpdate: (TaskItem) -> Void
    var onDelete: () -> Void
    var taskManager: TaskManager
    
    @State private var showingEditView = false
    @State private var isHovering = false
    
    public var body: some View {
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
            
            // 删除按钮
            Button(action: {
                onDelete()
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
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

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter
}()