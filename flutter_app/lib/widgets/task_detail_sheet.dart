import 'package:flutter/material.dart';
import '../models/task_model.dart';

/// نافذة عرض تفاصيل المهمة كاملة مع أزرار تغيير الحالة والتعديل والحذف
Future<void> showTaskDetailSheet(
  BuildContext context, {
  required TaskModel task,
  required ValueChanged<TaskStatus> onStatusChange,
  required VoidCallback onEdit,
  required VoidCallback onDelete,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text('الحالة: ${task.status.labelAr}')),
                  Chip(label: Text('الأولوية: ${task.priority.labelAr}')),
                  if (task.dueDate != null)
                    Chip(
                      avatar: const Icon(Icons.event_outlined, size: 18),
                      label: Text('الاستحقاق: ${task.dueDate}'),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  (task.description != null && task.description!.isNotEmpty)
                      ? task.description!
                      : 'لا يوجد وصف مضاف لهذه المهمة.',
                  style: const TextStyle(fontSize: 14, height: 1.6),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'تاريخ الإنشاء: ${task.createdAt}\nآخر تحديث: ${task.updatedAt}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.5),
              ),
              const SizedBox(height: 16),
              const Text(
                'تغيير سريع للحالة',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              SegmentedButton<TaskStatus>(
                segments: TaskStatus.values
                    .map((s) => ButtonSegment<TaskStatus>(value: s, label: Text(s.labelAr)))
                    .toList(),
                selected: {task.status},
                onSelectionChanged: (selection) {
                  Navigator.of(ctx).pop();
                  onStatusChange(selection.first);
                },
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        onEdit();
                      },
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('تعديل'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        onDelete();
                      },
                      style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('حذف'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
