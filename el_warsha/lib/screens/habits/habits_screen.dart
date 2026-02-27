import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';

import '../../providers/theme_provider.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/habit_model.dart';
import 'add_habit_screen.dart';
import 'habit_detail_screen.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> with SingleTickerProviderStateMixin {
  final DatabaseService _dbService = DatabaseService();
  late TabController _tabController;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  int _calculateGlobalLongestStreak(List<HabitModel> habits) {
    if (habits.isEmpty) return 0;
    return habits.map((h) => h.longestStreak).reduce((a, b) => a > b ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final authService = context.watch<AuthService>();
    final user = authService.currentUser;

    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: theme.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'العادات 🌱',
          style: GoogleFonts.cairo(
            color: theme.primaryText,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle, color: theme.accentOrange, size: 28),
            onPressed: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => const AddHabitScreen()),
              );
            },
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.accentOrange,
          labelColor: theme.accentOrange,
          unselectedLabelColor: theme.textSecondary,
          labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
          tabs: const [
            Tab(text: 'عاداتي'),
            Tab(text: 'سلبية'),
            Tab(text: 'إيجابية'),
          ],
        ),
      ),
      body: Stack(
        children: [
          StreamBuilder<List<HabitModel>>(
            stream: _dbService.getUserHabits(user.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(color: theme.accentOrange));
              }

              final allHabits = snapshot.data ?? [];
              final negativeHabits = allHabits.where((h) => h.type == 'negative').toList();
              final positiveHabits = allHabits.where((h) => h.type == 'positive').toList();

              return Column(
                children: [
                  _buildHeaderCard(theme, allHabits),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildHabitList(allHabits, theme, user.uid, 'لم تبدأ في تتبع أي عادات بعد!'),
                        _buildHabitList(negativeHabits, theme, user.uid, 'لا يوجد عادات سلبية تتابعها.'),
                        _buildHabitList(positiveHabits, theme, user.uid, 'لا يوجد عادات إيجابية تتابعها.'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [Colors.green, Colors.blue, Colors.orange, Colors.pink],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(ThemeProvider theme, List<HabitModel> habits) {
    final longestStreak = _calculateGlobalLongestStreak(habits);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.accentOrange.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: theme.accentOrange.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        textDirection: TextDirection.rtl,
        children: [
           Column(
             mainAxisSize: MainAxisSize.min,
             children: [
               Text(
                 'أطول سلسلة استمرار 🔥',
                 style: GoogleFonts.cairo(color: theme.textSecondary, fontSize: 16, fontWeight: FontWeight.bold),
               ),
               const SizedBox(height: 8),
               Text(
                 longestStreak.toString(),
                 style: GoogleFonts.tajawal(
                   color: theme.accentOrange,
                   fontSize: 48,
                   fontWeight: FontWeight.w900,
                   shadows: [Shadow(color: theme.accentOrange.withValues(alpha: 0.4), blurRadius: 15)],
                 ),
               ),
               Text(
                 'يوم',
                 style: GoogleFonts.cairo(color: theme.textSecondary, fontSize: 16),
               ),
             ],
           )
        ],
      ),
    );
  }

  Widget _buildHabitList(List<HabitModel> habits, ThemeProvider theme, String uid, String emptyMsg) {
    if (habits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.spa_outlined, size: 80, color: theme.textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(emptyMsg, style: GoogleFonts.cairo(color: theme.textSecondary, fontSize: 18)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddHabitScreen())),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.accentOrange,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('ابدأ رحلتك', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 20),
      itemCount: habits.length,
      itemBuilder: (context, index) {
        final habit = habits[index];
        return _buildHabitCard(habit, theme, uid);
      },
    );
  }

  Widget _buildHabitCard(HabitModel habit, ThemeProvider theme, String uid) {
    final isPositive = habit.type == 'positive';
    final accentColor = _parseColor(habit.color);
    
    // Check if recorded today
    final todayStr = DateTime.now().toIso8601String().split('T').first;
    bool checkedInToday = false;
    if (habit.lastCheckIn != null) {
      final lastCheckInStr = habit.lastCheckIn!.toDate().toIso8601String().split('T').first;
      checkedInToday = lastCheckInStr == todayStr;
    }

    final int progressDays = habit.totalCleanDays;
    final int target = habit.targetDays;
    final double progressPercent = (progressDays / target).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => HabitDetailScreen(habit: habit)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: checkedInToday ? accentColor.withValues(alpha: 0.3) : theme.isDarkMode ? Colors.white12 : Colors.black12),
          boxShadow: checkedInToday ? [BoxShadow(color: accentColor.withValues(alpha: 0.1), blurRadius: 10)] : [],
        ),
        child: Column(
          children: [
            // Top Row
            Row(
              textDirection: TextDirection.rtl,
              children: [
                CircleAvatar(backgroundColor: accentColor.withValues(alpha: 0.2), radius: 24, child: Text(habit.icon, style: const TextStyle(fontSize: 24))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(habit.name, style: GoogleFonts.cairo(color: theme.primaryText, fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(habit.category, style: GoogleFonts.cairo(color: theme.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Text(habit.currentStreak.toString(), style: GoogleFonts.tajawal(color: accentColor, fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 4),
                    Text('🔥', style: TextStyle(fontSize: 20)),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Progress Row
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progressPercent,
                      backgroundColor: theme.bg,
                      color: accentColor,
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text('$progressDays / $target', style: GoogleFonts.tajawal(color: theme.textSecondary, fontSize: 14)),
              ],
            ),

            const SizedBox(height: 20),
            
            // Actions Row
            if (!checkedInToday)
              Row(
                textDirection: TextDirection.rtl,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _actionButton('✅ نظيف', Colors.green, () => _handleCheckIn(uid, habit.id, 'clean')),
                  _actionButton('⚠️ زلة', Colors.redAccent, () => _handleCheckIn(uid, habit.id, 'slip')),
                  _actionButton('⏭️ تخطي', Colors.grey, () => _handleCheckIn(uid, habit.id, 'skip')),
                ],
              )
            else
              Text('🎉 تم التسجيل اليوم بنجاح!', style: GoogleFonts.cairo(color: Colors.green, fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(label, style: GoogleFonts.cairo(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
      ),
    );
  }

  Future<void> _handleCheckIn(String uid, String habitId, String status) async {
    if (status == 'clean') {
      _confettiController.play();
    }
    await _dbService.checkInHabit(uid, habitId, status, null);
  }

  Color _parseColor(String colorCode) {
    try {
      return Color(int.parse(colorCode.replaceAll('#', '0xff')));
    } catch (e) {
      return Colors.orange;
    }
  }
}
