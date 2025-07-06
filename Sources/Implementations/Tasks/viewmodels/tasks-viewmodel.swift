import Foundation
import Structures
import Combine
import Extensions

public class TaskListViewModel: ObservableObject {
    @Published public var tasks: [TaskItem] = []
    @Published public var projects: [TaskProject] = []
    @Published public var sortOption: TaskSortOption = .dateCreatedDesc

    private var timerCancellable: AnyCancellable?
    @Published public var now: Date = Date()

    public init(tasks: [TaskItem] = [], projects: [TaskProject] = []) {
        self.tasks    = tasks
        self.projects = projects

        timerCancellable = Timer
            .publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] date in
                self?.now = date
            }
    }

    public var sortedTaskItems: [TaskItem] {
        tasks.sorted { a, b in
            switch sortOption {
            case .urgencyDesc:      return a.urgency    > b.urgency
            case .urgencyAsc:       return a.urgency    < b.urgency
            case .importanceDesc:   return a.importance > b.importance
            case .importanceAsc:    return a.importance < b.importance
            case .dateCreatedDesc:  return a.dateCreated > b.dateCreated
            case .dateCreatedAsc:   return a.dateCreated < b.dateCreated
            case .deadlineDesc:     return a.deadline    > b.deadline
            case .deadlineAsc:      return a.deadline    < b.deadline
            }
        }
    }

    public func add(_ task: TaskItem) {
        tasks.append(task)
    }

    public func remove(at offsets: IndexSet) {
        let all       = sortedTaskItems
        let toRemove  = offsets.map { all[$0].id }
        tasks.removeAll { toRemove.contains($0.id) }
    }

    public func toggleCompletion(of task: TaskItem) {
        update(task) { $0.completion.toggle() }
    }
    public func updateTitle(of task: TaskItem, to newText: String) {
        update(task) { $0.title = newText }
    }
    public func updateDescription(of task: TaskItem, to newText: String) {
        update(task) { $0.description = newText }
    }
    public func updateDeadline(of task: TaskItem, to date: Date) {
        update(task) { $0.deadline = date }
    }
    public func updateUrgency(of task: TaskItem, to level: Int) {
        update(task) { $0.urgency = level }
    }
    public func updateImportance(of task: TaskItem, to level: Int) {
        update(task) { $0.importance = level }
    }
    public func updateTaskProject(of task: TaskItem, to project: TaskProject) {
        update(task) { $0.project = project }
    }
    public func updateDepartment(of task: TaskItem, to dept: TaskDepartment) {
        update(task) { $0.department = dept }
    }

    private func update(_ task: TaskItem, mutation: (inout TaskItem) -> Void) {
        guard let idx = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        var mod = tasks[idx]
        mutation(&mod)
        tasks[idx] = mod
    }

    public func timeOpen(for task: TaskItem) -> String {
        now.timeIntervalSince(task.dateCreated).formattedDuration
    }

    public func timeLeft(for task: TaskItem) -> String {
        let rem = task.deadline.timeIntervalSince(now)
        return rem > 0
            ? rem.formattedDuration
            : "Overdue"
    }

    public func isOverdue(_ task: TaskItem) -> Bool {
        task.deadline < now
    }
}
