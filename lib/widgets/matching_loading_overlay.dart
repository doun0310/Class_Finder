import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

class MatchingLoadingOverlay extends StatefulWidget {
  final Duration? expectedDuration;
  final Duration? recentDuration;

  const MatchingLoadingOverlay({
    super.key,
    this.expectedDuration,
    this.recentDuration,
  });

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
  late final Stopwatch _stopwatch;
  late final Duration _normalizedExpectedDuration;
  Timer? _ticker;
  int _step = 0;
  double _progress = 0.08;

  @override
  void initState() {
    super.initState();
    _normalizedExpectedDuration = _normalizeDuration(widget.expectedDuration);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _stopwatch = Stopwatch()..start();
    _ticker = Timer.periodic(
      const Duration(milliseconds: 80),
      (_) => _advance(),
    );
    _advance();
  }

  void _advance() {
    if (!mounted) {
      return;
    }

    final expectedMs = max(120, _normalizedExpectedDuration.inMilliseconds);
    final elapsedMs = _stopwatch.elapsedMilliseconds;
    final rawProgress = elapsedMs / expectedMs;
    final easedProgress = rawProgress <= 1
        ? rawProgress * 0.9
        : 0.9 + min(0.08, (rawProgress - 1) * 0.04);
    final nextProgress = easedProgress.clamp(0.08, 0.98);
    final nextStep = min(
      _steps.length - 1,
      (nextProgress * _steps.length).floor(),
    );

    setState(() {
      _progress = nextProgress;
      _step = nextStep;
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _stopwatch.stop();
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
              Text(
                '예상 약 ${_formatDuration(widget.expectedDuration ?? _normalizedExpectedDuration)}',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (widget.recentDuration != null) ...[
                const SizedBox(height: 4),
                Text(
                  '최근 측정 ${_formatDuration(widget.recentDuration!)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 12),
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
                child: LinearProgressIndicator(value: _progress, minHeight: 8),
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

Duration _normalizeDuration(Duration? duration) {
  final milliseconds = (duration ?? const Duration(milliseconds: 180))
      .inMilliseconds
      .clamp(120, 2400);
  return Duration(milliseconds: milliseconds);
}

String _formatDuration(Duration duration) {
  final seconds = duration.inMilliseconds / 1000;
  return '${seconds.toStringAsFixed(seconds < 1 ? 1 : 2)}초';
}
