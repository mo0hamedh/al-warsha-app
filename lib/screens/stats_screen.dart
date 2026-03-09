import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart' as intl;

import '../providers/theme_provider.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../models/user_model.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final DatabaseService _dbService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final themeProvider = context.watch<ThemeProvider>();
    final user = authService.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: themeProvider.bg,
        body: Center(child: CircularProgressIndicator(color: themeProvider.accentOrange)),
      );
    }

    return Scaffold(
      backgroundColor: themeProvider.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: themeProvider.primaryText, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'إحصائياتك 📊',
          style: GoogleFonts.ibmPlexSansArabic(
            color: themeProvider.primaryText,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: themeProvider.primaryText.withValues(alpha: 0.5),
                blurRadius: 10,
              )
            ],
          ),
        ),
      ),
      body: StreamBuilder<UserModel?>(
        stream: _dbService.getUserProfile(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: themeProvider.accentOrange));
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'حدث خطأ في جلب البيانات.',
                style: GoogleFonts.ibmPlexSansArabic(color: Colors.redAccent, fontSize: 16),
              ),
            );
          }

          final userData = snapshot.data;
          if (userData == null) {
            return Center(
              child: Text(
                'لم يتم العثور على بيانات المستخدم.',
                style: GoogleFonts.ibmPlexSansArabic(color: themeProvider.textSecondary, fontSize: 16),
              ),
            );
          }

          return _buildStatsContent(context, userData, themeProvider);
        },
      ),
    );
  }

  Widget _buildStatsContent(BuildContext context, UserModel user, ThemeProvider theme) {
    final focusSessions = List<Map<String, dynamic>>.from(user.focusSessions);
    // Sort descending by date
    focusSessions.sort((a, b) {
      final dateA = (a['date'] as dynamic)?.toDate() ?? DateTime.now();
      final dateB = (b['date'] as dynamic)?.toDate() ?? DateTime.now();
      return dateB.compareTo(dateA);
    });

    final weeklyFocusHours = (user.weeklyFocusMinutes / 60).toStringAsFixed(1);
    final completedSessionsCount = focusSessions.isNotEmpty ? focusSessions.length : 0;
    
    // Calculate most productive day
    final Map<int, int> dailyMinutes = {};
    for (var session in focusSessions) {
      if (session['type'] == 'focus') {
        final date = (session['date'] as dynamic)?.toDate() as DateTime?;
        if (date != null) {
          // Normalize to weekday
          dailyMinutes[date.weekday] = (dailyMinutes[date.weekday] ?? 0) + (session['duration'] as int? ?? 0);
        }
      }
    }
    
    String mostProductiveDayStr = "لا يوجد";
    if (dailyMinutes.isNotEmpty) {
      final bestDay = dailyMinutes.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      mostProductiveDayStr = _getWeekdayName(bestDay);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Cards
            Row(
              children: [
                Expanded(child: _buildSummaryCard('ساعات أسبوعية', weeklyFocusHours, Icons.timer, theme)),
                const SizedBox(width: 10),
                Expanded(child: _buildSummaryCard('جلسات مكتملة', '$completedSessionsCount', Icons.check_circle, theme)),
                const SizedBox(width: 10),
                Expanded(child: _buildSummaryCard('أفضل يوم', mostProductiveDayStr, Icons.star, theme)),
              ],
            ),
            const SizedBox(height: 30),

            // Weekly Chart
            Text(
              'نشاط التركيز لهذا الأسبوع',
              style: GoogleFonts.ibmPlexSansArabic(
                color: theme.primaryText,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 250,
              padding: const EdgeInsets.only(top: 20, right: 20, left: 10, bottom: 10),
              decoration: BoxDecoration(
                color: theme.card,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
              ),
              child: _buildWeeklyChart(focusSessions, theme),
            ),
            const SizedBox(height: 30),

            // Recent Sessions
            Text(
              'آخر الجلسات',
              style: GoogleFonts.ibmPlexSansArabic(
                color: theme.primaryText,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (focusSessions.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text('لا توجد جلسات مسجلة بعد.', style: GoogleFonts.ibmPlexSansArabic(color: theme.textSecondary)),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: focusSessions.length > 10 ? 10 : focusSessions.length,
                itemBuilder: (context, index) {
                  return _buildSessionTile(focusSessions[index], theme);
                },
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, ThemeProvider theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
        
      ),
      child: Column(
        children: [
          Icon(icon, color: theme.accentOrange, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.ibmPlexSansArabic(
              color: theme.primaryText,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.ibmPlexSansArabic(
              color: theme.textSecondary,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSessionTile(Map<String, dynamic> session, ThemeProvider theme) {
    final isFocus = session['type'] == 'focus';
    final color = isFocus ? theme.accentOrange : Colors.cyan;
    final iconText = isFocus ? '🧠' : '☕';
    final title = isFocus ? 'جلسة تركيز' : 'استراحة';
    final duration = session['duration'] ?? 0;
    
    final date = (session['date'] as dynamic)?.toDate() as DateTime?;
    final dateStr = date != null ? intl.DateFormat('dd MMM - hh:mm a', 'ar').format(date) : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                iconText,
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.ibmPlexSansArabic(
                    color: theme.primaryText,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  dateStr,
                  style: GoogleFonts.ibmPlexSansArabic(
                    color: theme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$duration د',
              style: GoogleFonts.ibmPlexSansArabic(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(List<Map<String, dynamic>> sessions, ThemeProvider theme) {
    // Generate data for the last 7 days including today
    final now = DateTime.now();
    final List<BarChartGroupData> barGroups = [];
    
    // We want last 7 days ending today. Let's go backwards from today 6 days.
    // Index 0 (left) = 6 days ago, Index 6 (right) = today.
    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: 6 - i));
      
      // Calculate total focus minutes for this specific date
      int dailyMinutes = 0;
      for (var s in sessions) {
        if (s['type'] == 'focus') {
          final sDate = (s['date'] as dynamic)?.toDate() as DateTime?;
          if (sDate != null && sDate.year == date.year && sDate.month == date.month && sDate.day == date.day) {
            dailyMinutes += (s['duration'] as int? ?? 0);
          }
        }
      }

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: dailyMinutes.toDouble(),
              color: theme.accentOrange,
              width: 14,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: 120, // A reference max value for background
                color: theme.isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
              ),
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 120, // Let's scale up dynamically or cap at 120. Ideally dynamically.
        // Find max Y for better scaling
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${rod.toY.round()} دقيقة',
                GoogleFonts.ibmPlexSansArabic(color: Colors.white, fontWeight: FontWeight.bold),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final date = now.subtract(Duration(days: 6 - value.toInt()));
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _getWeekdayShort(date.weekday),
                    style: GoogleFonts.ibmPlexSansArabic(
                      color: theme.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false), // Hide left titles for clean look
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 30,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: theme.isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  String _getWeekdayName(int weekday) {
    switch (weekday) {
      case DateTime.saturday: return 'السبت';
      case DateTime.sunday: return 'الأحد';
      case DateTime.monday: return 'الاثنين';
      case DateTime.tuesday: return 'الثلاثاء';
      case DateTime.wednesday: return 'الأربعاء';
      case DateTime.thursday: return 'الخميس';
      case DateTime.friday: return 'الجمعة';
      default: return '';
    }
  }

  String _getWeekdayShort(int weekday) {
    switch (weekday) {
      case DateTime.saturday: return 'سبت';
      case DateTime.sunday: return 'أحد';
      case DateTime.monday: return 'إثن';
      case DateTime.tuesday: return 'ثلا';
      case DateTime.wednesday: return 'أرب';
      case DateTime.thursday: return 'خمي';
      case DateTime.friday: return 'جمع';
      default: return '';
    }
  }
}
