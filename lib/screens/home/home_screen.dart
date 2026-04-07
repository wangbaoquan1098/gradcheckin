import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_dates.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/checkin_provider.dart';
import 'widgets/countdown_banner.dart';
import 'widgets/checkin_history_sheet.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showHistory(context),
            tooltip: AppStrings.history,
          ),
        ],
      ),
      body: Column(
        children: [
          const CountdownBanner(),
          Expanded(
            child: _buildCalendar(),
          ),
          _buildStatistics(),
        ],
      ),
    );
  }

  Widget _buildStatistics() {
    return Consumer<CheckinProvider>(
      builder: (context, provider, _) {
        final monthRate = provider.getMonthCheckinRate(_currentYear, _currentMonth);
        final totalRate = provider.totalCheckinRate;
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
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
                Colors.blue,
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.grey.shade200,
              ),
              _buildStatItem(
                '总打卡率',
                '${(totalRate * 100).toStringAsFixed(1)}%',
                Colors.green,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
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

        return Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TableCalendar(
            firstDay: AppDates.checkinStartDate,
            lastDay: AppDates.checkinEndDate,
            focusedDay: _focusedDay,
            locale: 'zh_CN',
            startingDayOfWeek: StartingDayOfWeek.monday,
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
                  (focusedDay.year == now.year && focusedDay.month > now.month)) {
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
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false, // 去掉切换日历格式功能
              titleCentered: true,
              titleTextStyle: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            calendarStyle: const CalendarStyle(
              outsideDaysVisible: false,
              weekendTextStyle: TextStyle(color: Colors.black87),
            ),
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
              weekendStyle: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDayCell(DateTime day, CheckinProvider provider, {
    bool isSelected = false,
    bool isToday = false,
    bool isDisabled = false,
  }) {
    final isCheckedIn = provider.isCheckedIn(day);
    final isFuture = _isFutureDay(day);
    final isInRange = !day.isBefore(AppDates.checkinStartDate) && 
                      !day.isAfter(AppDates.checkinEndDate);

    Color backgroundColor = Colors.transparent;
    Color textColor = Colors.black87;
    Color? borderColor;

    if (isDisabled || isFuture) {
      // 禁用/未来日期：灰色
      textColor = Colors.grey.shade400;
    } else if (isCheckedIn) {
      // 已打卡：绿色正圆形背景
      backgroundColor = AppColors.checkedIn;
      textColor = Colors.white;
    } else if (isInRange) {
      // 过去的未打卡日期：浅红色背景
      backgroundColor = AppColors.notCheckedInBackground;
      textColor = AppColors.notCheckedIn;
    }

    if (isSelected) {
      backgroundColor = isCheckedIn 
          ? AppColors.checkedIn.withValues(alpha: 0.8)
          : AppColors.primary.withValues(alpha: 0.2);
      textColor = isCheckedIn ? Colors.white : AppColors.primary;
      borderColor = AppColors.primary;
    }

    if (isToday && !isCheckedIn && !isFuture) {
      borderColor = AppColors.primary;
    }

    Widget content = Text(
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
    if (isCheckedIn) {
      return Container(
        margin: const EdgeInsets.all(2),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        child: Center(child: content),
      );
    }

    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: borderColor != null 
            ? Border.all(color: borderColor, width: isToday ? 2 : 1)
            : null,
      ),
      child: Center(child: content),
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
    final confirmed = await _showConfirmDialog(context, date, wasCheckedIn, isToday);
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
  Future<bool?> _showConfirmDialog(BuildContext context, DateTime date, bool wasCheckedIn, bool isToday) {
    final dateStr = DateFormat('yyyy年MM月dd日').format(date);
    String title;
    String content;
    
    if (isToday) {
      // 当天打卡提醒
      title = wasCheckedIn ? '取消打卡' : '打卡';
      content = wasCheckedIn 
          ? '确定要取消今天的打卡吗？'
          : '确认要打卡吗？';
    } else {
      title = wasCheckedIn ? '取消打卡' : '补打卡';
      content = wasCheckedIn 
          ? '确定要取消 $dateStr 的打卡吗？'
          : '确定要为 $dateStr 补打卡吗？';
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
}
