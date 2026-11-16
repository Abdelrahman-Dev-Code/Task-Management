enum TaskStatus {
  pending('Pending', 'قيد الانتظار'),
  inProgress('In Progress', 'قيد التنفيذ'),
  completed('Completed', 'مكتملة');

  final String apiValue;
  final String labelAr;

  const TaskStatus(this.apiValue, this.labelAr);

  static TaskStatus fromApi(String? value) {
    return TaskStatus.values.firstWhere(
      (e) => e.apiValue == value,
      orElse: () => TaskStatus.pending,
    );
  }
}

enum TaskPriority {
  low('Low', 'منخفضة'),
  medium('Medium', 'متوسطة'),
  high('High', 'عالية');

  final String apiValue;
  final String labelAr;

  const TaskPriority(this.apiValue, this.labelAr);

  static TaskPriority fromApi(String? value) {
    return TaskPriority.values.firstWhere(
      (e) => e.apiValue == value,
      orElse: () => TaskPriority.medium,
    );
  }
}

class TaskModel {
  final int id;
  final String title;
  final String? description;
  final TaskStatus status;
  final TaskPriority priority;
  final String? dueDate;
  final String createdAt;
  final String updatedAt;

  const TaskModel({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    required this.priority,
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: (json['id'] as num).toInt(),
      title: (json['title'] ?? '') as String,
      description: json['description'] as String?,
      status: TaskStatus.fromApi(json['status'] as String?),
      priority: TaskPriority.fromApi(json['priority'] as String?),
      dueDate: json['due_date'] as String?,
      createdAt: (json['created_at'] ?? '') as String,
      updatedAt: (json['updated_at'] ?? '') as String,
    );
  }
}

class TaskStatsModel {
  final int total;
  final int pending;
  final int inProgress;
  final int completed;
  final int overdue;

  const TaskStatsModel({
    required this.total,
    required this.pending,
    required this.inProgress,
    required this.completed,
    required this.overdue,
  });

  factory TaskStatsModel.fromJson(Map<String, dynamic> json) {
    return TaskStatsModel(
      total: (json['total'] as num? ?? 0).toInt(),
      pending: (json['pending'] as num? ?? 0).toInt(),
      inProgress: (json['in_progress'] as num? ?? 0).toInt(),
      completed: (json['completed'] as num? ?? 0).toInt(),
      overdue: (json['overdue'] as num? ?? 0).toInt(),
    );
  }
}
