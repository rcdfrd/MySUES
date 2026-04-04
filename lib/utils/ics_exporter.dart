import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/course.dart';
import '../models/schedule_table.dart';
import '../models/time_table.dart';
import '../utils/building_time_override.dart';

class IcsExporter {
  /// 导出并分享一份或多份课程的 ICS 日历文件
  static Future<void> exportCourses(
    List<Course> courses, 
    ScheduleTable currentTable, 
    List<TimeDetail> timeDetails, 
    {String fileName = 'mysues_schedule.ics'}
  ) async {
    final icsString = generateIcsString(courses, currentTable, timeDetails);
    
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsString(icsString);
    
    await Share.shareXFiles([XFile(file.path)]);
  }

  /// 针对一组课程生成完整的 ICS 文件字符串
  static String generateIcsString(
    List<Course> courses, 
    ScheduleTable currentTable, 
    List<TimeDetail> timeDetails
  ) {
    final buffer = StringBuffer();
    buffer.writeln('BEGIN:VCALENDAR');
    buffer.writeln('VERSION:2.0');
    buffer.writeln('PRODID:-//MySUES//Calendar Planner//ZH_CN');
    buffer.writeln('CALSCALE:GREGORIAN');
    buffer.writeln('METHOD:PUBLISH');
    buffer.writeln('X-WR-CALNAME:MySUES 课程表');
    buffer.writeln('X-WR-TIMEZONE:Asia/Shanghai');
    
    final DateFormat icsDateFormat = DateFormat("yyyyMMdd'T'HHmmss");
    final String nowUtcStr = icsDateFormat.format(DateTime.now().toUtc());
    final String nowStr = '${nowUtcStr}Z';
    
    // 找出当学期第一周的周一
    // weekday 1~7 (1 = Mon)
    final startMonday = currentTable.startDateObj.subtract(
      Duration(days: currentTable.startDateObj.weekday - 1),
    );

    for (var course in courses) {
      if (course.isHidden) continue;

      for (int week = 1; week <= currentTable.maxWeek; week++) {
        if (!course.inWeek(week)) continue;
        
        // 计算目标日期：开学周一 + (第几周 - 1)*7天 + 星期几-1天
        final daysOffset = (week - 1) * 7 + (course.day - 1);
        final targetDate = startMonday.add(Duration(days: daysOffset));
        
        // 查找首尾上课时间点
        String startHm = _getCourseStartTime(course, timeDetails);
        String endHm = _getCourseEndTime(course, timeDetails);
        
        final startParts = startHm.split(':');
        final courseStart = DateTime(
          targetDate.year, targetDate.month, targetDate.day, 
          int.parse(startParts[0]), int.parse(startParts[1])
        );

        final endParts = endHm.split(':');
        final courseEnd = DateTime(
          targetDate.year, targetDate.month, targetDate.day, 
          int.parse(endParts[0]), int.parse(endParts[1])
        );
        
        // 转换为 UTC 用于 ICS
        final startUtc = courseStart.toUtc();
        final endUtc = courseEnd.toUtc();

        buffer.writeln('BEGIN:VEVENT');
        buffer.writeln('DTSTAMP:$nowStr');
        buffer.writeln('DTSTART:${icsDateFormat.format(startUtc)}Z');
        buffer.writeln('DTEND:${icsDateFormat.format(endUtc)}Z');
        buffer.writeln('SUMMARY:${course.courseName}');
        if (course.room.isNotEmpty) {
          buffer.writeln('LOCATION:${course.room}');
        }
        
        String description = '教师: ${course.teacher.isNotEmpty ? course.teacher : '未知'}\\n节次: 第${course.startNode} - ${course.startNode + course.step - 1}节';
        buffer.writeln('DESCRIPTION:$description');
        buffer.writeln('UID:mysues_course_${course.id}_week${week}_${targetDate.millisecondsSinceEpoch}@mysues.app');
        buffer.writeln('END:VEVENT');
      }
    }

    buffer.writeln('END:VCALENDAR');
    return buffer.toString();
  }

  static String _getCourseStartTime(Course course, List<TimeDetail> timeDetails) {
    if (course.startTime != null && course.startTime!.isNotEmpty) {
      return course.startTime!;
    }
    final override = BuildingTimeOverride.getOverrideStartTime(
      course.room,
      course.startNode,
    );
    if (override != null) return override;

    try {
      final detail = timeDetails.firstWhere((t) => t.node == course.startNode);
      return detail.startTime;
    } catch (e) {
      return "08:00";
    }
  }

  static String _getCourseEndTime(Course course, List<TimeDetail> timeDetails) {
    if (course.endTime != null && course.endTime!.isNotEmpty) {
      return course.endTime!;
    }
    final endNode = course.startNode + course.step - 1;
    final override = BuildingTimeOverride.getOverrideEndTime(
      course.room,
      endNode,
    );
    if (override != null) return override;

    try {
      final detail = timeDetails.firstWhere((t) => t.node == endNode);
      return detail.endTime; // return corresponding node's end time
    } catch (e) {
      return "09:00";
    }
  }
}
