//
//  TaskFilter.swift
//  final_ai_day_work
//
//  Created by 慧誉 on 2025/8/16.
//

import Foundation

// 任务筛选枚举
public enum TaskFilter: CaseIterable {
    case all, active, completed, history
    
    public var title: String {
        switch self {
        case .all: return "全部"
        case .active: return "进行"
        case .completed: return "完成"
        case .history: return "历史"
        }
    }
    
    public var icon: String {
        switch self {
        case .all: return "📋"
        case .active: return "⏳"
        case .completed: return "✅"
        case .history: return "📚"
        }
    }
}