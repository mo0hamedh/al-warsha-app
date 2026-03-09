import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../providers/theme_provider.dart';
import '../../services/database_service.dart';
import '../../models/schedule_model.dart';

class ScheduleGridTab extends StatefulWidget {
  final WeeklyScheduleModel schedule;
  final ScheduleProgressModel? progress;
  final String userId;

  const ScheduleGridTab({
    super.key,
    required this.schedule,
    required this.progress,
    required this.userId,
  });

  @override
  State<ScheduleGridTab> createState() => _ScheduleGridTabState();
}

class _ScheduleGridTabState extends State<ScheduleGridTab> {
  late DateTime selectedDay;

  DateTime _getDefaultDay() {
    final now = DateTime.now();
    
    // بين 12AM و 6AM = افتح امبارح تلقائي
    if (now.hour >= 0 && now.hour < 6) {
      final yesterday = now.subtract(const Duration(days: 1));
      return DateTime(yesterday.year, yesterday.month, yesterday.day);
    }
    
    // بعد 6AM = اليوم الحالي
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void initState() {
    super.initState();
    selectedDay = _getDefaultDay();
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  DateTime get _weekStartDate {
    // Assuming week starts on Saturday (6)
    int daysToSubtract = (selectedDay.weekday - 6) % 7;
    if (daysToSubtract < 0) daysToSubtract += 7;
    return selectedDay.subtract(Duration(days: daysToSubtract));
  }

  String _getDayName(DateTime date) {
    switch (date.weekday) {
      case 6:
        return 'السبت';
      case 7:
        return 'الاحد';
      case 1:
        return 'الاثنين';
      case 2:
        return 'الثلاثاء';
      case 3:
        return 'الاربعاء';
      case 4:
        return 'الخميس';
      case 5:
        return 'الجمعة';
      default:
        return '';
    }
  }

  bool get isGracePeriod {
    final hour = DateTime.now().hour;
    return hour >= 0 && hour < 6;
  }

  bool _isYesterday(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    return date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day;
  }

  bool _isEditable(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    
    // اليوم = قابل للتعديل دايماً
    if (day == today) return true;
    
    // امبارح + grace period = قابل
    if (day == yesterday && now.hour < 6) return true;
    
    // أي يوم تاني = read only
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final dbService = DatabaseService();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    bool isPast = !_isEditable(selectedDay);
    bool isToday = _isToday(selectedDay);

    String dayNameAr = _getDayName(selectedDay);

    int dayCompletedCount = 0;
    int dayTotalHabits = widget.schedule.habits.length;
    Map<String, dynamic> dayProgress = {};

    if (widget.progress != null &&
        widget.progress!.days.containsKey(dayNameAr)) {
      dayProgress =
          Map<String, dynamic>.from(widget.progress!.days[dayNameAr]);
      dayProgress.forEach((_, val) {
        if (val is bool && val) dayCompletedCount++;
        if (val is num && val > 0) dayCompletedCount++;
      });
      if (dayProgress['isLocked'] == true) {
        isPast = true;
      }
    }

    bool allDone = (dayCompletedCount == dayTotalHabits) && dayTotalHabits > 0;
    bool selectedDayIsWeekStart = selectedDay.year == _weekStartDate.year &&
        selectedDay.month == _weekStartDate.month &&
        selectedDay.day == _weekStartDate.day;

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! > 0) {
          // swipe right = prev day
          if (!selectedDayIsWeekStart) {
            setState(() {
              selectedDay = selectedDay.subtract(const Duration(days: 1));
            });
          }
        } else if (details.primaryVelocity! < 0) {
          // swipe left = next day
          if (!isToday) {
            setState(() {
              selectedDay = selectedDay.add(const Duration(days: 1));
            });
          }
        }
      },
      child: Container(
        color: Colors.transparent, // Ensure GestureDetector catches events
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Day Navigation Row
            Row(
              children: [
                GestureDetector(
                  onTap: !selectedDayIsWeekStart
                      ? () {
                          setState(() {
                            selectedDay =
                                selectedDay.subtract(const Duration(days: 1));
                          });
                        }
                      : null,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: !selectedDayIsWeekStart
                            ? const Color(0xFF333333)
                            : const Color(0xFF222222),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        "›",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: !selectedDayIsWeekStart
                              ? Colors.white
                              : const Color(0xFF333333),
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Column(
                  children: [
                    Text(
                      _getDayName(selectedDay),
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      DateFormat('d MMMM', 'ar').format(selectedDay),
                      style: GoogleFonts.ibmPlexSansArabic(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (isToday) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6A00).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFFF6A00).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text("اليوم",
                            style: GoogleFonts.ibmPlexSansArabic(
                                color: const Color(0xFFFF6A00), fontSize: 11)),
                      ),
                    ],
                  ],
                ),
                const Spacer(),
                GestureDetector(
                  onTap: !isToday
                      ? () {
                          setState(() {
                            selectedDay =
                                selectedDay.add(const Duration(days: 1));
                          });
                        }
                      : null,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: !isToday
                            ? const Color(0xFF333333)
                            : const Color(0xFF222222),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        "‹",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: !isToday
                              ? Colors.white
                              : const Color(0xFF333333),
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Past banner
            if (isPast)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF333333)),
                ),
                child: Row(
                  children: [
                    const Text("🔒", style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 8),
                    Text("لا يمكن تعديل الأيام الماضية",
                        style: GoogleFonts.ibmPlexSansArabic(
                            color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),

            // Grace period banner for yesterday
            if (isGracePeriod && _isYesterday(selectedDay))
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A1500),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFFF6A00).withOpacity(0.4),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      "آخر فرصة للتسجيل تنتهي الساعة 6 الصبح",
                      style: GoogleFonts.ibmPlexSansArabic(
                        color: const Color(0xFFFF6A00),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text("⏰", style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),

            // Habits
            Expanded(
              child: ListView.separated(
                itemCount: widget.schedule.habits.length,
                separatorBuilder: (context, index) {
                  return const Divider(
                    color: Color(0xFF1E1E1E),
                    height: 1,
                    indent: 48,
                  );
                },
                itemBuilder: (context, index) {
                  final habit = widget.schedule.habits[index];
                  dynamic cellValue = dayProgress[habit.name];

                  bool completed = (cellValue is bool && cellValue) ||
                      (cellValue is num && cellValue > 0);

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        // Checkbox
                        GestureDetector(
                          onTap: isPast
                              ? null
                              : () {
                                  if (habit.type == 'number') {
                                    int newVal = completed ? 0 : 1;
                                    dbService.updateDayProgress(
                                        widget.userId,
                                        widget.schedule.id,
                                        dayNameAr,
                                        habit.name,
                                        newVal,
                                        widget.schedule.habits.length);
                                  } else {
                                    dbService.updateDayProgress(
                                        widget.userId,
                                        widget.schedule.id,
                                        dayNameAr,
                                        habit.name,
                                        !completed,
                                        widget.schedule.habits.length);
                                  }
                                },
                          child: Container(
                            width: 26,
                            height: 26,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: completed
                                  ? const Color(0xFFFF6A00)
                                  : Colors.transparent,
                              border: Border.all(
                                color: completed
                                    ? const Color(0xFFFF6A00)
                                    : const Color(0xFF444444),
                                width: 2,
                              ),
                            ),
                            child: completed
                                ? const Text(
                                    "✓",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      height: 1.1,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(habit.icon,
                            style: const TextStyle(
                                fontSize: 18,
                                fontFamilyFallback: ['NotoColorEmoji'])),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            habit.name,
                            style: GoogleFonts.ibmPlexSansArabic(
                              color: isPast
                                  ? const Color(0xFF555555)
                                  : completed
                                      ? const Color(0xFF555555)
                                      : const Color(0xFFEBEBEB),
                              fontSize: 15,
                              decoration: completed
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                              decorationColor: const Color(0xFF555555),
                            ),
                          ),
                        ),
                        if (habit.type == 'number' && !completed && !isPast) ...[
                          _buildNumberInput(cellValue, habit, dayNameAr, isPast,
                              theme, dbService),
                        ]
                      ],
                    ),
                  );
                },
              ),
            ),

