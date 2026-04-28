import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_dates.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/backup_service.dart';
import '../../providers/checkin_provider.dart';
import '../../providers/countdown_provider.dart';
import '../../providers/settings_provider.dart';
import 'widgets/countdown_banner.dart';
import 'widgets/checkin_history_sheet.dart';
import 'widgets/date_settings_dialog.dart';

/// 主界面（日历视图）
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  int _currentMonth = DateTime.now().month;
  int _currentYear = DateTime.now().year;
  bool _isImportExporting = false;
  final BackupService _backupService = BackupService();

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _currentMonth = DateTime.now().month;
    _currentYear = DateTime.now().year;

    // 加载当月打卡数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<CheckinProvider>(context, listen: false);
      provider.loadMonthCheckins(_currentYear, _currentMonth);
    });
  }

  bool _isToday(DateTime day) {
    final now = DateTime.now();
    return day.year == now.year && day.month == now.month && day.day == now.day;
  }

  bool _isFutureDay(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final checkDate = DateTime(day.year, day.month, day.day);
    return checkDate.isAfter(today);
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  DateTime _getTodayInRange() {
    final today = _dateOnly(DateTime.now());
    if (today.isBefore(AppDates.checkinStartDate)) {
      return AppDates.checkinStartDate;
    }
    if (today.isAfter(AppDates.checkinEndDate)) {
      return AppDates.checkinEndDate;
    }
    return today;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        centerTitle: true,
        backgroundColor: isDark ? AppColors.darkAppBar : AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        systemOverlayStyle: isDark
            ? const SystemUiOverlayStyle(
                statusBarColor: AppColors.darkAppBar,
                statusBarIconBrightness: Brightness.light,
                statusBarBrightness: Brightness.dark,
              )
            : SystemUiOverlayStyle.light,
        actions: [_buildSettingsMenu()],
      ),
      body: Column(
        children: [
          const CountdownBanner(),
          Expanded(child: _buildCalendar()),
          _buildStatistics(),
        ],
      ),
    );
  }

  Widget _buildStatistics() {
    return Consumer<CheckinProvider>(
      builder: (context, provider, _) {
        final monthRate = provider.getMonthCheckinRate(
          _currentYear,
          _currentMonth,
        );
        final totalRate = provider.totalCheckinRate;
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final isDark = theme.brightness == Brightness.dark;
        final statSurface = isDark
            ? AppColors.darkSurfaceElevated
            : colorScheme.surface;

        return Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
          decoration: BoxDecoration(
            color: statSurface,
            border: Border(
              top: BorderSide(
                color: isDark
                    ? AppColors.darkOutline
                    : colorScheme.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(
                  alpha: isDark ? 0.2 : 0.08,
                ),
                blurRadius: isDark ? 18 : 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                '${DateFormat('MM月').format(DateTime(_currentYear, _currentMonth))}打卡率',
                '${(monthRate * 100).toStringAsFixed(1)}%',
                isDark ? const Color(0xFF63B3FF) : Colors.blue,
              ),
              Container(
                width: 1,
                height: 42,
                color: colorScheme.outlineVariant.withValues(
                  alpha: isDark ? 0.9 : 1,
                ),
              ),
              _buildStatItem(
                '总打卡率',
                '${(totalRate * 100).toStringAsFixed(1)}%',
                isDark ? const Color(0xFF63D987) : Colors.green,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildCalendar() {
    return Consumer<CheckinProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final colorScheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final calendarSurface = isDark
            ? AppColors.darkSurface
            : colorScheme.surface;

        return Container(
          margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 10),
          decoration: BoxDecoration(
            color: calendarSurface,
            borderRadius: BorderRadius.circular(18),
            border: isDark ? Border.all(color: AppColors.darkOutline) : null,
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(
                  alpha: isDark ? 0.28 : 0.08,
                ),
                blurRadius: isDark ? 24 : 10,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              TableCalendar(
                firstDay: AppDates.checkinStartDate,
                lastDay: AppDates.checkinEndDate,
                focusedDay: _focusedDay,
                locale: 'zh_CN',
                startingDayOfWeek: StartingDayOfWeek.monday,
                rowHeight: 46,
                daysOfWeekHeight: 34,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  _handleCheckinForDate(selectedDay);
                },
                onPageChanged: (focusedDay) {
                  // 不允许切换到未来的月份
                  final now = DateTime.now();
                  if (focusedDay.year > now.year ||
                      (focusedDay.year == now.year &&
                          focusedDay.month > now.month)) {
                    return;
                  }
                  setState(() {
                    _focusedDay = focusedDay;
                    _currentMonth = focusedDay.month;
                    _currentYear = focusedDay.year;
                  });
                  provider.loadMonthCheckins(focusedDay.year, focusedDay.month);
                },
                enabledDayPredicate: (day) {
                  // 不允许选择未来日期
                  return !_isFutureDay(day);
                },
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    return _buildDayCell(day, provider);
                  },
                  selectedBuilder: (context, day, focusedDay) {
                    return _buildDayCell(day, provider, isSelected: true);
                  },
                  todayBuilder: (context, day, focusedDay) {
                    return _buildDayCell(day, provider, isToday: true);
                  },
                  disabledBuilder: (context, day, focusedDay) {
                    return _buildDayCell(day, provider, isDisabled: true);
                  },
                  outsideBuilder: (context, day, focusedDay) {
                    return const SizedBox.shrink();
                  },
                  weekNumberBuilder: (context, weekNumber) {
                    // 根据标准周数和当前聚焦的年份推算该周的某一天
                    // weekNumber 是从当年1月1日算起的周数
                    final year = _focusedDay.year;
                    // 计算该周的中间日期（第 weekNumber 周的周四）
                    final jan1 = DateTime(year, 1, 1);
                    final daysOffset = (weekNumber - 1) * 7 + 3; // +3 表示周四
                    final weekDate = jan1.add(Duration(days: daysOffset));
                    // 计算该周的周日（一周的最后一天）
                    final weekSunday = weekDate.add(
                      Duration(days: DateTime.sunday - weekDate.weekday),
                    );
                    // 如果该周的周日早于打卡开始日期，则不显示周数
                    if (weekSunday.isBefore(AppDates.checkinStartDate)) {
                      return const SizedBox.shrink();
                    }
                    // 使用从打卡开始日期算起的自定义周数
                    final customWeekNumber = AppDates.getWeekNumber(weekDate);
                    return Center(
                      child: Text(
                        '$customWeekNumber',
                        style: TextStyle(
                          fontSize: 10,
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  },
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false, // 去掉切换日历格式功能
                  titleCentered: true,
                  headerPadding: const EdgeInsets.symmetric(vertical: 12),
                  leftChevronIcon: Icon(
                    Icons.chevron_left,
                    color: colorScheme.onSurfaceVariant,
                    size: 30,
                  ),
                  rightChevronIcon: Icon(
                    Icons.chevron_right,
                    color: colorScheme.onSurfaceVariant,
                    size: 30,
                  ),
                  titleTextStyle: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : textTheme.titleMedium?.color,
                  ),
                ),
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  defaultTextStyle: TextStyle(color: colorScheme.onSurface),
                  weekendTextStyle: TextStyle(color: colorScheme.onSurface),
                  weekNumberTextStyle: TextStyle(
                    fontSize: 10,
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  weekendStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                weekNumbersVisible: true,
              ),
              Positioned(
                right: 16,
                bottom: 18,
                child: _buildTodayButton(provider),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTodayButton(CheckinProvider provider) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      elevation: isDark ? 0 : 4,
      borderRadius: BorderRadius.circular(22),
      child: FilledButton.icon(
        onPressed: () => _jumpToToday(provider),
        icon: const Icon(Icons.today, size: 18),
        label: const Text('今天'),
        style: FilledButton.styleFrom(
          backgroundColor: isDark
              ? AppColors.darkSurfaceElevated
              : colorScheme.primary,
          foregroundColor: isDark ? colorScheme.primary : colorScheme.onPrimary,
          minimumSize: const Size(88, 42),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          side: isDark
              ? BorderSide(color: colorScheme.primary, width: 1.5)
              : BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          shadowColor: colorScheme.shadow.withValues(alpha: 0.24),
        ),
      ),
    );
  }

  void _jumpToToday(CheckinProvider provider) {
    final today = _getTodayInRange();

    setState(() {
      _focusedDay = today;
      _selectedDay = today;
      _currentMonth = today.month;
      _currentYear = today.year;
    });

    provider.loadMonthCheckins(today.year, today.month);
  }

  Widget _buildDayCell(
    DateTime day,
    CheckinProvider provider, {
    bool isSelected = false,
    bool isToday = false,
    bool isDisabled = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isCheckedIn = provider.isCheckedIn(day);
    final isFuture = _isFutureDay(day);
    final isInRange =
        !day.isBefore(AppDates.checkinStartDate) &&
        !day.isAfter(AppDates.checkinEndDate);

    final checkedColor = isDark ? AppColors.checkedInDark : AppColors.checkedIn;
    final missedBackground = isDark
        ? AppColors.notCheckedInDarkContainer
        : AppColors.notCheckedInBackground;
    final missedSelectedBackground = isDark
        ? AppColors.notCheckedInDarkSelectedContainer
        : AppColors.notCheckedInBackground;
    final missedText = isDark
        ? AppColors.notCheckedInDark
        : AppColors.notCheckedIn;

    Color backgroundColor = Colors.transparent;
    Color textColor = colorScheme.onSurface;
    Color? borderColor;
    double borderWidth = 1;

    if (isDisabled || isFuture) {
      // 禁用/未来日期：灰色
      textColor = isDark
          ? AppColors.textSecondaryDark.withValues(alpha: 0.45)
          : Colors.grey.shade400;
    } else if (isCheckedIn) {
      // 已打卡：绿色正圆形背景
      backgroundColor = checkedColor;
      textColor = Colors.white;
    } else if (isInRange) {
      // 过去的未打卡日期：深色模式下只保留低亮度底色和描边，避免浅粉色块刺眼。
      backgroundColor = missedBackground;
      textColor = missedText;
      borderColor = isDark
          ? AppColors.notCheckedInDarkOutline.withValues(alpha: 0.85)
          : null;
    }

    if (isSelected && !isDisabled && !isFuture) {
      borderColor = colorScheme.primary;
      borderWidth = 2;
      if (isCheckedIn) {
        backgroundColor = checkedColor;
        textColor = Colors.white;
      } else if (isInRange) {
        backgroundColor = missedSelectedBackground;
        textColor = colorScheme.primary;
      } else {
        backgroundColor = colorScheme.primary.withValues(alpha: 0.16);
        textColor = colorScheme.primary;
      }
    }

    if (isToday && !isCheckedIn && !isFuture) {
      borderColor = colorScheme.primary;
      borderWidth = 2;
    }

    // 构建日期文本
    Widget dateContent = Text(
      '${day.day}',
      style: TextStyle(
        color: textColor,
        fontWeight: (isToday || isSelected || isCheckedIn)
            ? FontWeight.bold
            : FontWeight.normal,
        fontSize: 16,
      ),
    );

    // 已打卡使用正圆形，未打卡使用圆角矩形
    final cellSize = isCheckedIn ? 38.0 : 42.0;

    return Center(
      child: Container(
        width: cellSize,
        height: cellSize,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: isCheckedIn ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: isCheckedIn
              ? null
              : BorderRadius.circular(isDark ? 14 : 8),
          border: borderColor != null
              ? Border.all(color: borderColor, width: borderWidth)
              : null,
          boxShadow: isCheckedIn && isDark
              ? [
                  BoxShadow(
                    color: checkedColor.withValues(alpha: 0.28),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Center(child: dateContent),
      ),
    );
  }

  /// 处理日期点击 - 弹窗确认后打卡
  Future<void> _handleCheckinForDate(DateTime date) async {
    final provider = Provider.of<CheckinProvider>(context, listen: false);

    // 不允许对未来日期打卡
    if (_isFutureDay(date)) {
      return;
    }

    // 检查日期是否在允许范围内
    if (date.isBefore(AppDates.checkinStartDate) ||
        date.isAfter(AppDates.checkinEndDate)) {
      return;
    }

    final wasCheckedIn = provider.isCheckedIn(date);
    final isToday = _isToday(date);

    // 弹窗确认
    final confirmed = await _showConfirmDialog(
      context,
      date,
      wasCheckedIn,
      isToday,
    );
    if (confirmed == true && mounted) {
      await provider.toggleCheckin(date);

      // 根据操作前的状态显示提示
      if (mounted) {
        if (wasCheckedIn) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(AppStrings.checkinCancelled),
              duration: Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(AppStrings.checkinSuccess),
              duration: Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  /// 弹窗确认
  Future<bool?> _showConfirmDialog(
    BuildContext context,
    DateTime date,
    bool wasCheckedIn,
    bool isToday,
  ) {
    final dateStr = DateFormat('yyyy年MM月dd日').format(date);
    String title;
    String content;

    if (isToday) {
      // 当天打卡提醒
      title = wasCheckedIn ? '取消打卡' : '打卡';
      content = wasCheckedIn ? '确定要取消今天的打卡吗？' : '确认要打卡吗？';
    } else {
      title = wasCheckedIn ? '取消打卡' : '补打卡';
      content = wasCheckedIn ? '确定要取消 $dateStr 的打卡吗？' : '确定要为 $dateStr 补打卡吗？';
    }

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(wasCheckedIn ? '确认取消' : '确认打卡'),
          ),
        ],
      ),
    );
  }

  void _showHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CheckinHistorySheet(),
    );
  }

  /// 构建设置菜单
  Widget _buildSettingsMenu() {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final iconColor = Theme.of(context).colorScheme.primary;

        return PopupMenuButton<String>(
          icon: const Icon(Icons.settings),
          tooltip: AppStrings.settings,
          onSelected: (value) {
            if (value == 'history') {
              _showHistory(context);
            } else if (value == 'dates') {
              _showDateSettings(context);
            } else if (value == 'export') {
              _exportData();
            } else if (value == 'import') {
              _importData();
            } else if (value == 'dark_mode') {
              settings.toggleDarkMode();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'history',
              child: Row(
                children: [
                  Icon(Icons.history, size: 20, color: iconColor),
                  const SizedBox(width: 12),
                  const Text(AppStrings.history),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'dates',
              child: Row(
                children: [
                  Icon(Icons.date_range, size: 20, color: iconColor),
                  const SizedBox(width: 12),
                  const Text(AppStrings.modifyDates),
                ],
              ),
            ),
            CheckedPopupMenuItem(
              value: 'dark_mode',
              checked: settings.isDarkMode,
              child: Row(
                children: [
                  Icon(Icons.dark_mode, size: 20, color: iconColor),
                  const SizedBox(width: 12),
                  const Text(AppStrings.darkMode),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  Icon(Icons.upload_file, size: 20, color: iconColor),
                  const SizedBox(width: 12),
                  const Text(AppStrings.exportData),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'import',
              child: Row(
                children: [
                  Icon(Icons.download, size: 20, color: iconColor),
                  const SizedBox(width: 12),
                  const Text(AppStrings.importData),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _exportData() async {
    if (_isImportExporting) {
      return;
    }

    setState(() {
      _isImportExporting = true;
    });

    try {
      final filePath = await _backupService.exportToJson();
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('导出成功：$filePath'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    } on FileSystemException catch (e) {
      _showOperationMessage(e.message);
    } on PlatformException catch (e) {
      _showOperationMessage(e.message ?? '导出失败，请稍后重试');
    } catch (e) {
      _showOperationMessage('导出失败：$e');
    } finally {
      if (mounted) {
        setState(() {
          _isImportExporting = false;
        });
      }
    }
  }

  Future<void> _importData() async {
    if (_isImportExporting) {
      return;
    }

    final shouldImport = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.importData),
        content: const Text(AppStrings.importWarning),
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

    if (shouldImport != true) {
      return;
    }

    String? selectedDirectory;
    try {
      selectedDirectory = await _backupService.pickImportDirectory();
    } on PlatformException catch (e) {
      _showOperationMessage(e.message ?? '无法打开目录选择器');
      return;
    }

    if (selectedDirectory == null || selectedDirectory.isEmpty) {
      return;
    }

    setState(() {
      _isImportExporting = true;
    });

    try {
      final importedCount = await _backupService.importFromDirectory(
        selectedDirectory,
      );
      if (!mounted) {
        return;
      }

      final checkinProvider = Provider.of<CheckinProvider>(
        context,
        listen: false,
      );
      final settingsProvider = Provider.of<SettingsProvider>(
        context,
        listen: false,
      );
      final countdownProvider = Provider.of<CountdownProvider>(
        context,
        listen: false,
      );

      await settingsProvider.reload();
      await checkinProvider.refresh();
      countdownProvider.refresh();

      final newStartDate = AppDates.checkinStartDate;
      final newEndDate = AppDates.checkinEndDate;

      if (_focusedDay.isBefore(newStartDate)) {
        setState(() {
          _focusedDay = newStartDate;
          _selectedDay = newStartDate;
          _currentMonth = newStartDate.month;
          _currentYear = newStartDate.year;
        });
      } else if (_focusedDay.isAfter(newEndDate)) {
        setState(() {
          _focusedDay = newEndDate;
          _selectedDay = newEndDate;
          _currentMonth = newEndDate.month;
          _currentYear = newEndDate.year;
        });
      }

      await checkinProvider.loadMonthCheckins(_currentYear, _currentMonth);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('导入成功：已覆盖 $importedCount 条记录\n目录：$selectedDirectory'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    } on FileSystemException catch (e) {
      _showOperationMessage(
        e.message == '未找到备份文件'
            ? '所选目录中未找到 ${BackupService.backupFileName}'
            : e.message,
      );
    } on PlatformException catch (e) {
      _showOperationMessage(e.message ?? '导入失败，请稍后重试');
    } on FormatException catch (e) {
      _showOperationMessage(e.message);
    } catch (e) {
      _showOperationMessage('导入失败：$e');
    } finally {
      if (mounted) {
        setState(() {
          _isImportExporting = false;
        });
      }
    }
  }

  void _showOperationMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  /// 显示日期设置对话框
  Future<void> _showDateSettings(BuildContext parentContext) async {
    // 在异步操作前获取 provider 引用
    final checkinProvider = Provider.of<CheckinProvider>(
      parentContext,
      listen: false,
    );
    final countdownProvider = Provider.of<CountdownProvider>(
      parentContext,
      listen: false,
    );
    final messenger = ScaffoldMessenger.of(parentContext);

    final result = await showDialog<bool>(
      context: parentContext,
      builder: (context) => const DateSettingsDialog(),
    );

    if (result == true && mounted) {
      // 日期已修改，确保 focusedDay 在新的范围内
      final newStartDate = AppDates.checkinStartDate;
      final newEndDate = AppDates.checkinEndDate;

      setState(() {
        // 如果 focusedDay 早于新的开始日期，调整为开始日期
        if (_focusedDay.isBefore(newStartDate)) {
          _focusedDay = newStartDate;
          _currentMonth = newStartDate.month;
          _currentYear = newStartDate.year;
        }
        // 如果 focusedDay 晚于新的结束日期，调整为结束日期
        else if (_focusedDay.isAfter(newEndDate)) {
          _focusedDay = newEndDate;
          _currentMonth = newEndDate.month;
          _currentYear = newEndDate.year;
        }
      });

      // 日期已修改，刷新所有相关数据
      await checkinProvider.refresh();
      countdownProvider.refresh();

      // 重新加载当月数据
      checkinProvider.loadMonthCheckins(_currentYear, _currentMonth);

      // 使用当前 state 的 context 显示提示
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('日期设置已更新'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
