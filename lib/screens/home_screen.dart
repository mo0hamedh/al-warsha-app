import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/task_model.dart';
import '../models/user_model.dart';
import '../providers/task_provider.dart';
import '../providers/pomodoro_provider.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../widgets/add_task_dialog.dart';
import '../providers/theme_provider.dart';
import 'profile/profile_screen.dart';
import 'stats_screen.dart';
import 'monthly_leaderboard_screen.dart';
import '../models/category_data.dart';
import 'habits/habits_screen.dart';
import 'schedule/schedule_screen.dart';
import '../widgets/daily_checkin_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _dbService = DatabaseService();
  String _selectedFilter = 'الكل';
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DailyCheckInDialog.showIfNeeded(context);
    });
  }

  // ── Max content width for large screens (Web / Desktop) ──
  static const double _maxWidth = 800;

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
      floatingActionButton: _selectedIndex == 0 ? FloatingActionButton(
        onPressed: () => showDialog(context: context, builder: (_) => const AddTaskDialog()),
        backgroundColor: themeProvider.accentOrange,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 8,
        child: const Icon(Icons.add, size: 28),
      ) : null,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: themeProvider.card,
        selectedItemColor: themeProvider.accentOrange,
        unselectedItemColor: themeProvider.textSecondary,
        selectedLabelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        unselectedLabelStyle: GoogleFonts.cairo(),
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.task_alt), label: 'المهام'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'الجدول'),
          BottomNavigationBarItem(icon: Icon(Icons.track_changes), label: 'العادات'),
        ],
      ),
      body: _selectedIndex == 0 
          ? _buildTasksDashboard(authService, themeProvider, user)
          : _selectedIndex == 1
              ? const ScheduleScreen()
              : const HabitsScreen(),
    );
  }

  Widget _buildTasksDashboard(AuthService authService, ThemeProvider themeProvider, dynamic user) {
    return Stack(
      children: [
        // ── Subtle Background Pattern ──
        Positioned.fill(
          child: IgnorePointer(
            child: Opacity(
              opacity: 0.03,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  mainAxisSpacing: 50,
                  crossAxisSpacing: 50,
                ),
                itemBuilder: (context, index) {
                  final icons = [Icons.handyman, Icons.architecture, Icons.build, Icons.design_services];
                  return Icon(icons[index % icons.length], size: 40, color: Colors.white);
                },
              ),
            ),
          ),
        ),
        
        SafeArea(
          child: Column(
            children: [
              // ── Top bar (full width, not constrained) ──
              _buildTopBar(context, authService, themeProvider),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: _maxWidth),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      child: Directionality(
                        textDirection: TextDirection.rtl,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(user.uid, themeProvider),
                            const SizedBox(height: 20),
                            _buildPomodoroCard(themeProvider),
                            const SizedBox(height: 28),
                            _buildTaskSection(themeProvider, user.uid),
                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context, AuthService authService, ThemeProvider theme) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.person_outline, color: theme.isDarkMode ? Colors.white70 : Colors.black87),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              ),
            ),
            IconButton(
              icon: Icon(Icons.bar_chart, color: theme.isDarkMode ? Colors.white70 : Colors.black87),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StatsScreen()),
              ),
            ),
            IconButton(
              icon: Icon(Icons.emoji_events, color: theme.isDarkMode ? Colors.white70 : Colors.black87),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MonthlyLeaderboardScreen()),
              ),
            ),
            Expanded(
              child: Text(
                'الـ وَرشة',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  color: theme.primaryText,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: theme.primaryText.withOpacity(0.6), blurRadius: 12)], // Neon effect
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.logout_outlined, color: Colors.redAccent),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: theme.card,
                    title: Text('تسجيل خروج؟',
                        style: GoogleFonts.cairo(
                            color: theme.primaryText, fontWeight: FontWeight.bold)),
                    content: Text('هل أنت متأكد؟',
                        style: GoogleFonts.cairo(color: theme.textSecondary)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('إلغاء',
                            style: GoogleFonts.cairo(color: Colors.grey)),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent),
                        child: Text('خروج',
                            style: GoogleFonts.cairo(color: Colors.white)),
                      ),
                    ],
                  ),
                );
                if (confirm == true && mounted) await authService.logout();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String uid, ThemeProvider theme) {
    return StreamBuilder<UserModel?>(
      stream: _dbService.getUserProfile(uid),
      builder: (context, snap) {
        final profile = snap.data;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [theme.card, theme.isDarkMode ? const Color(0xFF252525) : Colors.grey[200]!],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: theme.bg,
                backgroundImage:
                    profile?.photoUrl.isNotEmpty == true
                        ? NetworkImage(profile!.photoUrl)
                        : null,
                child: profile?.photoUrl.isEmpty != false
                    ? Icon(Icons.person, color: theme.isDarkMode ? Colors.white54 : Colors.black54, size: 28)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text('أهلاً،',
                            style: GoogleFonts.cairo(
                                color: theme.textSecondary, fontSize: 13)),
                        if (profile?.isAdmin == true) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                            ),
                            child: Text(
                              'مشرف',
                              style: GoogleFonts.cairo(
                                color: Colors.redAccent,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ]
                      ],
                    ),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            profile?.name ?? 'مستخدم',
                            style: GoogleFonts.cairo(
                                color: theme.primaryText,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                shadows: [Shadow(color: theme.primaryText.withOpacity(0.4), blurRadius: 6)], // Subtle neon
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (profile?.isPremium == true)
                          GestureDetector(
                            onTap: () {
                              // Navigate to subscription details (Placeholder for now)
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تفاصيل الاشتراك قريباً')));
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.workspace_premium, size: 12, color: Colors.black),
                                  const SizedBox(width: 4),
                                  Text("مشترك", style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black)),
                                ],
                              ),
                            ),
                          )
                        else
                          GestureDetector(
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const ScheduleScreen()));
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                border: Border.all(color: const Color(0xFFFF6A00)),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.lock, size: 12, color: Color(0xFFFF6A00)),
                                  const SizedBox(width: 4),
                                  Text("غير مشترك", style: GoogleFonts.cairo(fontSize: 10, color: const Color(0xFFFF6A00))),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Weekly Focus Rank Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.accentOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.accentOrange.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_fire_department,
                        color: theme.accentOrange, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${profile?.weeklyFocusPoints ?? 0} نقطة',
                      style: GoogleFonts.tajawal(
                          color: theme.accentOrange,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showPomodoroOptions(BuildContext context, ThemeProvider theme, PomodoroProvider pomodoro) async {
    bool isFocus = !pomodoro.isRestMode;
    int selectedMinutes = pomodoro.isRestMode ? 10 : 25;

    final focusOptions = [15, 25, 45, 60];
    final restOptions = [5, 10, 15];

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final activeOptions = isFocus ? focusOptions : restOptions;
            if (!activeOptions.contains(selectedMinutes)) {
              selectedMinutes = activeOptions.first;
            }

            final activeColor = isFocus ? theme.accentOrange : Colors.cyan;

            return Directionality(
              textDirection: TextDirection.rtl,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.bg,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(color: activeColor.withOpacity(0.1), blurRadius: 20, spreadRadius: 5)
                  ]
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'إعداد الجلسة',
                      style: GoogleFonts.cairo(
                        color: theme.primaryText,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(() => isFocus = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isFocus ? theme.accentOrange.withOpacity(0.1) : theme.card,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isFocus ? theme.accentOrange : Colors.transparent),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'تركيز 🧠',
                                style: GoogleFonts.cairo(
                                  color: isFocus ? theme.accentOrange : theme.textSecondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(() => isFocus = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: !isFocus ? Colors.cyan.withOpacity(0.1) : theme.card,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: !isFocus ? Colors.cyan : Colors.transparent),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'استراحة ☕',
                                style: GoogleFonts.cairo(
                                  color: !isFocus ? Colors.cyan : theme.textSecondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'المدة (بالدقائق)',
                      style: GoogleFonts.cairo(color: theme.primaryText),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: activeOptions.map((mins) {
                        final isSelected = selectedMinutes == mins;
                        return GestureDetector(
                          onTap: () => setModalState(() => selectedMinutes = mins),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? activeColor.withOpacity(0.1) : theme.card,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isSelected ? activeColor : Colors.transparent),
                            ),
                            child: Text(
                              '$mins',
                              style: GoogleFonts.tajawal(
                                color: isSelected ? activeColor : theme.textSecondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () {
                        pomodoro.setSession(selectedMinutes, isRest: !isFocus);
                        pomodoro.startTimer();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.accentOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 8,
                        shadowColor: theme.accentOrange.withOpacity(0.5),
                      ),
                      child: Text('ابدأ', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPomodoroCard(ThemeProvider theme) {
    final pomodoro = context.watch<PomodoroProvider>();
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: theme.isDarkMode ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04), // Glassmorphism base
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.isDarkMode ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1)), // Updated border opacity
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left side: label + timer
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(pomodoro.isRestMode ? '☕ استراحة' : '⏱ جلسة تركيز',
                          style: GoogleFonts.cairo(
                              color: pomodoro.isRestMode ? Colors.cyan : theme.textSecondary, 
                              fontSize: 13,
                              fontWeight: pomodoro.isRestMode ? FontWeight.bold : FontWeight.normal)),
                      const SizedBox(height: 6),
                      Text(
                        pomodoro.timeDisplay,
                        style: GoogleFonts.tajawal(
                          color: theme.primaryText,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3,
                          shadows: [Shadow(color: theme.primaryText.withOpacity(0.5), blurRadius: 10)], // Neon timer
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Progress bar inside card
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pomodoro.progress,
                          backgroundColor: theme.isDarkMode ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.1),
                          color: pomodoro.isRestMode ? Colors.cyan : theme.accentOrange,
                          minHeight: 4,
                        ),
                      ),
                    ],
                  ),
                ),
                // Vertical divider
                Container(
                  width: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  color: theme.isDarkMode ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.1),
                ),
                // Right side: controls
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (pomodoro.isRunning) {
                          pomodoro.pauseTimer();
                        } else if (pomodoro.progress < 1.0) { // Has been paused
                          pomodoro.startTimer();
                        } else {
                          _showPomodoroOptions(context, theme, pomodoro);
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: pomodoro.isRunning ? [BoxShadow(color: theme.accentOrange.withOpacity(0.4), blurRadius: 12)] : [],
                        ),
                        child: Icon(
                          pomodoro.isRunning
                              ? Icons.pause_circle_filled_rounded
                              : Icons.play_circle_fill_rounded,
                          size: 56,
                          color: theme.accentOrange,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: pomodoro.resetTimer,
                      child: Icon(Icons.refresh_rounded,
                          color: theme.textSecondary, size: 26),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool selected, ThemeProvider theme, {TaskCategory? customCategory, String? uid}) {
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      onLongPress: customCategory != null && uid != null ? () {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: theme.card,
            title: Text('حذف التصنيف؟', style: GoogleFonts.cairo(color: theme.primaryText, fontWeight: FontWeight.bold)),
            content: Text(
              'هل تريد حذف تصنيف \'$label\'؟\nسيتم إزالته من جميع المهام',
              style: GoogleFonts.cairo(color: theme.textSecondary),
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  if (_selectedFilter == label) {
                    setState(() => _selectedFilter = 'الكل');
                  }
                  await _dbService.deleteCustomCategory(uid, customCategory.id);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('تم حذف التصنيف وتحديث المهام', style: GoogleFonts.cairo()),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5252)),
                child: Text('حذف', style: GoogleFonts.cairo(color: Colors.white)),
              ),
            ],
          ),
        );
      } : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? theme.accentOrange : theme.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? theme.accentOrange : (theme.isDarkMode ? Colors.white12 : Colors.black12)),
          boxShadow: selected ? [BoxShadow(color: theme.accentOrange.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))] : [],
        ),
        child: Text(
          label,
          style: GoogleFonts.cairo(
            color: selected ? Colors.white : theme.textSecondary,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildTaskSection(ThemeProvider theme, String uid) {
    final taskProvider = context.watch<TaskProvider>();
    return StreamBuilder<List<TaskCategory>>(
      stream: _dbService.getCustomCategories(uid),
      builder: (context, catSnapshot) {
        final customCategories = catSnapshot.data ?? [];
        final allCategories = [...taskCategories, ...customCategories];
        final currentFilters = ['الكل', 'المهام', 'المكتملة', ...allCategories.map((c) => c.name)];

        return StreamBuilder<List<TaskModel>>(
          stream: taskProvider.tasksStream,
          builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: CircularProgressIndicator(color: theme.accentOrange),
            ),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'خطأ: ${snapshot.error}',
                style: GoogleFonts.cairo(color: Colors.redAccent),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final allTasks = snapshot.data ?? [];
        final completed = allTasks.where((t) => t.isCompleted).length;
        final total = allTasks.length;

        final filtered = _selectedFilter == 'المكتملة'
            ? allTasks.where((t) => t.isCompleted).toList()
            : _selectedFilter == 'المهام'
                ? allTasks.where((t) => !t.isCompleted).toList()
                : _selectedFilter == 'الكل'
                    ? allTasks
                    : allTasks.where((t) {
                        final catName = allCategories.firstWhere((c) => c.id == t.category, orElse: () => taskCategories.last).name;
                        return catName == _selectedFilter;
                      }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section title + counter
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('المهام',
                    style: GoogleFonts.cairo(
                        color: theme.primaryText,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.accentOrange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$completed / $total',
                    style: GoogleFonts.tajawal(
                        color: theme.accentOrange,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: total > 0 ? completed / total : 0.0,
                backgroundColor: theme.isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05), // faded grey/white
                color: theme.accentOrange,
                minHeight: 7,
              ),
            ),
            const SizedBox(height: 16),
            // Custom filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Row(
                children: currentFilters.map((f) {
                  TaskCategory? customCat;
                  try {
                    customCat = customCategories.firstWhere((c) => c.name == f);
                  } catch (_) {}
                  return Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: _buildFilterChip(
                      f, 
                      _selectedFilter == f, 
                      theme,
                      customCategory: customCat,
                      uid: uid,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            // Task list
            if (filtered.isEmpty)
              _buildEmptyState(theme)
            else
              Column(
                children: [
                  for (final task in filtered) _buildTaskCard(task, taskProvider, theme, allCategories),
                ],
              ),
          ],
        );
      },
    );
      },
    );
  }


  Widget _buildEmptyState(ThemeProvider theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline,
                size: 60, color: theme.isDarkMode ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.15)),
            const SizedBox(height: 14),
            Text(
              _selectedFilter == 'المكتملة'
                  ? 'لا توجد مهام مكتملة'
                  : 'لا توجد مهام حالياً، اضغط + لإضافة مهمة',
              style: GoogleFonts.cairo(color: theme.textSecondary, fontSize: 15),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(TaskModel task, TaskProvider taskProvider, ThemeProvider theme, List<TaskCategory> allCategories) {
    final catColor = allCategories.firstWhere((c) => c.id == task.category, orElse: () => taskCategories.last).color;
    final catIcon = allCategories.firstWhere((c) => c.id == task.category, orElse: () => taskCategories.last).icon;
    final barColor = task.isCompleted ? Colors.grey.withOpacity(0.25) : catColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: IntrinsicHeight(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            color: theme.card,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Accent bar ──
                Container(
                  width: 5, 
                  color: barColor,
                  child: task.isCompleted ? null : Container(
                    decoration: BoxDecoration(
                      boxShadow: [BoxShadow(color: theme.accentOrange.withOpacity(0.5), blurRadius: 4)]
                    ),
                  ),
                ),

                // ── Card content ──
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        // Checkbox
                        SizedBox(
                          width: 26,
                          height: 26,
                          child: Checkbox(
                            value: task.isCompleted,
                            activeColor: theme.accentOrange,
                            checkColor: Colors.white,
                            side: BorderSide(
                                color: Colors.grey[600]!, width: 1.5),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6)),
                            onChanged: (_) =>
                                taskProvider.toggleTaskStatus(task),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (task.category != 'other')
                                    Padding(
                                      padding: const EdgeInsets.only(left: 6.0),
                                      child: Icon(catIcon, size: 16, color: task.isCompleted ? Colors.grey : catColor),
                                    ),
                                  Expanded(
                                    child: Text(
                                      task.title,
                                      textAlign: TextAlign.right,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                      style: GoogleFonts.cairo(
                                        color: task.isCompleted
                                            ? Colors.grey[600]
                                            : theme.primaryText,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        decoration: task.isCompleted
                                            ? TextDecoration.lineThrough
                                            : null,
                                        decorationColor: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (task.description.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  task.description,
                                  textAlign: TextAlign.right,
                                  style: GoogleFonts.cairo(
                                      color: theme.textSecondary, fontSize: 12),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              if (task.estimatedMinutes > 0) ...[
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: task.isCompleted ? Colors.grey.withOpacity(0.1) : theme.accentOrange.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.access_time, size: 12, color: task.isCompleted ? Colors.grey : theme.accentOrange),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${task.estimatedMinutes} دقيقة',
                                        style: GoogleFonts.cairo(
                                          color: task.isCompleted ? Colors.grey : theme.accentOrange,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),
                        // Delete button
                        GestureDetector(
                          onTap: () => taskProvider.deleteTask(task.id),
                          child: Icon(Icons.delete_outline_rounded,
                              color: theme.isDarkMode ? Colors.white.withOpacity(0.22) : Colors.black.withOpacity(0.4), size: 20),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