            // All Done banner
            if (allDone && isToday)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F2A0F),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF66BB6A).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "🎉 أكملت يومك كاملاً!  ",
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      "+20 نقطة 🔥",
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFF6A00),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberInput(dynamic value, ScheduleHabitModel habit,
      String dayName, bool isPast, ThemeProvider theme, DatabaseService dbService) {
    TextEditingController ctrl = TextEditingController(
        text: value != null && value != 0 ? value.toString() : '');

    return Container(
      width: 40,
      height: 30,
      margin: const EdgeInsets.only(right: 8),
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        enabled: !isPast,
        style: GoogleFonts.ibmPlexSansArabic(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
        decoration: InputDecoration(
          contentPadding: EdgeInsets.zero,
          filled: true,
          fillColor: theme.isDarkMode ? Colors.black26 : Colors.grey.shade200,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Colors.transparent)),
          disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Colors.transparent)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: theme.accentOrange, width: 1)),
        ),
        onSubmitted: (newVal) {
          if (newVal.isNotEmpty && !isPast) {
            dbService.updateDayProgress(
                widget.userId,
                widget.schedule.id,
                dayName,
                habit.name,
                int.tryParse(newVal) ?? 0,
                widget.schedule.habits.length);
          }
        },
      ),
    );
  }
}
