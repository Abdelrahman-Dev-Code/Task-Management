class NotificationModel {
  final int id;
  final String type;
  final String title;
  final String body;
  final String? readAt;
  final String createdAt;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.readAt,
    required this.createdAt,
  });

  bool get isRead => readAt != null && readAt!.isNotEmpty;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: (json['id'] as num).toInt(),
      type: (json['type'] ?? 'info') as String,
      title: (json['title'] ?? '') as String,
      body: (json['body'] ?? '') as String,
      readAt: json['read_at'] as String?,
      createdAt: (json['created_at'] ?? '') as String,
    );
  }
}
