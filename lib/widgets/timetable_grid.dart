import 'package:flutter/material.dart';
import '../models/course.dart';
import '../services/genetic_algorithm.dart';

class TimetableGrid extends StatelessWidget {
  final Timetable timetable;
  const TimetableGrid({super.key, required this.timetable});

  static const _days = ['월', '화', '수', '목', '금'];
  static const _startHour = 9;
  static const _endHour = 20;
  static const _cellH = 48.0;
  static const _cellW = 60.0;
  static const _timeColW = 40.0;
  static const _headerH = 32.0;

  static const _palette = [
    Color(0xFF4FC3F7), Color(0xFF81C784), Color(0xFFFFB74D),
    Color(0xFFBA68C8), Color(0xFFFF8A65), Color(0xFF4DB6AC),
    Color(0xFFF06292), Color(0xFFAED581), Color(0xFF90CAF9),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colorMap = <String, Color>{};
    for (int i = 0; i < timetable.courses.length; i++) {
      colorMap[timetable.courses[i].id] = _palette[i % _palette.length];
    }

    final totalH = _headerH + (_endHour - _startHour) * _cellH;
    final totalW = _timeColW + _days.length * _cellW;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: totalW,
        height: totalH,
        child: Stack(children: [
          // 그리드 배경
          CustomPaint(
            size: Size(totalW, totalH),
            painter: _GridPainter(scheme),
          ),
          // 요일 헤더
          ..._days.asMap().entries.map((e) => Positioned(
                left: _timeColW + e.key * _cellW,
                top: 0,
                width: _cellW,
                height: _headerH,
                child: Center(
                  child: Text(e.value,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: scheme.onSurface)),
                ),
              )),
          // 시간 레이블
          ...List.generate(_endHour - _startHour, (i) {
            final hour = _startHour + i;
            return Positioned(
              left: 0,
              top: _headerH + i * _cellH,
              width: _timeColW,
              height: _cellH,
              child: Center(
                child: Text('$hour',
                    style: TextStyle(
                        fontSize: 11, color: scheme.outline)),
              ),
            );
          }),
          // 과목 블록
          ...timetable.courses.expand((c) => c.timeSlots.map((s) {
                final dayIdx = _days.indexOf(s.day);
                if (dayIdx < 0) return const SizedBox.shrink();
                final top = _headerH + (s.startHour - _startHour) * _cellH;
                final height = (s.endHour - s.startHour) * _cellH;
                final color = colorMap[c.id]!;
                return Positioned(
                  left: _timeColW + dayIdx * _cellW + 2,
                  top: top + 2,
                  width: _cellW - 4,
                  height: height - 4,
                  child: _CourseBlock(course: c, color: color),
                );
              })),
        ]),
      ),
    );
  }
}

// ── 과목 블록 ─────────────────────────────────────────────────
class _CourseBlock extends StatelessWidget {
  final Course course;
  final Color color;
  const _CourseBlock({required this.course, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeData.estimateBrightnessForColor(color) == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            course.name,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: textColor),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            course.professor,
            style: TextStyle(fontSize: 9, color: textColor.withValues(alpha: 0.8)),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── 그리드 배경 ───────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  final ColorScheme scheme;
  _GridPainter(this.scheme);

  @override
  void paint(Canvas canvas, Size size) {
    const days = 5;
    const startHour = TimetableGrid._startHour;
    const endHour = TimetableGrid._endHour;
    const cellH = TimetableGrid._cellH;
    const cellW = TimetableGrid._cellW;
    const timeColW = TimetableGrid._timeColW;
    const headerH = TimetableGrid._headerH;

    final linePaint = Paint()
      ..color = scheme.outlineVariant.withValues(alpha: 0.5)
      ..strokeWidth = 0.5;

    final strongLinePaint = Paint()
      ..color = scheme.outlineVariant
      ..strokeWidth = 1;

    // 헤더 하단선
    canvas.drawLine(
        Offset(0, headerH), Offset(size.width, headerH), strongLinePaint);

    // 시간 열 우측선
    canvas.drawLine(
        Offset(timeColW, 0), Offset(timeColW, size.height), strongLinePaint);

    // 수평선 (시간)
    for (int i = 0; i <= endHour - startHour; i++) {
      final y = headerH + i * cellH;
      // 정시선 진하게
      canvas.drawLine(Offset(timeColW, y), Offset(size.width, y),
          i % 1 == 0 ? linePaint : linePaint);
    }

    // 수직선 (요일)
    for (int d = 0; d <= days; d++) {
      final x = timeColW + d * cellW;
      canvas.drawLine(Offset(x, headerH), Offset(x, size.height), linePaint);
    }

    // 점심 시간대 (12~13) 음영
    final lunchPaint = Paint()
      ..color = scheme.surfaceContainerLow.withValues(alpha: 0.6);
    canvas.drawRect(
        Rect.fromLTWH(timeColW, headerH + (12 - startHour) * cellH,
            days * cellW, cellH),
        lunchPaint);
  }

  @override
  bool shouldRepaint(_GridPainter old) => old.scheme != scheme;
}
