import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../providers/settings_provider.dart';

/// 日期设置对话框
class DateSettingsDialog extends StatefulWidget {
  const DateSettingsDialog({super.key});

  @override
  State<DateSettingsDialog> createState() => _DateSettingsDialogState();
}

class _DateSettingsDialogState extends State<DateSettingsDialog> {
  late DateTime _startDate;
  late DateTime _endDate;
  bool _showWarning = false;

  @override
  void initState() {
    super.initState();
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    _startDate = settings.startDate;
    _endDate = settings.endDate;
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: '选择开始日期',
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        _showWarning = true;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: '选择结束日期',
    );
    if (picked != null) {
      setState(() {
        _endDate = DateTime(picked.year, picked.month, picked.day, 8, 0);
        _showWarning = true;
      });
    }
  }

  Future<void> _saveSettings() async {
    if (_endDate.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('结束日期不能早于开始日期'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 如果显示警告，先确认
    if (_showWarning) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('确认修改'),
          content: const Text(AppStrings.dateRangeWarning),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(AppStrings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(AppStrings.confirm),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
    }

    if (!mounted) return;

    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final success = await settings.updateDates(_startDate, _endDate);

    if (mounted) {
      Navigator.pop(context, success);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text(AppStrings.modifyDates),
      content: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          if (settings.isLoading) {
            return const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            );
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 开始日期选择
              _buildDateRow(
                label: AppStrings.startDate,
                date: _startDate,
                onTap: _selectStartDate,
              ),
              const SizedBox(height: 16),
              // 结束日期选择
              _buildDateRow(
                label: AppStrings.endDate,
                date: _endDate,
                onTap: _selectEndDate,
              ),
              if (_showWarning) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colorScheme.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, color: colorScheme.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '修改后将删除范围外的打卡记录',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text(AppStrings.cancel),
        ),
        FilledButton(
          onPressed: _saveSettings,
          child: const Text(AppStrings.save),
        ),
      ],
    );
  }

  Widget _buildDateRow({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    final dateFormat = DateFormat('yyyy年MM月dd日');
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_today, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  dateFormat.format(date),
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
