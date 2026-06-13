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

class _MatchingLoadingOverlayState extends State<MatchingLoadingOverlay> {
  static const _steps = [
    '강의 목록 확인',
    '분반 시간표 대조',
    '공강 조건 적용',
    '학점 범위 검토',
    '후보 결과 정렬',
  ];

  late final Stopwatch _stopwatch;
  late final Duration _normalizedExpectedDuration;
  Timer? _ticker;
  int _step = 0;
  double _progress = 0.08;

  @override
  void initState() {
    super.initState();
    _normalizedExpectedDuration = _normalizeDuration(widget.expectedDuration);
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
              _LoadingHeader(progress: _progress),
              const SizedBox(height: 20),
              Text('시간표 생성 중', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                '예상 소요 ${_formatDuration(widget.expectedDuration ?? _normalizedExpectedDuration)}',
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
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
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

class _LoadingHeader extends StatelessWidget {
  final double progress;

  const _LoadingHeader({required this.progress});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final percent = (progress * 100).clamp(0, 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              Icons.calendar_view_week_rounded,
              size: 28,
              color: scheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '조건 검토 진행률',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  '$percent%',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
