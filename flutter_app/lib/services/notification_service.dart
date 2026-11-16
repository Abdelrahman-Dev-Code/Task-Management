import '../models/notification_model.dart';
import 'api_client.dart';

class NotificationFeed {
  final List<NotificationModel> items;
  final int unreadCount;

  const NotificationFeed({required this.items, required this.unreadCount});
}

class NotificationService {
  final ApiClient _client;

  NotificationService(this._client);

  Future<NotificationFeed> getNotifications() async {
    final data = await _client.get('/api/notifications');
    final list = (data['data'] as List<dynamic>? ?? <dynamic>[])
        .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final unread = (data['unread_count'] as num? ?? 0).toInt();
    return NotificationFeed(items: list, unreadCount: unread);
  }

  Future<void> markRead(int id) async {
    await _client.patch('/api/notifications/$id/read');
  }

  Future<void> markAllRead() async {
    await _client.post('/api/notifications/read-all');
  }
}
