import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/countdown_provider.dart';

/// 倒计时横幅组件
class CountdownBanner extends StatelessWidget {
  const CountdownBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CountdownProvider>(
      builder: (context, provider, child) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final gradientColors = isDark
            ? [AppColors.countdownDarkStart, AppColors.countdownDarkEnd]
            : [Colors.blue.shade700, Colors.blue.shade900];

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? AppColors.darkOutline.withValues(alpha: 0.9)
                    : Colors.transparent,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.4)
                    : Colors.blue.withValues(alpha: 0.3),
                blurRadius: isDark ? 24 : 10,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text(
                '距离 2026 考研初试',
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),
              const SizedBox(height: 12),
              _buildCountdownRow(provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCountdownRow(CountdownProvider provider) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              provider.days,
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              '天',
              style: TextStyle(
                fontSize: 20,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '已过去 ${provider.elapsedDays} 天 (${provider.elapsedPercentage}%)',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
