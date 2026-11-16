import 'package:flutter/material.dart';
import '../../core/date_formatter.dart';
import '../../models/notification_model.dart';
import '../../services/session_controller.dart';

/// تبويب الإشعارات: تحديث متفائل فوري، دعم الوضع الداكن، وتنسيق زمني عربي
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
      _loading = _items.isEmpty;
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
    final nowIso = DateTime.now().toIso8601String();
    final previous = List<NotificationModel>.from(_items);
    setState(() {
      _items = _items
          .map(
            (n) => n.isRead
                ? n
                : NotificationModel(
                    id: n.id,
                    type: n.type,
                    title: n.title,
                    body: n.body,
                    readAt: nowIso,
                    createdAt: n.createdAt,
                  ),
          )
          .toList();
    });
    widget.session.updateUnreadCount(0);

    try {
      await widget.session.notificationService.markAllRead();
    } catch (e) {
      if (mounted) {
        setState(() => _items = previous);
        widget.session.updateUnreadCount(previous.where((n) => !n.isRead).length);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _markRead(NotificationModel item) async {
    if (item.isRead) return;
    final nowIso = DateTime.now().toIso8601String();
    final idx = _items.indexWhere((n) => n.id == item.id);
    if (idx == -1) return;

    final previous = List<NotificationModel>.from(_items);
    setState(() {
      _items[idx] = NotificationModel(
        id: item.id,
        type: item.type,
        title: item.title,
        body: item.body,
        readAt: nowIso,
        createdAt: item.createdAt,
      );
    });
    widget.session.updateUnreadCount(_items.where((n) => !n.isRead).length);

    try {
      await widget.session.notificationService.markRead(item.id);
    } catch (_) {
      if (mounted) {
        setState(() => _items = previous);
        widget.session.updateUnreadCount(previous.where((n) => !n.isRead).length);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات', style: TextStyle(fontWeight: FontWeight.bold)),
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
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    children: [
                      Card(
                        color: scheme.errorContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: scheme.onErrorContainer),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: TextStyle(color: scheme.onErrorContainer),
                                ),
                              ),
                              TextButton(
                                onPressed: _load,
                                child: const Text('إعادة المحاولة'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : _items.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(48),
                        children: [
                          Icon(
                            Icons.notifications_off_outlined,
                            size: 56,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          const Center(
                            child: Text('لا توجد إشعارات حالياً', style: TextStyle(fontSize: 16)),
                          ),
                        ],
                      )
                    : Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 760),
                          child: ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            itemCount: _items.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (_, index) {
                              final item = _items[index];
                              final unreadBg = scheme.primaryContainer.withValues(alpha: 0.32);

                              return Card(
                                color: item.isRead ? null : unreadBg,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: item.isRead
                                        ? scheme.outlineVariant.withValues(alpha: 0.5)
                                        : scheme.primary.withValues(alpha: 0.4),
                                  ),
                                ),
                                child: ListTile(
                                  onTap: () => _markRead(item),
                                  leading: CircleAvatar(
                                    backgroundColor: item.isRead
                                        ? scheme.surfaceContainerHighest
                                        : scheme.primary.withValues(alpha: 0.14),
                                    child: Icon(
                                      item.isRead
                                          ? Icons.notifications_none
                                          : Icons.notifications_active,
                                      color: item.isRead ? Colors.grey : scheme.primary,
                                    ),
                                  ),
                                  title: Text(
                                    item.title,
                                    style: TextStyle(
                                      fontWeight:
                                          item.isRead ? FontWeight.w600 : FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(item.body),
                                      const SizedBox(height: 6),
                                      Text(
                                        DateFormatter.formatRelative(item.createdAt),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: item.isRead
                                      ? null
                                      : Container(
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            color: scheme.primary,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
      ),
    );
  }
}
