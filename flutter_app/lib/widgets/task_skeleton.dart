import 'package:flutter/material.dart';

/// مؤشر تحميل هيكلي (Skeleton) ناعم يعطي إحساساً بالسرعة أثناء جلب المهام
class TaskSkeletonList extends StatefulWidget {
  final int count;

  const TaskSkeletonList({super.key, this.count = 4});

  @override
  State<TaskSkeletonList> createState() => _TaskSkeletonListState();
}

class _TaskSkeletonListState extends State<TaskSkeletonList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF1E293B) : Colors.grey.shade200;
    final highlightColor = isDark ? const Color(0xFF334155) : Colors.grey.shade100;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final color = Color.lerp(baseColor, highlightColor, _controller.value)!;
        return Column(
          children: List.generate(
            widget.count,
            (_) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: 200,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 12,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          height: 24,
                          width: 82,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          height: 24,
                          width: 72,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
