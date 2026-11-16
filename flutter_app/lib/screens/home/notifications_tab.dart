import 'package:flutter/material.dart';
import '../../models/notification_model.dart';
import '../../services/session_controller.dart';

class NotificationsTab extends StatefulWidget {
  final SessionController session;

  const NotificationsTab({super.key, required this.session});

  @override
  State<NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<NotificationsTab> {
  List<NotificationModel> _items = <NotificationModel>[];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final feed = await widget.session.notificationService.getNotifications();
      if (!mounted) return;
      setState(() => _items = feed.items);
      widget.session.updateUnreadCount(feed.unreadCount);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markAllRead() async {
    try {
      await widget.session.notificationService.markAllRead();
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _markRead(NotificationModel item) async {
    if (item.isRead) return;
    try {
      await widget.session.notificationService.markRead(item.id);
      await _load();
    } catch (_) {
      // Ignore transient read mark failure
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        actions: [
          if (_items.any((n) => !n.isRead))
            TextButton(
              onPressed: _markAllRead,
              child: const Text('تحديد الكل كمقروء'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(
                    padding: const EdgeInsets.all(20),
                    children: [Text(_error!)],
                  )
                : _items.isEmpty
                    ? ListView(
                        padding: const EdgeInsets.all(40),
                        children: const [
                          Center(child: Text('لا توجد إشعارات حالياً')),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, index) {
                          final item = _items[index];
                          return Card(
                            elevation: 0,
                            color: item.isRead ? Colors.white : Colors.indigo.shade50,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                color: item.isRead
                                    ? Colors.grey.shade200
                                    : Colors.indigo.shade200,
                              ),
                            ),
                            child: ListTile(
                              onTap: () => _markRead(item),
                              leading: Icon(
                                item.isRead
                                    ? Icons.notifications_none
                                    : Icons.notifications_active,
                                color: item.isRead ? Colors.grey : const Color(0xFF4F46E5),
                              ),
                              title: Text(
                                item.title,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(item.body),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.createdAt,
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
