import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DashboardShimmer extends StatefulWidget {
  const DashboardShimmer({super.key});

  @override
  State<DashboardShimmer> createState() => _DashboardShimmerState();
}

class _DashboardShimmerState extends State<DashboardShimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _box({double? width, required double height, double radius = 14}) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          color: Color.lerp(const Color(0xFFE7ECEA), const Color(0xFFF3F6F5), _ctrl.value),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      children: [
        // Hero card skeleton
        Container(
          height: 220,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: AppColors.primary.withValues(alpha: 0.14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _box(width: 130, height: 26, radius: 20),
              const SizedBox(height: 18),
              _box(width: 160, height: 36, radius: 10),
              const Spacer(),
              Row(
                children: [
                  Expanded(child: _box(height: 50, radius: 14)),
                  const SizedBox(width: 10),
                  Expanded(child: _box(height: 50, radius: 14)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Kitchen bar skeleton
        _box(height: 62, radius: 16),
        const SizedBox(height: 16),
        // 4 Quick action circles
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(
            4,
            (_) => Column(
              children: [
                _box(width: 50, height: 50, radius: 16),
                const SizedBox(height: 6),
                _box(width: 46, height: 10, radius: 6),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        // Member balance card skeletons
        _box(width: 150, height: 18, radius: 8),
        const SizedBox(height: 12),
        ...List.generate(
          3,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _box(height: 82, radius: 16),
          ),
        ),
      ],
    );
  }
}
