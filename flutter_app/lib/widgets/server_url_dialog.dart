import 'package:flutter/material.dart';
import '../core/app_config.dart';
import '../services/session_controller.dart';

Future<void> showServerUrlDialog(BuildContext context, SessionController session) async {
  final controller = TextEditingController(text: session.baseUrl);
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('إعداد عنوان الخادم (API URL)'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: controller,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(
                labelText: 'Base URL',
                hintText: 'https://...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  label: const Text('الخادم السحابي'),
                  onPressed: () => controller.text = AppConfig.defaultBaseUrl,
                ),
                ActionChip(
                  label: const Text('محاكي Android'),
                  onPressed: () => controller.text = 'http://10.0.2.2:3000',
                ),
                ActionChip(
                  label: const Text('Localhost'),
                  onPressed: () => controller.text = 'http://localhost:3000',
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: () async {
            await session.updateBaseUrl(controller.text);
            if (ctx.mounted) {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم تحديث عنوان الخادم بنجاح')),
              );
            }
          },
          child: const Text('حفظ'),
        ),
      ],
    ),
  );
}
