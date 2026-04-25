import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AuthShell extends StatelessWidget {
  final String badge;
  final String title;
  final String subtitle;
  final String heroTitle;
  final String heroSubtitle;
  final IconData icon;
  final List<AuthFeatureItem> features;
  final List<AuthMetricItem> metrics;
  final Widget child;
  final Widget? footer;

  const AuthShell({
    super.key,
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.heroTitle,
    required this.heroSubtitle,
    required this.icon,
    required this.features,
    required this.metrics,
    required this.child,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final surfaceTint = scheme.brightness == Brightness.light
        ? Colors.white.withValues(alpha: 0.74)
        : scheme.surface.withValues(alpha: 0.88);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    scheme.surfaceContainerLowest,
                    scheme.surfaceContainerLow,
                    scheme.primaryContainer.withValues(alpha: 0.42),
                    scheme.secondaryContainer.withValues(alpha: 0.3),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -120,
            right: -60,
            child: _AmbientOrb(
              size: 260,
              color: AppTheme.blue.withValues(alpha: 0.14),
            ),
          ),
          Positioned(
            left: -80,
            bottom: 96,
            child: _AmbientOrb(
              size: 220,
              color: AppTheme.coral.withValues(alpha: 0.12),
            ),
          ),
          Positioned(
            right: 72,
            bottom: -40,
            child: _AmbientOrb(
              size: 180,
              color: AppTheme.cyan.withValues(alpha: 0.1),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 980;

                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    wide ? 32 : 20,
                    wide ? 24 : 14,
                    wide ? 32 : 20,
                    28,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1160),
                      child: wide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 11,
                                  child: _HeroPanel(
                                    icon: icon,
                                    badge: badge,
                                    title: heroTitle,
                                    subtitle: heroSubtitle,
                                    features: features,
                                    metrics: metrics,
                                  ),
                                ),
                                const SizedBox(width: 24),
                                SizedBox(
                                  width: 448,
                                  child: _FormPanel(
                                    icon: icon,
                                    badge: badge,
                                    title: title,
                                    subtitle: subtitle,
                                    surfaceTint: surfaceTint,
                                    footer: footer,
                                    child: child,
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                _HeroPanel(
                                  icon: icon,
                                  badge: badge,
                                  title: heroTitle,
                                  subtitle: heroSubtitle,
                                  features: features,
                                  metrics: metrics,
                                  compact: true,
                                ),
                                const SizedBox(height: 16),
                                _FormPanel(
                                  icon: icon,
                                  badge: badge,
                                  title: title,
                                  subtitle: subtitle,
                                  surfaceTint: surfaceTint,
                                  footer: footer,
                                  child: child,
                                ),
                              ],
                            ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AuthFeatureItem {
  final IconData icon;
  final String title;
  final String description;

  const AuthFeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });
}

class AuthMetricItem {
  final String value;
  final String label;

  const AuthMetricItem({required this.value, required this.label});
}

class _HeroPanel extends StatelessWidget {
  final IconData icon;
  final String badge;
  final String title;
  final String subtitle;
  final List<AuthFeatureItem> features;
  final List<AuthMetricItem> metrics;
  final bool compact;

  const _HeroPanel({
    required this.icon,
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.features,
    required this.metrics,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0, end: 1),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 28 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        constraints: BoxConstraints(minHeight: compact ? 0 : 700),
        padding: EdgeInsets.all(compact ? 24 : 32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(36),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.primaryContainer.withValues(alpha: 0.92),
              scheme.secondaryContainer.withValues(alpha: 0.86),
              scheme.surface.withValues(alpha: 0.88),
            ],
          ),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.82),
          ),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.1),
              blurRadius: 36,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: scheme.surface.withValues(alpha: 0.68),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.65),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: scheme.onPrimary),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ClassFinder',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          badge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text(
              title,
              style: theme.textTheme.headlineLarge?.copyWith(
                height: 1.05,
                letterSpacing: -1.2,
              ),
            ),
            const SizedBox(height: 14),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Text(
                subtitle,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 28),
            ...features.map(
              (feature) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _FeatureRow(feature: feature),
              ),
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final tileWidth = constraints.maxWidth >= 580
                    ? (constraints.maxWidth - 14) / 2
                    : constraints.maxWidth;

                return Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: metrics
                      .map(
                        (metric) => SizedBox(
                          width: tileWidth,
                          child: _MetricCard(metric: metric),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final AuthFeatureItem feature;

  const _FeatureRow({required this.feature});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(feature.icon, color: scheme.onSurface, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                feature.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                feature.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final AuthMetricItem metric;

  const _MetricCard({required this.metric});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.76),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            metric.value,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: scheme.primary,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            metric.label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _FormPanel extends StatelessWidget {
  final IconData icon;
  final String badge;
  final String title;
  final String subtitle;
  final Color surfaceTint;
  final Widget child;
  final Widget? footer;

  const _FormPanel({
    required this.icon,
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.surfaceTint,
    required this.child,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 620),
      curve: Curves.easeOutQuart,
      tween: Tween(begin: 0, end: 1),
      builder: (context, value, panel) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - value)),
            child: panel,
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: surfaceTint,
              borderRadius: BorderRadius.circular(34),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.84),
              ),
              boxShadow: [
                BoxShadow(
                  color: scheme.shadow.withValues(alpha: 0.12),
                  blurRadius: 28,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.surface.withValues(alpha: 0.78),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: scheme.outlineVariant.withValues(alpha: 0.76),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(icon, size: 18, color: scheme.primary),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          badge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Text(title, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                Divider(color: scheme.outlineVariant),
                const SizedBox(height: 24),
                child,
                if (footer != null) ...[const SizedBox(height: 20), footer!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AmbientOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _AmbientOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(color: color, blurRadius: 80, spreadRadius: 10),
          ],
        ),
      ),
    );
  }
}
