import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'schedule_screen.dart';
import 'daily_schedule_screen.dart';

/// 课表视图容器，管理周视图和日视图之间的切换
class ScheduleViewContainer extends StatefulWidget {
  const ScheduleViewContainer({super.key});

  /// 全局 key，用于外部触发视图切换
  static final GlobalKey<ScheduleViewContainerState> containerKey =
      GlobalKey<ScheduleViewContainerState>();

  @override
  State<ScheduleViewContainer> createState() => ScheduleViewContainerState();
}

class ScheduleViewContainerState extends State<ScheduleViewContainer> {
  bool _isDailyView = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadViewPreference();
  }

  Future<void> _loadViewPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDailyView = prefs.getBool('is_daily_view') ?? false;
      _isLoading = false;
    });
  }

  Future<void> _saveViewPreference(bool isDaily) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_daily_view', isDaily);
  }

  void toggleView() {
    setState(() {
      _isDailyView = !_isDailyView;
    });
    _saveViewPreference(_isDailyView);
  }

  void setDailyView(bool daily) {
    if (_isDailyView != daily) {
      setState(() {
        _isDailyView = daily;
      });
      _saveViewPreference(daily);
    }
  }

  bool get isDailyView => _isDailyView;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: _isDailyView
          ? DailyScheduleScreen(
              key: const ValueKey('daily'),
              onSwitchToWeek: () => setDailyView(false),
            )
          : ScheduleScreen(
              key: const ValueKey('week'),
              onSwitchToDaily: () => setDailyView(true),
            ),
    );
  }
}
