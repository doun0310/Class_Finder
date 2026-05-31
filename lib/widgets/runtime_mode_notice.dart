import 'package:flutter/material.dart';

import '../services/runtime_config.dart';

class RuntimeModeNotice extends StatelessWidget {
  final RuntimeConfig config;

  const RuntimeModeNotice({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isRemote = config.usesBackend;
    final backgroundColor = isRemote
        ? scheme.primaryContainer
        : scheme.tertiaryContainer;
    final foregroundColor = isRemote
        ? scheme.onPrimaryContainer
        : scheme.onTertiaryContainer;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: foregroundColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isRemote ? Icons.cloud_done_rounded : Icons.devices_rounded,
              color: foregroundColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  config.modeBadge,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: foregroundColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  config.modeTitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: foregroundColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  config.modeDescription,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: foregroundColor.withValues(alpha: 0.88),
                  ),
                ),
                if (config.modeHint != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    config.modeHint!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: foregroundColor.withValues(alpha: 0.82),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
