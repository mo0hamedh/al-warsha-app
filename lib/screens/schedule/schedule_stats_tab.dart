import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/theme_provider.dart';
import '../../models/schedule_model.dart';
import '../../services/database_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart' hide TextDirection;

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
              Text('إحصائيات الأسبوع الحالي', style: GoogleFonts.ibmPlexSansArabic(color: theme.primaryText, fontSize: 20, fontWeight: FontWeight.bold)),
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
              
              Text('أداء الأيام (Bar Chart)', style: GoogleFonts.ibmPlexSansArabic(color: theme.primaryText, fontSize: 18, fontWeight: FontWeight.bold)),
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
                                child: Text(days[value.toInt()], style: GoogleFonts.ibmPlexSansArabic(color: theme.textSecondary, fontSize: 12)),
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
                            return Text('${(value * 100).toInt()}%', style: GoogleFonts.ibmPlexSansArabic(color: theme.textSecondary, fontSize: 10));
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
                   borderRadius: BorderRadius.circular(8),
                 ),
                 child: Row(
                   children: [
                      const Icon(Icons.tips_and_updates, color: Colors.amber, size: 30),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'نصيحة: الإلتزام في الأيام الأولى من الأسبوع يزيد فرصتك في إكمال الجدول للنهاية.',
                          style: GoogleFonts.ibmPlexSansArabic(color: theme.primaryText, fontSize: 14),
                        ),
                      )
                   ],
                 ),
              ),

              const SizedBox(height: 40),

              // ━━━━━━━━━━━━━━━━━━━━
              // قسم "أرشيف أسابيعي 📚"
              // ━━━━━━━━━━━━━━━━━━━━
              FutureBuilder<List<Map>>(
                future: DatabaseService().getUserWeeksArchive(userId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFFFF6A00)));
                  }
                  
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  
                  final archive = snapshot.data!;
                  
                  return Column(
                    children: [
                      Row(
                        children: [
                          Text("📚 أرشيف أسابيعي", style: GoogleFonts.ibmPlexSansArabic(color: theme.primaryText, fontSize: 16, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          Text("${archive.length} أسبوع", style: GoogleFonts.ibmPlexSansArabic(color: theme.textSecondary, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: archive.length,
                        itemBuilder: (context, index) {
                          final week = archive[index];
                          final rate = (week['completionRate'] as num).toDouble();
                          
                          return GestureDetector(
                            onTap: () => _showWeekDetails(context, week, theme),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: theme.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _getBorderColor(rate),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // يمين: معلومات الأسبوع
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "شهر ${week['month']} - أسبوع ${week['weekNumber']}",
                                          style: GoogleFonts.ibmPlexSansArabic(color: theme.primaryText, fontSize: 14, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatDate(week['createdAt']),
                                          style: GoogleFonts.ibmPlexSansArabic(color: theme.textSecondary, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // شمال: نسبة الإنجاز
                                  SizedBox(
                                    width: 60,
                                    height: 60,
                                    child: Stack(
                                      children: [
                                        SizedBox(
                                          width: 60, height: 60,
                                          child: CircularProgressIndicator(
                                            value: rate / 100,
                                            backgroundColor: theme.isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey.shade200,
                                            color: _getProgressColor(rate),
                                            strokeWidth: 6,
                                          ),
                                        ),
                                        Center(
                                          child: Text(
                                            "${rate.toInt()}%",
                                            style: GoogleFonts.ibmPlexSansArabic(color: theme.primaryText, fontSize: 14, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
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
           borderRadius: BorderRadius.circular(8),
           border: Border.all(color: color.withValues(alpha: 0.3)),
         ),
         child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
              Icon(icon, color: color),
              const SizedBox(height: 12),
              Text(title, style: GoogleFonts.ibmPlexSansArabic(color: theme.textSecondary, fontSize: 14)),
              const SizedBox(height: 4),
              Text(value, style: GoogleFonts.ibmPlexSansArabic(color: theme.primaryText, fontSize: 18, fontWeight: FontWeight.bold)),
           ],
         ),
       ),
     );
  }

  // ━━━━━━━━━━━━━━━━━━━━
  // BottomSheet تفاصيل الأسبوع
  // ━━━━━━━━━━━━━━━━━━━━
  void _showWeekDetails(BuildContext context, Map week, ThemeProvider theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (_, scrollController) => SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Handle
                  Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // العنوان
                  Text(
                    "شهر ${week['month']} - أسبوع ${week['weekNumber']}",
                    style: GoogleFonts.ibmPlexSansArabic(color: theme.primaryText, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // نسبة الإنجاز الكلية
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _getProgressColor((week['completionRate'] as num).toDouble()).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _getProgressColor((week['completionRate'] as num).toDouble()), width: 1.5),
                    ),
                    child: Text(
                      "نسبة الإنجاز: ${week['completionRate'].toInt()}%",
                      style: GoogleFonts.ibmPlexSansArabic(color: _getProgressColor((week['completionRate'] as num).toDouble()), fontWeight: FontWeight.bold),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // تفاصيل كل يوم
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text("تفاصيل الأيام:", style: GoogleFonts.ibmPlexSansArabic(color: theme.primaryText, fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 12),
                  
                  // الأيام
                  ...['السبت', 'الاحد', 'الاثنين', 'الثلاثاء', 'الاربعاء', 'الخميس', 'الجمعة'].map((dayName) {
                    final dayData = week['days'][dayName];
                    if (dayData == null) return const SizedBox.shrink();
                    
                    int dayCompleted = 0;
                    int dayTotal = 0;
                    
                    if (dayData is Map) {
                       dayData.forEach((key, val) {
                          if (key != 'isLocked' && key != 'lockedAt') {
                             dayTotal++;
                             if (val is bool && val) dayCompleted++;
                             if (val is num && val > 0) dayCompleted++;
                          }
                       });
                    }
                    
                    final double dayRate = dayTotal > 0 ? (dayCompleted / dayTotal) * 100 : 0;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: theme.isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Text(dayName, style: GoogleFonts.ibmPlexSansArabic(color: theme.primaryText)),
                          const Spacer(),
                          // progress bar
                          SizedBox(
                            width: 100,
                            child: LinearProgressIndicator(
                              value: dayRate / 100,
                              backgroundColor: theme.isDarkMode ? const Color(0xFF3A3A3A) : Colors.grey.shade300,
                              color: _getProgressColor(dayRate),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "${dayRate.toInt()}%",
                            style: GoogleFonts.ibmPlexSansArabic(color: _getProgressColor(dayRate), fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper functions:
  Color _getProgressColor(double rate) {
    if (rate >= 80) return const Color(0xFF66BB6A);
    if (rate >= 50) return const Color(0xFFFF6A00);
    return const Color(0xFFFF5252);
  }

  Color _getBorderColor(dynamic rate) {
    final r = (rate as num).toDouble();
    if (r >= 80) return const Color(0xFF66BB6A).withValues(alpha: 0.5);
    if (r >= 50) return const Color(0xFFFF6A00).withValues(alpha: 0.5);
    return const Color(0xFFFF5252).withValues(alpha: 0.3);
  }

  String _formatDate(dynamic ts) {
    if (ts == null) return 'غير متوفر';
    DateTime dt;
    if (ts is Timestamp) {
      dt = ts.toDate();
    } else if (ts is String) {
      dt = DateTime.parse(ts);
    } else {
      return '';
    }
    return DateFormat('dd/MM/yyyy').format(dt);
  }
}
