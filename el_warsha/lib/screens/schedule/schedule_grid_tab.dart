import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/theme_provider.dart';
import '../../services/database_service.dart';
import 'dart:ui' as ui;
import '../../models/schedule_model.dart';
import 'package:intl/intl.dart';

class ScheduleGridTab extends StatelessWidget {
  final WeeklyScheduleModel schedule;
  final ScheduleProgressModel? progress;
  final String userId;

  const ScheduleGridTab({super.key, required this.schedule, required this.progress, required this.userId});

  final List<String> daysOfWeek = const ['السبت', 'الاحد', 'الاثنين', 'الثلاثاء', 'الاربعاء', 'الخميس', 'الجمعة'];

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    
    // Map today's actual day to our Arabic array logic (simplified static check for demo: e.g mapping DateTime.now().weekday to the array)
    // To make it exact, we map Dart's weekday (1=Mon..7=Sun) to Arabic offset.
    int dartDay = DateTime.now().weekday;
    String todayAr = _getArabicDay(dartDay);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
         scrollDirection: Axis.vertical,
         padding: const EdgeInsets.all(16),
         child: Directionality(
           textDirection: ui.TextDirection.rtl,
           child: Row(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: daysOfWeek.map((day) {
               bool isToday = day == todayAr;
               
               // For demo purposes, define index mapping to determine past/future
               int indexOfToday = daysOfWeek.indexOf(todayAr);
               int currentIdx = daysOfWeek.indexOf(day);
               bool isPast = currentIdx < indexOfToday;
               bool isFuture = currentIdx > indexOfToday;

               return _buildDayColumn(day, isToday, isPast, isFuture, theme);
             }).toList(),
           ),
         ),
      ),
    );
  }

  String _getArabicDay(int weekday) {
     switch(weekday) {
       case 6: return 'السبت';
       case 7: return 'الاحد';
       case 1: return 'الاثنين';
       case 2: return 'الثلاثاء';
       case 3: return 'الاربعاء';
       case 4: return 'الخميس';
       case 5: return 'الجمعة';
       default: return 'السبت';
     }
  }

  Widget _buildDayColumn(String dayName, bool isToday, bool isPast, bool isFuture, ThemeProvider theme) {
    final dbService = DatabaseService();

    // Calculate Completion for the day column footer
    int DayCompletedCount = 0;
    int DayTotalHabits = schedule.habits.length;
    Map<String, dynamic> dayProgress = {};

    if (progress != null && progress!.days.containsKey(dayName)) {
       dayProgress = Map<String, dynamic>.from(progress!.days[dayName]);
       dayProgress.forEach((_, val) {
          if (val is bool && val) DayCompletedCount++;
          if (val is num && val > 0) DayCompletedCount++;
       });
    }

    return Container(
      width: 140,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isToday ? theme.accentOrange.withValues(alpha: 0.1) : theme.card.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isToday ? theme.accentOrange : (theme.isDarkMode ? Colors.white12 : Colors.black12)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isToday ? theme.accentOrange : (theme.isDarkMode ? Colors.black26 : Colors.black12),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            alignment: Alignment.center,
            child: Text(dayName, style: GoogleFonts.cairo(color: isToday ? Colors.white : theme.primaryText, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          
          // Habits Cells
          ...schedule.habits.map((habit) {
             dynamic cellValue = dayProgress[habit.name];

             // UI Logics
             Widget cellContent;
             if (isFuture) {
                cellContent = Icon(Icons.lock_outline, color: theme.textSecondary.withValues(alpha: 0.5));
             } else {
                if (habit.type == 'number') {
                   // Number Field
                   cellContent = _buildNumberInput(cellValue, habit, dayName, isPast, theme, dbService);
                } else {
                   // Checkbox
                   cellContent = _buildCheckboxInput(cellValue, habit, dayName, isPast, theme, dbService);
                }
             }

             bool completed = (cellValue is bool && cellValue) || (cellValue is num && cellValue > 0);
             Color cellBgColor = Colors.transparent;
             if (isPast && !completed) cellBgColor = Colors.redAccent.withValues(alpha: 0.1);
             if (completed) cellBgColor = Colors.green.withValues(alpha: 0.1);

             return Container(
                height: 70, // Fixed height for alignment across columns
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                   color: cellBgColor,
                   border: Border(bottom: BorderSide(color: theme.isDarkMode ? Colors.white12 : Colors.black12)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                     Expanded(child: Text('${habit.icon} ${habit.name}', overflow: TextOverflow.ellipsis, maxLines: 1, style: GoogleFonts.cairo(color: theme.primaryText, fontSize: 11))),
                     cellContent,
                  ],
                ),
             );
          }).toList(),
          
          // Footer Metric
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text('$DayCompletedCount/$DayTotalHabits', style: GoogleFonts.cairo(color: theme.accentOrange, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxInput(dynamic value, ScheduleHabitModel habit, String dayName, bool isPast, ThemeProvider theme, DatabaseService dbService) {
      bool isChecked = value == true;
      return InkWell(
        onTap: () {
           dbService.updateDayProgress(userId, schedule.id, dayName, habit.name, !isChecked, schedule.habits.length);
        },
        child: Icon(
           isChecked ? Icons.check_circle : Icons.circle_outlined,
           color: isChecked ? Colors.green : theme.textSecondary,
           size: 28,
        ),
      );
  }

  Widget _buildNumberInput(dynamic value, ScheduleHabitModel habit, String dayName, bool isPast, ThemeProvider theme, DatabaseService dbService) {
      TextEditingController ctrl = TextEditingController(text: value != null ? value.toString() : '');
      
      return Container(
        width: 50,
        height: 30,
        child: TextField(
           controller: ctrl,
           keyboardType: TextInputType.number,
           textAlign: TextAlign.center,
           style: GoogleFonts.tajawal(color: theme.primaryText, fontWeight: FontWeight.bold, fontSize: 14),
           decoration: InputDecoration(
             contentPadding: EdgeInsets.zero,
             filled: true,
             fillColor: theme.bg,
             border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: theme.accentOrange)),
             focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: theme.accentOrange, width: 2)),
           ),
           onSubmitted: (newVal) {
              if (newVal.isNotEmpty) {
                 dbService.updateDayProgress(userId, schedule.id, dayName, habit.name, int.tryParse(newVal) ?? 0, schedule.habits.length);
              }
           },
        ),
      );
  }
}
