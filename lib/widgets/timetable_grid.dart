import 'package:flutter/material.dart';
import '../models/course.dart';
import '../services/genetic_algorithm.dart';

class TimetableGrid extends StatelessWidget {
  final Timetable timetable;
  final int? highlightMinHour; // 사용자 설정 최소 시작 시간
  final int? highlightMaxHour; // 사용자 설정 최대 종료 시간
  const TimetableGrid({
    super.key,
    required this.timetable,
    this.highlightMinHour,
    this.highlightMaxHour,
  });

  static const _days = ['월', '화', '수', '목', '금'];
  static const _startHour = 9;
  static const _endHour = 21;
  static const _cellH = 48.0;
  static const _cellW = 62.0;
  static const _timeColW = 38.0;
  static const _headerH = 32.0;

  // 과목별 구분이 명확한 파스텔 팔레트
  static const _palette = [
    Color(0xFF5C9BD6), // blue
    Color(0xFF5CAD76), // green
    Color(0xFFE8885A), // orange
    Color(0xFF9B72B8), // purple
    Color(0xFFD95F6B), // red-pink
    Color(0xFF4AABAA), // teal
    Color(0xFFD4A843), // gold
    Color(0xFF7494C4), // steel blue
    Color(0xFF69B57A), // mint
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
            painter: _GridPainter(
              scheme: scheme,
              minHour: highlightMinHour,
              maxHour: highlightMaxHour,
            ),
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
            final isLunch = hour == 12;
            return Positioned(
              left: 0,
              top: _headerH + i * _cellH,
              width: _timeColW,
              height: _cellH,
              child: Center(
                child: Text('$hour',
                    style: TextStyle(
                        fontSize: 11,
                        color: isLunch
                            ? scheme.primary.withValues(alpha: 0.6)
                            : scheme.outline,
                        fontWeight:
                            isLunch ? FontWeight.bold : FontWeight.normal)),
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

// ── 과목 블록 ─────────────────────────────────────────────────────
class _CourseBlock extends StatelessWidget {
  final Course course;
  final Color color;
  const _CourseBlock({required this.course, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
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
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            course.professor,
            style: TextStyle(
                fontSize: 9, color: Colors.white.withValues(alpha: 0.85)),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── 그리드 배경 ───────────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  final ColorScheme scheme;
  final int? minHour;
  final int? maxHour;
  _GridPainter({required this.scheme, this.minHour, this.maxHour});

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

    // 수평선
    for (int i = 0; i <= endHour - startHour; i++) {
      final y = headerH + i * cellH;
      canvas.drawLine(Offset(timeColW, y), Offset(size.width, y), linePaint);
    }

    // 수직선
    for (int d = 0; d <= days; d++) {
      final x = timeColW + d * cellW;
      canvas.drawLine(Offset(x, headerH), Offset(x, size.height), linePaint);
    }

    // 점심 시간대 (12~13) 강조
    final lunchTop = headerH + (12 - startHour) * cellH;
    final lunchPaint = Paint()
      ..color = scheme.primary.withValues(alpha: 0.06);
    canvas.drawRect(
        Rect.fromLTWH(timeColW, lunchTop, days * cellW, cellH), lunchPaint);

    // 점심 레이블 라인 (살짝 진하게)
    final lunchLinePaint = Paint()
      ..color = scheme.primary.withValues(alpha: 0.2)
      ..strokeWidth = 1;
    canvas.drawLine(
        Offset(timeColW, lunchTop), Offset(size.width, lunchTop), lunchLinePaint);

    // 시간 범위 외 영역 음영 (사용자가 설정한 범위 밖)
    if (minHour != null && minHour! > startHour) {
      final restrictedH = (minHour! - startHour) * cellH;
      canvas.drawRect(
          Rect.fromLTWH(timeColW, headerH, days * cellW, restrictedH),
          Paint()..color = scheme.errorContainer.withValues(alpha: 0.12));
    }
    if (maxHour != null && maxHour! < endHour) {
      final allowedH = (maxHour! - startHour) * cellH;
      final restrictedY = headerH + allowedH;
      canvas.drawRect(
          Rect.fromLTWH(timeColW, restrictedY, days * cellW,
              size.height - restrictedY),
          Paint()..color = scheme.errorContainer.withValues(alpha: 0.12));
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) =>
      old.scheme != scheme ||
      old.minHour != minHour ||
      old.maxHour != maxHour;
}
