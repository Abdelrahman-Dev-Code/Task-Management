import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_management_flutter/core/app_theme.dart';
import 'package:task_management_flutter/core/date_formatter.dart';
import 'package:task_management_flutter/models/notification_model.dart';
import 'package:task_management_flutter/models/task_model.dart';
import 'package:task_management_flutter/models/user_model.dart';

void main() {
  group('Models JSON serialization', () {
    test('UserModel parses Laravel and Node payloads consistently', () {
      final user = UserModel.fromJson({
        'id': 1,
        'name': 'أحمد محمد',
        'email': 'ahmed@example.com',
        'avatar': null,
        'provider': 'google',
        'google_id': 'g-123',
        'has_password': false,
        'email_verified_at': '2026-11-16T10:00:00Z',
        'created_at': '2026-11-16T10:00:00Z',
        'updated_at': '2026-11-16T10:00:00Z',
      });

      expect(user.id, 1);
      expect(user.isEmailVerified, isTrue);
      expect(user.hasPassword, isFalse);
      expect(user.toJson()['provider'], 'google');
    });

    test('TaskModel & TaskStatsModel round-trip cleanly', () {
      final task = TaskModel.fromJson({
        'id': 7,
        'title': 'اختبار Flutter',
        'description': 'تفاصيل المهمة',
        'status': 'In Progress',
        'priority': 'High',
        'due_date': '2026-11-20',
        'created_at': '2026-11-16T10:00:00Z',
        'updated_at': '2026-11-16T10:00:00Z',
      });

      expect(task.status, TaskStatus.inProgress);
      expect(task.priority, TaskPriority.high);
      expect(task.copyWith(status: TaskStatus.completed).status, TaskStatus.completed);

      final stats = TaskStatsModel.fromJson({
        'total': 5,
        'pending': 2,
        'in_progress': 1,
        'completed': 2,
        'overdue': 1,
      });
      expect(stats.total, 5);
      expect(stats.toJson()['overdue'], 1);
    });

    test('NotificationModel tracks read state', () {
      final unread = NotificationModel.fromJson({
        'id': 10,
        'type': 'task_created',
        'title': 'مهمة جديدة',
        'body': 'تم إنشاء مهمة',
        'read_at': null,
        'created_at': '2026-11-16T10:00:00Z',
      });
      expect(unread.isRead, isFalse);
    });
  });

  group('DateFormatter & Themes', () {
    test('DateFormatter handles MySQL and ISO dates', () {
      expect(DateFormatter.tryParse('2026-11-16 14:30:00'), isNotNull);
      expect(DateFormatter.tryParse('2026-11-16T14:30:00Z'), isNotNull);
      expect(DateFormatter.formatDueDate('2020-01-01'), contains('متأخرة'));
    });

    test('Light and Dark Material3 themes build cleanly', () {
      expect(AppTheme.light().brightness, Brightness.light);
      expect(AppTheme.dark().brightness, Brightness.dark);
    });
  });
}
