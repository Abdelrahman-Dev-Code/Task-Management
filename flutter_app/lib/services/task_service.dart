import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_model.dart';
import 'api_client.dart';

/// نتيجة صفحة المهام مع بيانات الترقيم (Pagination)
class TaskPageResult {
  final List<TaskModel> tasks;
  final int total;
  final int page;
  final int lastPage;

  const TaskPageResult({
    required this.tasks,
    required this.total,
    required this.page,
    required this.lastPage,
  });

  bool get hasMore => page < lastPage;
}

class CachedTasksSnapshot {
  final List<TaskModel> tasks;
  final TaskStatsModel stats;

  const CachedTasksSnapshot({required this.tasks, required this.stats});
}

/// خدمة إدارة المهام والتصفية والإحصائيات والترقيم مع تخزين مؤقت فوري
class TaskService {
  static const _cacheTasksKey = 'cached_tasks_v1';
  static const _cacheStatsKey = 'cached_stats_v1';

  final ApiClient _client;

  TaskService(this._client);

  /// جلب المهام مع دعم البحث، التصفية، الترتيب، والترقيم
  Future<TaskPageResult> getTasks({
    String? search,
    TaskStatus? status,
    TaskPriority? priority,
    bool overdueOnly = false,
    String sortBy = 'created_at',
    String sortDir = 'desc',
    int page = 1,
    int perPage = 20,
  }) async {
    final query = <String, String>{
      'sort_by': sortBy,
      'sort_dir': sortDir,
      'page': '$page',
      'per_page': '$perPage',
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
    final list = (data['data'] as List<dynamic>? ?? <dynamic>[])
        .map((item) => TaskModel.fromJson(item as Map<String, dynamic>))
        .toList();
    final meta = data['meta'] as Map<String, dynamic>?;

    return TaskPageResult(
      tasks: list,
      total: (meta?['total'] as num? ?? list.length).toInt(),
      page: (meta?['page'] as num? ?? page).toInt(),
      lastPage: (meta?['last_page'] as num? ?? 1).toInt(),
    );
  }

  /// جلب إحصائيات المهام للوحة المتابعة
  Future<TaskStatsModel> getStats() async {
    final data = await _client.get('/api/tasks/stats');
    return TaskStatsModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<void> saveCache(List<TaskModel> tasks, TaskStatsModel stats) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _cacheTasksKey,
      jsonEncode(tasks.take(30).map((t) => t.toJson()).toList()),
    );
    await prefs.setString(_cacheStatsKey, jsonEncode(stats.toJson()));
  }

  Future<CachedTasksSnapshot?> loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksRaw = prefs.getString(_cacheTasksKey);
      final statsRaw = prefs.getString(_cacheStatsKey);
      if (tasksRaw == null || statsRaw == null) return null;

      final decodedTasks = (jsonDecode(tasksRaw) as List<dynamic>)
          .map((e) => TaskModel.fromJson(e as Map<String, dynamic>))
          .toList();
      final decodedStats =
          TaskStatsModel.fromJson(jsonDecode(statsRaw) as Map<String, dynamic>);
      return CachedTasksSnapshot(tasks: decodedTasks, stats: decodedStats);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheTasksKey);
    await prefs.remove(_cacheStatsKey);
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
