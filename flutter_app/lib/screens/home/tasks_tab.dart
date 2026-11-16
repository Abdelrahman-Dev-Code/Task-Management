import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/responsive.dart';
import '../../models/task_model.dart';
import '../../services/session_controller.dart';
import '../../widgets/task_detail_sheet.dart';
import '../../widgets/task_skeleton.dart';
import 'task_form_sheet.dart';

/// تبويب لوحة المهام الرئيسي: إحصائيات تفاعلية، بحث فوري، فلاتر، وتجاوب كامل
class TasksTab extends StatefulWidget {
  final SessionController session;

  const TasksTab({super.key, required this.session});

  @override
  State<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<TasksTab> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  List<TaskModel> _tasks = <TaskModel>[];
  TaskStatsModel _stats = const TaskStatsModel(
    total: 0,
    pending: 0,
    inProgress: 0,
    completed: 0,
    overdue: 0,
  );

  TaskStatus? _statusFilter;
  TaskPriority? _priorityFilter;
  bool _overdueOnly = false;
  String _sortBy = 'created_at';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String _) {
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) _loadAll(showSkeleton: false);
    });
  }

  Future<void> _loadAll({bool showSkeleton = true}) async {
    if (showSkeleton) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else {
      setState(() => _error = null);
    }

    try {
      final results = await Future.wait([
        widget.session.taskService.getTasks(
          search: _searchController.text,
          status: _statusFilter,
          priority: _priorityFilter,
          overdueOnly: _overdueOnly,
          sortBy: _sortBy,
        ),
        widget.session.taskService.getStats(),
      ]);
      if (!mounted) return;
      setState(() {
        _tasks = results[0] as List<TaskModel>;
        _stats = results[1] as TaskStatsModel;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createTask() async {
    final form = await showTaskFormSheet(context);
    if (form == null) return;
    try {
      await widget.session.taskService.createTask(
        title: form.title,
        description: form.description,
        status: form.status,
        priority: form.priority,
        dueDate: form.dueDate,
      );
      await widget.session.refreshUnreadCount();
      await _loadAll(showSkeleton: false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إنشاء المهمة بنجاح')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _editTask(TaskModel task) async {
    final form = await showTaskFormSheet(context, existing: task);
    if (form == null) return;
    try {
      await widget.session.taskService.updateTask(
        task.id,
        title: form.title,
        description: form.description,
        status: form.status,
        priority: form.priority,
        dueDate: form.dueDate,
      );
      await _loadAll(showSkeleton: false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث المهمة بنجاح')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  /// تحديث متفائل سريع للحالة مع التراجع التلقائي عند الفشل
  Future<void> _quickChangeStatus(TaskModel task, TaskStatus nextStatus) async {
    final previousTasks = List<TaskModel>.from(_tasks);
    final idx = _tasks.indexWhere((t) => t.id == task.id);
    if (idx != -1) {
      setState(() {
        _tasks[idx] = TaskModel(
          id: task.id,
          title: task.title,
          description: task.description,
          status: nextStatus,
          priority: task.priority,
          dueDate: task.dueDate,
          createdAt: task.createdAt,
          updatedAt: task.updatedAt,
        );
      });
    }

    try {
      await widget.session.taskService.patchStatus(task.id, nextStatus);
      await _loadAll(showSkeleton: false);
    } catch (e) {
      if (mounted) {
        setState(() => _tasks = previousTasks);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _deleteTask(TaskModel task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف المهمة'),
        content: Text('هل تريد حذف "${task.title}"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await widget.session.taskService.deleteTask(task.id);
      await _loadAll(showSkeleton: false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _clearCompleted() async {
    try {
      final deleted = await widget.session.taskService.deleteCompleted();
      await _loadAll(showSkeleton: false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم حذف $deleted مهمة مكتملة')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  void _clearAllFilters() {
    _searchController.clear();
    setState(() {
      _statusFilter = null;
      _priorityFilter = null;
      _overdueOnly = false;
    });
    _loadAll(showSkeleton: false);
  }

  bool _isOverdue(TaskModel task) {
    if (task.status == TaskStatus.completed || task.dueDate == null) return false;
    final parsed = DateTime.tryParse(task.dueDate!);
    if (parsed == null) return false;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    return parsed.isBefore(todayDate);
  }

  @override
  Widget build(BuildContext context) {
    final columns = Responsive.taskGridColumns(context);
    final hasActiveFilters = _statusFilter != null ||
        _priorityFilter != null ||
        _overdueOnly ||
        _searchController.text.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة المهام', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (_stats.completed > 0)
            IconButton(
              tooltip: 'حذف المهام المكتملة',
              icon: const Icon(Icons.cleaning_services_outlined),
              onPressed: _clearCompleted,
            ),
          PopupMenuButton<String>(
            tooltip: 'ترتيب المهام',
            icon: const Icon(Icons.sort),
            initialValue: _sortBy,
            onSelected: (value) {
              setState(() => _sortBy = value);
              _loadAll(showSkeleton: false);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'created_at', child: Text('الأحدث إنشاءً')),
              PopupMenuItem(value: 'priority', child: Text('الأولوية')),
              PopupMenuItem(value: 'due_date', child: Text('تاريخ الاستحقاق')),
              PopupMenuItem(value: 'title', child: Text('الاسم أبجدياً')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createTask,
        icon: const Icon(Icons.add),
        label: const Text('مهمة جديدة'),
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadAll(showSkeleton: false),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: [
            _buildStatsDashboard(),
            const SizedBox(height: 14),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ابحث بالعنوان أو الوصف...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _loadAll(showSkeleton: false);
                        },
                      )
                    : null,
              ),
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('الكل'),
                    selected: _statusFilter == null && !_overdueOnly,
                    onSelected: (_) {
                      setState(() {
                        _statusFilter = null;
                        _overdueOnly = false;
                      });
                      _loadAll(showSkeleton: false);
                    },
                  ),
                  const SizedBox(width: 8),
                  ...TaskStatus.values.map(
                    (status) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: FilterChip(
                        label: Text(status.labelAr),
                        selected: _statusFilter == status && !_overdueOnly,
                        onSelected: (selected) {
                          setState(() {
                            _overdueOnly = false;
                            _statusFilter = selected ? status : null;
                          });
                          _loadAll(showSkeleton: false);
                        },
                      ),
                    ),
                  ),
                  if (_stats.overdue > 0)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: FilterChip(
                        label: Text('متأخرة (${_stats.overdue})'),
                        selected: _overdueOnly,
                        onSelected: (selected) {
                          setState(() {
                            _statusFilter = null;
                            _overdueOnly = selected;
                          });
                          _loadAll(showSkeleton: false);
                        },
                      ),
                    ),
                  const SizedBox(width: 4),
                  DropdownButton<TaskPriority?>(
                    value: _priorityFilter,
                    hint: const Text('الأولوية'),
                    underline: const SizedBox.shrink(),
                    items: [
                      const DropdownMenuItem<TaskPriority?>(
                        value: null,
                        child: Text('كل الأولويات'),
                      ),
                      ...TaskPriority.values.map(
                        (p) => DropdownMenuItem<TaskPriority?>(
                          value: p,
                          child: Text('أولوية: ${p.labelAr}'),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _priorityFilter = value);
                      _loadAll(showSkeleton: false);
                    },
                  ),
                ],
              ),
            ),
            if (hasActiveFilters)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _clearAllFilters,
                  icon: const Icon(Icons.filter_alt_off, size: 18),
                  label: const Text('مسح الفلاتر'),
                ),
              ),
            const SizedBox(height: 8),
            if (_error != null)
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(_error!, style: TextStyle(color: Colors.red.shade800)),
                      ),
                      TextButton(
                        onPressed: () => _loadAll(),
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_loading)
              const TaskSkeletonList()
            else if (_tasks.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Column(
                  children: [
                    Icon(Icons.task_alt, size: 58, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    const Text('لا توجد مهام مطابقة', style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 6),
                    Text(
                      hasActiveFilters
                          ? 'جرّب تعديل خيارات البحث أو إزالة الفلاتر.'
                          : 'اضغط على "مهمة جديدة" لإضافة أول مهمة لك.',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
              )
            else if (columns == 1)
              ..._tasks.map(_buildTaskCard)
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _tasks.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 175,
                ),
                itemBuilder: (_, index) => _buildTaskCard(_tasks[index], inGrid: true),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsDashboard() {
    final progress = _stats.total == 0 ? 0.0 : _stats.completed / _stats.total;
    final pct = (progress * 100).round();

    return Column(
      children: [
        Row(
          children: [
            _StatBox(
              label: 'الإجمالي',
              value: _stats.total,
              color: const Color(0xFF475569),
              selected: _statusFilter == null && !_overdueOnly,
              onTap: () {
                setState(() {
                  _statusFilter = null;
                  _overdueOnly = false;
                });
                _loadAll(showSkeleton: false);
              },
            ),
            const SizedBox(width: 8),
            _StatBox(
              label: 'انتظار',
              value: _stats.pending,
              color: Colors.amber.shade700,
              selected: _statusFilter == TaskStatus.pending,
              onTap: () {
                setState(() {
                  _overdueOnly = false;
                  _statusFilter =
                      _statusFilter == TaskStatus.pending ? null : TaskStatus.pending;
                });
                _loadAll(showSkeleton: false);
              },
            ),
            const SizedBox(width: 8),
            _StatBox(
              label: 'تنفيذ',
              value: _stats.inProgress,
              color: const Color(0xFF4F46E5),
              selected: _statusFilter == TaskStatus.inProgress,
              onTap: () {
                setState(() {
                  _overdueOnly = false;
                  _statusFilter = _statusFilter == TaskStatus.inProgress
                      ? null
                      : TaskStatus.inProgress;
                });
                _loadAll(showSkeleton: false);
              },
            ),
            const SizedBox(width: 8),
            _StatBox(
              label: 'مكتملة',
              value: _stats.completed,
              color: Colors.green.shade700,
              selected: _statusFilter == TaskStatus.completed,
              onTap: () {
                setState(() {
                  _overdueOnly = false;
                  _statusFilter =
                      _statusFilter == TaskStatus.completed ? null : TaskStatus.completed;
                });
                _loadAll(showSkeleton: false);
              },
            ),
          ],
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Text(
                  'نسبة الإنجاز',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: progress),
                    duration: const Duration(milliseconds: 450),
                    builder: (context, value, _) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: value,
                          minHeight: 8,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$pct%',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskCard(TaskModel task, {bool inGrid = false}) {
    final isCompleted = task.status == TaskStatus.completed;
    final overdue = _isOverdue(task);

    final statusColor = switch (task.status) {
      TaskStatus.pending => Colors.amber.shade700,
      TaskStatus.inProgress => const Color(0xFF4F46E5),
      TaskStatus.completed => Colors.green.shade700,
    };

    final priorityColor = switch (task.priority) {
      TaskPriority.low => Colors.grey.shade600,
      TaskPriority.medium => Colors.blue.shade700,
      TaskPriority.high => Colors.red.shade700,
    };

    return Card(
      margin: inGrid ? EdgeInsets.zero : const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => showTaskDetailSheet(
          context,
          task: task,
          onStatusChange: (next) => _quickChangeStatus(task, next),
          onEdit: () => _editTask(task),
          onDelete: () => _deleteTask(task),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border(
              right: BorderSide(color: priorityColor, width: 4),
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: Checkbox(
                      value: isCompleted,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      onChanged: (checked) {
                        _quickChangeStatus(
                          task,
                          checked == true ? TaskStatus.completed : TaskStatus.pending,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      task.title,
                      maxLines: inGrid ? 2 : 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    onSelected: (action) {
                      if (action == 'edit') {
                        _editTask(task);
                      } else if (action == 'delete') {
                        _deleteTask(task);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('تعديل')),
                      PopupMenuItem(value: 'delete', child: Text('حذف')),
                    ],
                  ),
                ],
              ),
              if (task.description != null && task.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  task.description!,
                  maxLines: inGrid ? 2 : 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
              if (inGrid) const Spacer() else const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  PopupMenuButton<TaskStatus>(
                    onSelected: (next) => _quickChangeStatus(task, next),
                    itemBuilder: (_) => TaskStatus.values
                        .map((s) => PopupMenuItem(value: s, child: Text(s.labelAr)))
                        .toList(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            task.status.labelAr,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(Icons.arrow_drop_down, size: 16, color: statusColor),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: priorityColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'أولوية: ${task.priority.labelAr}',
                      style: TextStyle(
                        color: priorityColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (task.dueDate != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: overdue
                            ? Colors.red.withValues(alpha: 0.12)
                            : Colors.grey.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        overdue ? 'متأخرة: ${task.dueDate}' : task.dueDate!,
                        style: TextStyle(
                          color: overdue ? Colors.red.shade700 : Colors.grey.shade600,
                          fontSize: 11,
                          fontWeight: overdue ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.12) : Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? color : Colors.grey.withValues(alpha: 0.25),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                '$value',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
              ),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }
}
