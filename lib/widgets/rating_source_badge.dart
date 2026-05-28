import 'package:flutter/material.dart';

import '../models/course.dart';
import '../theme/app_theme.dart';

class RatingSourceBadge extends StatelessWidget {
  final RatingSource source;
  final bool compact;

  const RatingSourceBadge({
    super.key,
    required this.source,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (source) {
      RatingSource.officialEstimate => AppTheme.blue,
      RatingSource.userInput => AppTheme.coral,
      RatingSource.reviewBacked => AppTheme.leaf,
    };
    final icon = switch (source) {
      RatingSource.officialEstimate => Icons.auto_awesome_rounded,
      RatingSource.userInput => Icons.edit_note_rounded,
      RatingSource.reviewBacked => Icons.verified_rounded,
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 14 : 16, color: color),
          const SizedBox(width: 6),
          Text(
            source.label,
            style: theme.textTheme.labelMedium?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
