import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../providers/theme_provider.dart';
import 'package:el_warsha/features/auth/services/auth_service.dart';
import '../../../services/database_service.dart';
import '../models/habit_model.dart';

class HabitDetailScreen extends StatefulWidget {
  final HabitModel habit;

  const HabitDetailScreen({super.key, required this.habit});

  @override
  State<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen> {
  final DatabaseService _dbService = DatabaseService();
  List<HabitLogModel> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    final authService = context.read<AuthService>();
    final user = authService.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final monthPrefix = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    
    final logs = await _dbService.getHabitLogs(user.uid, widget.habit.id, monthPrefix);
    if (mounted) {
      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final color = Color(int.parse(widget.habit.color.replaceAll('#', '0xff')));
    
    int successRate = 0;
    if (widget.habit.startDate.toDate().isBefore(DateTime.now())) {
      final daysSinceStart = DateTime.now().difference(widget.habit.startDate.toDate()).inDays + 1;
      successRate = daysSinceStart > 0 ? ((widget.habit.totalCleanDays / daysSinceStart) * 100).round() : 0;
    }

    return Scaffold(
      backgroundColor: theme.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: theme.primaryText, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
           IconButton(
             icon: Icon(Icons.delete_outline, color: Colors.redAccent),
             onPressed: () => _confirmDelete(theme),
           )
        ],
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: color))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: color.withValues(alpha: 0.2),
                      child: Text(widget.habit.icon, style: const TextStyle(fontSize: 50, fontFamilyFallback: ['NotoColorEmoji'])),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.habit.name,
                      style: GoogleFonts.tajawal(color: theme.primaryText, fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      widget.habit.category,
                      style: GoogleFonts.tajawal(color: theme.textSecondary, fontSize: 16),
                    ),
                  ],
                ),
                
                const SizedBox(height: 40),
                
                // Stats Row
                Row(
                  children: [
                    Expanded(child: _statBox('أطول سلسلة', '${widget.habit.longestStreak} يوم', theme, color)),
                    const SizedBox(width: 16),
                    Expanded(child: _statBox('أيام النجاح', '${widget.habit.totalCleanDays}', theme, color)),
                    const SizedBox(width: 16),
                    Expanded(child: _statBox('نسبة الالتزام', '$successRate%', theme, color)),
                  ],
                ),
                
                const SizedBox(height: 40),
                
                // Calendar Grid
                Text(
                  'تقويم الشهر الحالي',
                  textAlign: TextAlign.right,
                  style: GoogleFonts.tajawal(color: theme.primaryText, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildCalendar(theme),
              ],
            ),
          ),
    );
  }

  Widget _statBox(String label, String value, ThemeProvider theme, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(value, style: GoogleFonts.tajawal(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.tajawal(color: theme.textSecondary, fontSize: 12), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildCalendar(ThemeProvider theme) {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    
    // Create a map of date strings to statuses
    final logMap = {for (var log in _logs) log.date: log.status};

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: daysInMonth,
      itemBuilder: (context, index) {
        final day = index + 1;
        final date = DateTime(now.year, now.month, day);
        final dateStr = date.toIso8601String().split('T').first;
        final status = logMap[dateStr];
        
        Color boxColor = theme.card;
        Color textColor = theme.textSecondary;
        BoxBorder? border;

        if (date.isBefore(widget.habit.startDate.toDate().subtract(const Duration(days: 1)))) {
           boxColor = theme.bg; // Before habit started
        } else if (status == 'clean') {
           boxColor = Colors.green.withValues(alpha: 0.2);
           textColor = Colors.green;
           border = Border.all(color: Colors.green.withValues(alpha: 0.5));
        } else if (status == 'slip') {
           boxColor = Colors.red.withValues(alpha: 0.2);
           textColor = Colors.redAccent;
           border = Border.all(color: Colors.redAccent.withValues(alpha: 0.5));
        } else if (status == 'skip') {
           boxColor = Colors.grey.withValues(alpha: 0.2);
           textColor = Colors.grey;
        } else if (date.year == now.year && date.month == now.month && date.day == now.day) {
           boxColor = Colors.amber.withValues(alpha: 0.2); // Today ring
           textColor = Colors.amber;
           border = Border.all(color: Colors.amber, width: 2);
        }

        return Container(
          decoration: BoxDecoration(
            color: boxColor,
            borderRadius: BorderRadius.circular(8),
            border: border,
          ),
          child: Center(
            child: Text(
              day.toString(),
              style: GoogleFonts.tajawal(color: textColor, fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(ThemeProvider theme) async {
     final bool? confirm = await showDialog(
       context: context,
       builder: (ctx) => AlertDialog(
         backgroundColor: theme.card,
         title: Text('حذف العادة', style: GoogleFonts.tajawal(color: theme.primaryText)),
         content: Text('هل أنت متأكد أنك تريد حذف هذه العادة وسجلها بالكامل؟', style: GoogleFonts.tajawal(color: theme.textSecondary)),
         actions: [
           TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('إلغاء')),
           TextButton(
             onPressed: () => Navigator.pop(ctx, true), 
             child: Text('حذف', style: TextStyle(color: Colors.redAccent)),
           ),
         ],
       )
     );

     if (confirm == true) {
        final authService = context.read<AuthService>();
        if (authService.currentUser != null) {
          await _dbService.deleteHabit(authService.currentUser!.uid, widget.habit.id);
          if (mounted) Navigator.pop(context);
        }
     }
  }
}
