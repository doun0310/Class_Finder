import 'dart:math';

import 'package:flutter/material.dart';

class MatchingLoadingOverlay extends StatefulWidget {
  const MatchingLoadingOverlay({super.key});

  @override
  State<MatchingLoadingOverlay> createState() => _MatchingLoadingOverlayState();
}

class _MatchingLoadingOverlayState extends State<MatchingLoadingOverlay>
    with SingleTickerProviderStateMixin {
  static const _steps = [
    '강의 데이터를 정리하고 있어요.',
    '초기 시간표 후보를 생성하고 있어요.',
    '제약 조건을 만족하는 조합을 탐색하고 있어요.',
    '공강과 평점 기준으로 점수를 다시 보정하고 있어요.',
    '상위 추천 시간표를 정리하고 있어요.',
  ];

  late final AnimationController _controller;
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _advance();
  }

  Future<void> _advance() async {
    for (int i = 0; i < _steps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 340));
      if (!mounted) {
        return;
      }
      setState(() => _step = i);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.56),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _AnimatedHelix(controller: _controller),
              const SizedBox(height: 22),
              Text('시간표를 조합하는 중입니다.', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                child: Text(
                  _steps[_step],
                  key: ValueKey(_step),
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: (_step + 1) / _steps.length,
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedHelix extends StatelessWidget {
  final AnimationController controller;

  const _AnimatedHelix({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(80, 80),
          painter: _HelixPainter(
            progress: controller.value,
            color: Theme.of(context).colorScheme.primary,
          ),
        );
      },
    );
  }
}

class _HelixPainter extends CustomPainter {
  final double progress;
  final Color color;

  _HelixPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final fill = Paint()..style = PaintingStyle.fill;

    const steps = 22;
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    for (int i = 0; i < steps; i++) {
      final fraction = i / (steps - 1);
      final angle = (fraction + progress) * pi * 4;
      final y = centerY + (fraction - 0.5) * size.height * 0.8;
      final x1 = centerX + cos(angle) * 20;
      final x2 = centerX + cos(angle + pi) * 20;

      stroke.color = color.withValues(alpha: 0.28 + 0.58 * fraction);
      canvas.drawLine(Offset(x1, y), Offset(x2, y), stroke);

      if (i.isEven) {
        fill.color = color.withValues(alpha: 0.8);
        canvas.drawCircle(Offset(x1, y), 3, fill);
        canvas.drawCircle(Offset(x2, y), 3, fill);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HelixPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
