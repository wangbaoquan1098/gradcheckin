import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dates.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/checkin_trend_calculator.dart';
import '../../data/models/checkin_trend.dart';
import '../../providers/checkin_provider.dart';
import 'widgets/checkin_trend_chart.dart';

/// 打卡趋势页面
class TrendScreen extends StatelessWidget {
  const TrendScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(AppStrings.trend),
        backgroundColor: isDark ? AppColors.darkAppBar : AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Consumer<CheckinProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return TrendContent(
            checkedDates: provider.checkedDates,
            startDate: AppDates.checkinStartDate,
            endDate: AppDates.checkinEndDate,
            today: DateTime.now(),
          );
        },
      ),
    );
  }
}

class TrendContent extends StatefulWidget {
  final Set<String> checkedDates;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime today;

  const TrendContent({
    super.key,
    required this.checkedDates,
    required this.startDate,
    required this.endDate,
    required this.today,
  });

  @override
  State<TrendContent> createState() => _TrendContentState();
}

class _TrendContentState extends State<TrendContent> {
  TrendGrouping _grouping = TrendGrouping.weekly;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final periods = _buildPeriods();
    final currentPeriod = periods.isEmpty ? null : periods.last;
    final surface = isDark ? AppColors.darkSurface : colorScheme.surface;
    final elevatedSurface = isDark
        ? AppColors.darkSurfaceElevated
        : colorScheme.surface;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.trend,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _dateRangeText(),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  label: AppStrings.currentPeriodRate,
                  value: _formatRate(currentPeriod?.rate ?? 0),
                  color: isDark ? const Color(0xFF63B3FF) : AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryCard(
                  label: AppStrings.currentPeriodDays,
                  value: currentPeriod == null
                      ? '0/0 天'
                      : '${currentPeriod.checkedDays}/${currentPeriod.totalDays} 天',
                  color: isDark ? const Color(0xFF63D987) : AppColors.checkedIn,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Center(
            child: SegmentedButton<TrendGrouping>(
              segments: const [
                ButtonSegment(
                  value: TrendGrouping.weekly,
                  icon: Icon(Icons.view_week),
                  label: Text(AppStrings.weeklyTrend),
                ),
                ButtonSegment(
                  value: TrendGrouping.monthly,
                  icon: Icon(Icons.calendar_month),
                  label: Text(AppStrings.monthlyTrend),
                ),
              ],
              selected: {_grouping},
              onSelectionChanged: (selection) {
                setState(() {
                  _grouping = selection.first;
                });
              },
            ),
          ),
          const SizedBox(height: 18),
          Container(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(8),
              border: isDark ? Border.all(color: AppColors.darkOutline) : null,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(
                    alpha: isDark ? 0.18 : 0.06,
                  ),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: CheckinTrendChart(periods: periods),
          ),
          const SizedBox(height: 20),
          Text(
            AppStrings.trendDetails,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          if (periods.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: elevatedSurface,
                borderRadius: BorderRadius.circular(8),
                border: isDark
                    ? Border.all(color: AppColors.darkOutline)
                    : null,
              ),
              child: Text(
                AppStrings.noTrendData,
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            )
          else
            ...periods.reversed.map(
              (period) => _TrendPeriodTile(period: period),
            ),
        ],
      ),
    );
  }

  List<CheckinTrendPeriod> _buildPeriods() {
    return switch (_grouping) {
      TrendGrouping.weekly => CheckinTrendCalculator.buildWeeklyTrends(
        checkedDates: widget.checkedDates,
        startDate: widget.startDate,
        endDate: widget.endDate,
        today: widget.today,
      ),
      TrendGrouping.monthly => CheckinTrendCalculator.buildMonthlyTrends(
        checkedDates: widget.checkedDates,
        startDate: widget.startDate,
        endDate: widget.endDate,
        today: widget.today,
      ),
    };
  }

  String _dateRangeText() {
    final formatter = DateFormat('yyyy年MM月dd日');
    return '${formatter.format(widget.startDate)} - ${formatter.format(widget.endDate)}';
  }

  String _formatRate(double rate) {
    return '${(rate * 100).toStringAsFixed(1)}%';
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: isDark ? Border.all(color: AppColors.darkOutline) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendPeriodTile extends StatelessWidget {
  final CheckinTrendPeriod period;

  const _TrendPeriodTile({required this.period});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final dateFormatter = DateFormat('MM/dd');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: isDark ? Border.all(color: AppColors.darkOutline) : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  period.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${dateFormatter.format(period.startDate)} - ${dateFormatter.format(period.endDate)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(period.rate * 100).toStringAsFixed(1)}% 打卡率',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '已打卡 ${period.checkedDays} / ${period.totalDays} 天',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
