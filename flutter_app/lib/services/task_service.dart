import '../models/task_model.dart';
import 'api_client.dart';

/// خدمة إدارة المهام والتصفية والإحصائيات عبر REST API
class TaskService {
  final ApiClient _client;

  TaskService(this._client);

  /// جلب المهام مع دعم البحث، التصفية حسب الحالة/الأولوية/المتأخرة، والترتيب
  Future<List<TaskModel>> getTasks({
    String? search,
    TaskStatus? status,
    TaskPriority? priority,
    bool overdueOnly = false,
    String sortBy = 'created_at',
    String sortDir = 'desc',
  }) async {
    final query = <String, String>{
      'sort_by': sortBy,
      'sort_dir': sortDir,
    };
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }
    if (status != null) {
      query['status'] = status.apiValue;
    }
    if (priority != null) {
      query['priority'] = priority.apiValue;
    }
    if (overdueOnly) {
      query['overdue'] = 'true';
    }

    final data = await _client.get('/api/tasks', query: query);
    final list = (data['data'] as List<dynamic>? ?? <dynamic>[]);
    return list
        .map((item) => TaskModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// جلب إحصائيات المهام للوحة المتابعة
  Future<TaskStatsModel> getStats() async {
    final data = await _client.get('/api/tasks/stats');
    return TaskStatsModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<TaskModel> createTask({
    required String title,
    String? description,
    required TaskStatus status,
    required TaskPriority priority,
    String? dueDate,
  }) async {
    final data = await _client.post('/api/tasks', body: {
      'title': title.trim(),
      'description': description?.trim().isNotEmpty == true ? description!.trim() : null,
      'status': status.apiValue,
      'priority': priority.apiValue,
      'due_date': dueDate,
    });
    return TaskModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<TaskModel> updateTask(
    int id, {
    required String title,
    String? description,
    required TaskStatus status,
    required TaskPriority priority,
    String? dueDate,
  }) async {
    final data = await _client.put('/api/tasks/$id', body: {
      'title': title.trim(),
      'description': description?.trim().isNotEmpty == true ? description!.trim() : null,
      'status': status.apiValue,
      'priority': priority.apiValue,
      'due_date': dueDate,
    });
    return TaskModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  /// تحديث جزئي سريع لحالة المهمة
  Future<TaskModel> patchStatus(int id, TaskStatus status) async {
    final data = await _client.patch('/api/tasks/$id', body: {
      'status': status.apiValue,
    });
    return TaskModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteTask(int id) async {
    await _client.delete('/api/tasks/$id');
  }

  Future<int> deleteCompleted() async {
    final data = await _client.delete('/api/tasks/completed');
    return (data['deleted_count'] as num? ?? 0).toInt();
  }
}
