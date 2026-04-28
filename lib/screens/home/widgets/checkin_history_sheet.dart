import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/checkin_provider.dart';

/// 打卡历史底部弹窗（显示每次操作记录）
class CheckinHistorySheet extends StatelessWidget {
  const CheckinHistorySheet({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetColor = isDark
        ? AppColors.darkSurfaceElevated
        : colorScheme.surface;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: sheetColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // 拖动把手
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // 标题
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '打卡记录',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Consumer<CheckinProvider>(
                      builder: (context, provider, _) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.checkedInDarkContainer
                                : Colors.green.shade50,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '已打卡 ${provider.totalCheckins} 天',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.green.shade200
                                  : Colors.green.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: colorScheme.outlineVariant),
              // 历史列表
              Expanded(
                child: Consumer<CheckinProvider>(
                  builder: (context, provider, _) {
                    final records = provider.historyRecords;

                    if (records.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 64,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '暂无打卡记录',
                              style: TextStyle(
                                fontSize: 16,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: records.length,
                      separatorBuilder: (context, index) =>
                          Divider(height: 1, color: colorScheme.outlineVariant),
                      itemBuilder: (context, index) {
                        final record = records[index];
                        final iconBackground = record.isCheckin
                            ? isDark
                                  ? AppColors.checkedInDarkContainer
                                  : Colors.green.shade50
                            : isDark
                            ? AppColors.notCheckedInDarkContainer
                            : Colors.orange.shade50;
                        final iconColor = record.isCheckin
                            ? isDark
                                  ? Colors.green.shade200
                                  : Colors.green
                            : isDark
                            ? Colors.orange.shade200
                            : Colors.orange;

                        return ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: iconBackground,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              record.isCheckin ? Icons.check : Icons.undo,
                              color: iconColor,
                            ),
                          ),
                          title: Text(
                            DateFormat('yyyy年MM月dd日').format(record.date),
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          subtitle: Text(
                            record.isCheckin ? '打卡' : '取消打卡',
                            style: TextStyle(color: iconColor),
                          ),
                          trailing: Text(
                            DateFormat('HH:mm').format(record.operationTime),
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
