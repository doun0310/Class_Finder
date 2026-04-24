import 'package:flutter/material.dart';

import '../models/course.dart';
import '../services/genetic_algorithm.dart';
import '../theme/app_theme.dart';

class TimetableGrid extends StatelessWidget {
  final Timetable timetable;
  final int? highlightMinHour;
  final int? highlightMaxHour;

  const TimetableGrid({
    super.key,
    required this.timetable,
    this.highlightMinHour,
    this.highlightMaxHour,
  });

  static const _startHour = 9;
  static const _endHour = 21;
  static const _timeColumnWidth = 46.0;
  static const _dayColumnWidth = 78.0;
  static const _headerHeight = 40.0;
  static const _cellHeight = 54.0;

  static const _palette = [
    Color(0xFF1D4ED8),
    Color(0xFF0891B2),
    Color(0xFFF97316),
    Color(0xFF16A34A),
    Color(0xFF7C3AED),
    Color(0xFFDB2777),
    Color(0xFF0F766E),
    Color(0xFFB45309),
  ];

  @override
  Widget build(BuildContext context) {
    final totalWidth = _timeColumnWidth + weekdays.length * _dayColumnWidth;
    final totalHeight = _headerHeight + (_endHour - _startHour) * _cellHeight;
    final colors = <String, Color>{};
    for (int i = 0; i < timetable.courses.length; i++) {
      colors[timetable.courses[i].id] = _palette[i % _palette.length];
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(28),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: totalWidth,
          height: totalHeight,
          child: Stack(
            children: [
              CustomPaint(
                size: Size(totalWidth, totalHeight),
                painter: _GridPainter(
                  scheme: Theme.of(context).colorScheme,
                  minHour: highlightMinHour,
                  maxHour: highlightMaxHour,
                ),
              ),
              ...weekdays.asMap().entries.map((entry) {
                return Positioned(
                  left: _timeColumnWidth + entry.key * _dayColumnWidth + 6,
                  top: 4,
                  width: _dayColumnWidth - 12,
                  height: _headerHeight - 8,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        entry.value,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                  ),
                );
              }),
              ...List.generate(_endHour - _startHour, (index) {
                final hour = _startHour + index;
                final isLunch = hour == 12;
                return Positioned(
                  left: 0,
                  top: _headerHeight + index * _cellHeight,
                  width: _timeColumnWidth,
                  height: _cellHeight,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '$hour:00',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: isLunch
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                  ),
                );
              }),
              ...timetable.courses.expand((course) {
                return course.timeSlots.map((slot) {
                  final dayIndex = weekdays.indexOf(slot.day);
                  if (dayIndex < 0) {
                    return const SizedBox.shrink();
                  }

                  final top =
                      _headerHeight +
                      (slot.startHour - _startHour) * _cellHeight +
                      3;
                  final height = slot.durationHours * _cellHeight - 6;
                  return Positioned(
                    left: _timeColumnWidth + dayIndex * _dayColumnWidth + 4,
                    top: top,
                    width: _dayColumnWidth - 8,
                    height: height,
                    child: _CourseBlock(
                      course: course,
                      color: colors[course.id] ?? AppTheme.blue,
                    ),
                  );
                });
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourseBlock extends StatelessWidget {
  final Course course;
  final Color color;

  const _CourseBlock({required this.course, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withValues(alpha: 0.82)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            course.name,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            course.professor,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final ColorScheme scheme;
  final int? minHour;
  final int? maxHour;

  _GridPainter({
    required this.scheme,
    required this.minHour,
    required this.maxHour,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = scheme.outlineVariant
      ..strokeWidth = 1;
    final softLinePaint = Paint()
      ..color = scheme.outlineVariant.withValues(alpha: 0.55)
      ..strokeWidth = 0.8;

    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(24)),
      Paint()..color = scheme.surface,
    );

    final gridTop = TimetableGrid._headerHeight;
    final gridLeft = TimetableGrid._timeColumnWidth;

    canvas.drawLine(
      Offset(gridLeft, 0),
      Offset(gridLeft, size.height),
      linePaint,
    );
    canvas.drawLine(Offset(0, gridTop), Offset(size.width, gridTop), linePaint);

    for (
      int i = 0;
      i <= TimetableGrid._endHour - TimetableGrid._startHour;
      i++
    ) {
      final y = gridTop + i * TimetableGrid._cellHeight;
      canvas.drawLine(
        Offset(gridLeft, y),
        Offset(size.width, y),
        softLinePaint,
      );
    }

    for (int i = 0; i <= weekdays.length; i++) {
      final x = gridLeft + i * TimetableGrid._dayColumnWidth;
      canvas.drawLine(
        Offset(x, gridTop),
        Offset(x, size.height),
        softLinePaint,
      );
    }

    final lunchTop =
        gridTop + (12 - TimetableGrid._startHour) * TimetableGrid._cellHeight;
    canvas.drawRect(
      Rect.fromLTWH(
        gridLeft,
        lunchTop,
        weekdays.length * TimetableGrid._dayColumnWidth,
        TimetableGrid._cellHeight,
      ),
      Paint()..color = scheme.primary.withValues(alpha: 0.05),
    );

    if (minHour != null && minHour! > TimetableGrid._startHour) {
      final height =
          (minHour! - TimetableGrid._startHour) * TimetableGrid._cellHeight;
      canvas.drawRect(
        Rect.fromLTWH(
          gridLeft,
          gridTop,
          weekdays.length * TimetableGrid._dayColumnWidth,
          height,
        ),
        Paint()..color = scheme.error.withValues(alpha: 0.06),
      );
    }

    if (maxHour != null && maxHour! < TimetableGrid._endHour) {
      final top =
          gridTop +
          (maxHour! - TimetableGrid._startHour) * TimetableGrid._cellHeight;
      canvas.drawRect(
        Rect.fromLTWH(
          gridLeft,
          top,
          weekdays.length * TimetableGrid._dayColumnWidth,
          size.height - top,
        ),
        Paint()..color = scheme.error.withValues(alpha: 0.06),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return oldDelegate.scheme != scheme ||
        oldDelegate.minHour != minHour ||
        oldDelegate.maxHour != maxHour;
  }
}
