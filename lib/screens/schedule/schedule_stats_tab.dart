import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/theme_provider.dart';
import '../../models/schedule_model.dart';
import 'package:fl_chart/fl_chart.dart';

class ScheduleStatsTab extends StatelessWidget {
  final String userId;
  final WeeklyScheduleModel schedule;
  final ScheduleProgressModel? progress;
  
  const ScheduleStatsTab({
    super.key, 
    required this.userId,
    required this.schedule,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    
    final List<String> daysAr = ['السبت', 'الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'];
    List<double> weeklyRates = List.filled(7, 0.0);
    double totalRate = 0.0;
    String bestDayName = "لا يوجد";
    double bestDayRate = 0.0;

    if (progress != null && schedule.habits.isNotEmpty) {
      final totalHabits = schedule.habits.length;
      for (int i = 0; i < daysAr.length; i++) {
        final day = daysAr[i];
        final dayMap = progress!.days[day] ?? {};
        int completed = 0;
        dayMap.forEach((hName, hVal) {
          if (hVal is bool && hVal == true) completed++;
          if (hVal is num && hVal > 0) completed++;
        });
        
        final rate = completed / totalHabits;
        weeklyRates[i] = rate;
        
        if (rate > bestDayRate) {
          bestDayRate = rate;
          bestDayName = day;
        }
      }
      totalRate = progress!.completionRate;
    }

    return Scaffold(
      backgroundColor: theme.bg,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('إحصائيات الأسبوع الحالي', style: GoogleFonts.cairo(color: theme.primaryText, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              
              // Key Stats Row
              Row(
                children: [
                  _buildStatCard('أفضل يوم', '$bestDayName\n${(bestDayRate * 100).toInt()}%', Icons.star, Colors.amber, theme),
                  const SizedBox(width: 16),
                  _buildStatCard('متوسط الإلتزام', '${(totalRate * 100).toInt()}%', Icons.analytics, theme.accentOrange, theme),
                ],
              ),
              const SizedBox(height: 40),
              
              Text('أداء الأيام (Bar Chart)', style: GoogleFonts.cairo(color: theme.primaryText, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              
              // Bar Chart using fl_chart
              SizedBox(
                height: 250,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 1.0,
                    barTouchData: BarTouchData(enabled: false),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            const days = ['سبت', 'أحد', 'إثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة'];
                            if (value.toInt() >= 0 && value.toInt() < days.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(days[value.toInt()], style: GoogleFonts.cairo(color: theme.textSecondary, fontSize: 12)),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                          reservedSize: 30,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            return Text('${(value * 100).toInt()}%', style: GoogleFonts.cairo(color: theme.textSecondary, fontSize: 10));
                          }
                        )
                      ),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) => FlLine(color: theme.isDarkMode ? Colors.white12 : Colors.black12, strokeWidth: 1),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(weeklyRates.length, (i) {
                      return BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: weeklyRates[i],
                            color: theme.accentOrange,
                            width: 16,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: 1.0,
                              color: theme.card,
                            ),
                          )
                        ],
                      );
                    }),
                  ),
                ),
              ),

              const SizedBox(height: 40),
              Container(
                 padding: const EdgeInsets.all(16),
                 decoration: BoxDecoration(
                   color: theme.card,
                   borderRadius: BorderRadius.circular(16),
                 ),
                 child: Row(
                   children: [
                      const Icon(Icons.tips_and_updates, color: Colors.amber, size: 30),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'نصيحة: الإلتزام في الأيام الأولى من الأسبوع يزيد فرصتك في إكمال الجدول للنهاية.',
                          style: GoogleFonts.cairo(color: theme.primaryText, fontSize: 14),
                        ),
                      )
                   ],
                 ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, ThemeProvider theme) {
     return Expanded(
       child: Container(
         padding: const EdgeInsets.all(16),
         decoration: BoxDecoration(
           color: theme.card,
           borderRadius: BorderRadius.circular(16),
           border: Border.all(color: color.withValues(alpha: 0.3)),
         ),
         child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
              Icon(icon, color: color),
              const SizedBox(height: 12),
              Text(title, style: GoogleFonts.cairo(color: theme.textSecondary, fontSize: 14)),
              const SizedBox(height: 4),
              Text(value, style: GoogleFonts.cairo(color: theme.primaryText, fontSize: 18, fontWeight: FontWeight.bold)),
           ],
         ),
       ),
     );
  }
}
