import 'dart:math';
import 'package:flutter/material.dart';

class MatchingLoadingOverlay extends StatefulWidget {
  const MatchingLoadingOverlay({super.key});

  @override
  State<MatchingLoadingOverlay> createState() => _MatchingLoadingOverlayState();
}

class _MatchingLoadingOverlayState extends State<MatchingLoadingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  int _step = 0;

  static const _steps = [
    '과목 데이터 로드 중...',
    '유전 알고리즘 초기화 중...',
    '최적 조합 탐색 중...',
    '적합도 평가 중...',
    '상위 5개 시간표 선별 중...',
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
    _startStepper();
  }

  void _startStepper() async {
    for (int i = 0; i < _steps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 320));
      if (mounted) setState(() => _step = i);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: Colors.black.withValues(alpha: 0.55),
      child: Center(
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _GeneticAnimIcon(controller: _ctrl),
              const SizedBox(height: 24),
              Text('시간표 매칭 중',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(_steps[_step],
                    key: ValueKey(_step),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.outline)),
              ),
              const SizedBox(height: 20),
              LinearProgressIndicator(
                borderRadius: BorderRadius.circular(4),
                value: (_step + 1) / _steps.length,
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// DNA 이중나선 형태의 애니메이션 아이콘
class _GeneticAnimIcon extends StatelessWidget {
  final AnimationController controller;
  const _GeneticAnimIcon({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(64, 64),
          painter: _DNAPainter(controller.value, Theme.of(context).colorScheme.primary),
        );
      },
    );
  }
}

class _DNAPainter extends CustomPainter {
  final double t;
  final Color color;
  _DNAPainter(this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const steps = 20;
    final cx = size.width / 2;
    final cy = size.height / 2;

    for (int i = 0; i < steps; i++) {
      final frac = i / steps;
      final angle = (frac + t) * pi * 4;
      final y = (frac - 0.5) * size.height;
      final x1 = cx + cos(angle) * 20;
      final x2 = cx + cos(angle + pi) * 20;

      paint.color = color.withValues(alpha: 0.3 + 0.7 * ((sin(angle) + 1) / 2));
      canvas.drawLine(Offset(x1, cy + y), Offset(x2, cy + y), paint);

      if (i % 4 == 0) {
        paint.color = color.withValues(alpha: 0.7);
        canvas.drawCircle(Offset(x1, cy + y), 3, paint..style = PaintingStyle.fill);
        canvas.drawCircle(Offset(x2, cy + y), 3, paint);
        paint.style = PaintingStyle.stroke;
      }
    }
  }

  @override
  bool shouldRepaint(_DNAPainter old) => old.t != t;
}
