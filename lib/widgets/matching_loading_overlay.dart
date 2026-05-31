import 'dart:async';
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
    '선택한 강의를 확인하고 있어요.',
    '시간이 겹치지 않는 분반을 정리하고 있어요.',
    '조건에 맞는 시간표를 고르고 있어요.',
    '공강과 이동 흐름을 살펴보고 있어요.',
    '결과를 화면에 맞게 정리하고 있어요.',
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

    final expectedMs = _normalizedExpectedDuration.inMilliseconds;
    final elapsedMs = _stopwatch.elapsedMilliseconds;
    final rawProgress = elapsedMs / expectedMs;
    final easedProgress = rawProgress <= 1
        ? rawProgress * 0.9
        : 0.9 + ((rawProgress - 1) * 0.04).clamp(0.0, 0.08);
    final nextProgress = easedProgress.clamp(0.08, 0.98);
    final nextStep = ((nextProgress * _steps.length).floor()).clamp(
      0,
      _steps.length - 1,
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
              _AnimatedStatusGlyph(controller: _controller),
              const SizedBox(height: 22),
              Text('시간표를 준비하고 있습니다.', style: theme.textTheme.titleLarge),
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

class _AnimatedStatusGlyph extends StatelessWidget {
  final AnimationController controller;

  const _AnimatedStatusGlyph({required this.controller});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final pulse = 0.92 + (controller.value * 0.12);
        final opacity = 0.18 + (controller.value * 0.12);

        return SizedBox(
          width: 88,
          height: 88,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: pulse,
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.primary.withValues(alpha: opacity),
                  ),
                ),
              ),
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.primaryContainer,
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.22),
                  ),
                ),
                child: Icon(
                  Icons.calendar_month_rounded,
                  size: 34,
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        );
      },
    );
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
