import 'package:flutter/material.dart';
import '../../models/task_model.dart';

class TaskFormResult {
  final String title;
  final String? description;
  final TaskStatus status;
  final TaskPriority priority;
  final String? dueDate;

  const TaskFormResult({
    required this.title,
    this.description,
    required this.status,
    required this.priority,
    this.dueDate,
  });
}

Future<TaskFormResult?> showTaskFormSheet(
  BuildContext context, {
  TaskModel? existing,
}) {
  return showModalBottomSheet<TaskFormResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _TaskFormSheetBody(existing: existing),
  );
}

class _TaskFormSheetBody extends StatefulWidget {
  final TaskModel? existing;

  const _TaskFormSheetBody({this.existing});

  @override
  State<_TaskFormSheetBody> createState() => _TaskFormSheetBodyState();
}

class _TaskFormSheetBodyState extends State<_TaskFormSheetBody> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late TaskStatus _status;
  late TaskPriority _priority;
  String? _dueDate;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existing?.title ?? '');
    _descController = TextEditingController(text: widget.existing?.description ?? '');
    _status = widget.existing?.status ?? TaskStatus.pending;
    _priority = widget.existing?.priority ?? TaskPriority.medium;
    _dueDate = widget.existing?.dueDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final initial = _dueDate != null ? (DateTime.tryParse(_dueDate!) ?? now) : now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      final mm = picked.month.toString().padLeft(2, '0');
      final dd = picked.day.toString().padLeft(2, '0');
      setState(() => _dueDate = '${picked.year}-$mm-$dd');
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      TaskFormResult(
        title: _titleController.text.trim(),
        description: _descController.text.trim().isNotEmpty ? _descController.text.trim() : null,
        status: _status,
        priority: _priority,
        dueDate: _dueDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isEdit = widget.existing != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 20),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEdit ? 'تعديل المهمة' : 'إضافة مهمة جديدة',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'عنوان المهمة',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'عنوان المهمة مطلوب';
                  if (v.trim().length > 255) return 'الحد الأقصى 255 حرفاً';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'الوصف (اختياري)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<TaskStatus>(
                      value: _status,
                      decoration: const InputDecoration(
                        labelText: 'الحالة',
                        border: OutlineInputBorder(),
                      ),
                      items: TaskStatus.values
                          .map((s) => DropdownMenuItem(value: s, child: Text(s.labelAr)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _status = v);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<TaskPriority>(
                      value: _priority,
                      decoration: const InputDecoration(
                        labelText: 'الأولوية',
                        border: OutlineInputBorder(),
                      ),
                      items: TaskPriority.values
                          .map((p) => DropdownMenuItem(value: p, child: Text(p.labelAr)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _priority = v);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickDueDate,
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(
                  _dueDate != null ? 'تاريخ الاستحقاق: $_dueDate' : 'تحديد تاريخ الاستحقاق (اختياري)',
                ),
              ),
              if (_dueDate != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => setState(() => _dueDate = null),
                    child: const Text('إزالة التاريخ'),
                  ),
                ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(isEdit ? 'حفظ التعديلات' : 'إضافة المهمة'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
