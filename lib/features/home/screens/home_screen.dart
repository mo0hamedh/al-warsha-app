import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:el_warsha/features/tasks/models/task_model.dart';
import 'package:el_warsha/features/tasks/models/admin_task_model.dart';
import '../../../models/user_model.dart';
import 'package:el_warsha/features/tasks/providers/task_provider.dart';
import 'package:el_warsha/features/study_room/providers/pomodoro_provider.dart';
import 'package:el_warsha/features/auth/services/auth_service.dart';
import '../../../../services/database_service.dart';
import '../../../../services/connectivity_service.dart';
import '../../../../services/local_storage_service.dart';
import 'package:el_warsha/features/tasks/widgets/add_task_dialog.dart';
import '../../../../providers/theme_provider.dart';
import '../../profile/screens/profile_screen.dart';
import '../../leaderboard/screens/stats_screen.dart';
import '../../leaderboard/screens/monthly_leaderboard_screen.dart';
import 'package:el_warsha/features/profile/models/category_data.dart';
import '../../habits/screens/habits_screen.dart';
import '../../schedule/screens/schedule_screen.dart';
import 'package:el_warsha/features/habits/widgets/daily_checkin_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _dbService = DatabaseService();
  final String _selectedFilter = 'الكل';
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DailyCheckInDialog.showIfNeeded(context);
    });
    _checkAndLockYesterday();
  }

  bool _isSameDay(DateTime? date1, DateTime date2) {
    if (date1 == null) return false;
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  Future<void> _checkAndLockYesterday() async {
    final now = DateTime.now();
    final lastCheck = await LocalStorageService.getLastLockCheck();
    
    if (!_isSameDay(lastCheck, now)) {
      final user = context.read<AuthService>().currentUser;
      if (user != null) {
        final schedule = await _dbService.getActiveSchedule().first;
        if (schedule != null) {
          await _dbService.lockPreviousDay(user.uid, schedule.id);
        }
      }
      await LocalStorageService.setLastLockCheck(now);
    }
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
        body: Center(
          child: CircularProgressIndicator(color: themeProvider.accentColor),
        ),
      );
    }

    return Scaffold(
      backgroundColor: themeProvider.bg,
      floatingActionButton:
          _selectedIndex == 0
              ? FloatingActionButton(
                onPressed:
                    () => showDialog(
                      context: context,
                      builder: (_) => const AddTaskDialog(),
                    ),
                backgroundColor: theme.accentColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 8,
                child: const Icon(Icons.add, size: 28),
              )
              : null,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: themeProvider.card,
        selectedItemColor: themeProvider.accentColor,
        unselectedItemColor: themeProvider.textSecondary,
        selectedLabelStyle: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
        unselectedLabelStyle: GoogleFonts.tajawal(),
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Text("📋", style: TextStyle(fontSize: 20), textAlign: TextAlign.center),
            label: 'المهام',
          ),
          BottomNavigationBarItem(
            icon: Text("📅", style: TextStyle(fontSize: 20), textAlign: TextAlign.center),
            label: 'الجدول',
          ),
          BottomNavigationBarItem(
            icon: Text("🎯", style: TextStyle(fontSize: 20), textAlign: TextAlign.center),
            label: 'العادات',
          ),
        ],
      ),
      body: Column(
        children: [
          StreamBuilder<bool>(
            stream: ConnectivityService.onlineStatus,
            builder: (context, snapshot) {
              final isOnline = snapshot.data ?? true;
              if (isOnline) return const SizedBox.shrink();

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 6,
                  horizontal: 16,
                ),
                color: const Color(0xFFFF5252),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      "أنت غير متصل - جارِ الحفظ محلياً",
                      style: GoogleFonts.tajawal(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Expanded(
            child:
                _selectedIndex == 0
                    ? _buildTasksDashboard(authService, themeProvider, user)
                    : _selectedIndex == 1
                    ? const ScheduleScreen()
                    : const HabitsScreen(),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksDashboard(
    AuthService authService,
    ThemeProvider themeProvider,
    dynamic user,
  ) {
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
                  final icons = [
                    Icons.handyman,
                    Icons.architecture,
                    Icons.build,
                    Icons.design_services,
                  ];
                  return Icon(
                    icons[index % icons.length],
                    size: 40,
                    color: Colors.white,
                  );
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
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 8,
                      ),
                      child: Directionality(
                        textDirection: TextDirection.rtl,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            HomeHeaderWidget(uid: user.uid),
                            const SizedBox(height: 24),
                            RepaintBoundary(child: const PomodoroCardWidget()),
                            const SizedBox(height: 24),
                            Expanded(
                              child: _buildTaskSection(themeProvider, user.uid),
                            ),
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

  Widget _buildTopBar(
    BuildContext context,
    AuthService authService,
    ThemeProvider theme,
  ) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.person_outline,
                color: theme.isDarkMode ? Colors.white70 : Colors.black87,
              ),
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  ),
            ),
            IconButton(
              icon: Icon(
                Icons.bar_chart,
                color: theme.isDarkMode ? Colors.white70 : Colors.black87,
              ),
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const StatsScreen()),
                  ),
            ),
            IconButton(
              icon: Icon(
                Icons.emoji_events,
                color: theme.isDarkMode ? Colors.white70 : Colors.black87,
              ),
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MonthlyLeaderboardScreen(),
                    ),
                  ),
            ),
            Expanded(
              child: Text(
                'الـ وَرشة',
                textAlign: TextAlign.center,
                style: GoogleFonts.tajawal(
                  color: theme.primaryText,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: theme.primaryText.withOpacity(0.6),
                      blurRadius: 12,
                    ),
                  ], // Neon effect
                ),
              ),
            ),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: DatabaseService().getUserNotifications(
                authService.currentUser?.uid ?? '',
              ),
              builder: (context, snapshot) {
                final notifications = snapshot.data ?? [];
                final unreadCount =
                    notifications.where((n) => n['isRead'] == false).length;
                return IconButton(
                  icon: Badge(
                    isLabelVisible: unreadCount > 0,
                    label: Text('$unreadCount'),
                    child: Icon(
                      Icons.notifications_outlined,
                      color: theme.isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  onPressed:
                      () => _showNotificationsSheet(
                        context,
                        authService.currentUser?.uid ?? '',
                        notifications,
                        theme,
                      ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout_outlined, color: Colors.redAccent),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder:
                      (_) => AlertDialog(
                        backgroundColor: theme.card,
                        title: Text(
                          'تسجيل خروج؟',
                          style: GoogleFonts.tajawal(
                            color: theme.primaryText,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        content: Text(
                          'هل أنت متأكد؟',
                          style: GoogleFonts.tajawal(color: theme.textSecondary),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(
                              'إلغاء',
                              style: GoogleFonts.tajawal(color: Colors.grey),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                            ),
                            child: Text(
                              'خروج',
                              style: GoogleFonts.tajawal(color: Colors.white),
                            ),
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

  void _showNotificationsSheet(
    BuildContext context,
    String uid,
    List<Map<String, dynamic>> notifications,
    ThemeProvider theme,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (_, controller) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الإشعارات',
                      style: GoogleFonts.tajawal(
                        color: theme.primaryText,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child:
                          notifications.isEmpty
                              ? Center(
                                child: Text(
                                  'لا توجد إشعارات حالياً',
                                  style: GoogleFonts.tajawal(
                                    color: theme.textSecondary,
                                  ),
                                ),
                              )
                              : ListView.builder(
                                controller: controller,
                                itemCount: notifications.length,
                                itemBuilder: (context, index) {
                                  final notif = notifications[index];
                                  final isRead = notif['isRead'] == true;
                                  final notifType = notif['type'] ?? '';

                                  IconData iconData = Icons.notifications;
                                  Color iconColor = theme.accentColor;
                                  if (notifType == 'friend_request') {
                                    iconData = Icons.person_add;
                                    iconColor = Colors.blue;
                                  } else if (notifType == 'broadcast') {
                                    iconData = Icons.campaign;
                                    iconColor = Colors.amber;
                                  }

                                  return GestureDetector(
                                    onTap: () {
                                      if (!isRead) {
                                        DatabaseService()
                                            .markNotificationAsRead(
                                              uid,
                                              notif['id'],
                                            );
                                      }
                                      if (notifType == 'friend_request') {
                                        Navigator.pop(ctx);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) => const ProfileScreen(),
                                          ),
                                        );
                                      }
                                    },
                                    child: Card(
                                      color:
                                          isRead
                                              ? theme.card
                                              : theme.card.withOpacity(0.8),
                                      margin: const EdgeInsets.only(bottom: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(
                                          color:
                                              isRead
                                                  ? Colors.transparent
                                                  : theme.accentColor
                                                      .withOpacity(0.5),
                                        ),
                                      ),
                                      child: ListTile(
                                        leading: Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            CircleAvatar(
                                              backgroundColor: iconColor
                                                  .withOpacity(0.2),
                                              child: Icon(
                                                iconData,
                                                color: iconColor,
                                                size: 20,
                                              ),
                                            ),
                                            if (!isRead)
                                              Positioned(
                                                right: -4,
                                                top: -4,
                                                child: Container(
                                                  width: 10,
                                                  height: 10,
                                                  decoration:
                                                      const BoxDecoration(
                                                        color: Colors.red,
                                                        shape: BoxShape.circle,
                                                      ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        title: Text(
                                          notif['title'] ?? '',
                                          style: GoogleFonts.tajawal(
                                            color: theme.primaryText,
                                            fontWeight:
                                                isRead
                                                    ? FontWeight.normal
                                                    : FontWeight.bold,
                                          ),
                                        ),
                                        subtitle: Text(
                                          notif['body'] ?? '',
                                          style: GoogleFonts.tajawal(
                                            color: theme.textSecondary,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
            color: theme.card,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: theme.bg,
                child:
                    profile?.photoUrl != null && profile!.photoUrl.isNotEmpty
                        ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: profile.photoUrl,
                            fit: BoxFit.cover,
                            width: 52, // 2 * radius
                            height: 52, // 2 * radius
                            memCacheWidth: 150,
                            memCacheHeight: 150,
                            placeholder:
                                (context, url) => Container(
                                  color:
                                      theme.isDarkMode
                                          ? Colors.white12
                                          : Colors.black12,
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.grey,
                                  ),
                                ),
                            errorWidget:
                                (context, url, error) => Container(
                                  color:
                                      theme.isDarkMode
                                          ? Colors.white12
                                          : Colors.black12,
                                  child: const Icon(
                                    Icons.error,
                                    color: Colors.red,
                                  ),
                                ),
                          ),
                        )
                        : Icon(
                          Icons.person,
                          size: 30,
                          color:
                              theme.isDarkMode
                                  ? Colors.white54
                                  : Colors.black54,
                        ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          'أهلاً،',
                          style: GoogleFonts.tajawal(
                            color: theme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        if (profile?.isAdmin == true) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: Colors.redAccent.withOpacity(0.5),
                              ),
                            ),
                            child: Text(
                              'مشرف',
                              style: GoogleFonts.tajawal(
                                color: Colors.redAccent,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            profile?.name ?? 'مستخدم',
                            style: GoogleFonts.tajawal(
                              color: theme.primaryText,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: theme.primaryText.withOpacity(0.4),
                                  blurRadius: 6,
                                ),
                              ], // Subtle neon
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
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('تفاصيل الاشتراك قريباً'),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFC5A87C).withValues(alpha: 0.2), // premium gold tint
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.workspace_premium,
                                    size: 12,
                                    color: Colors.black,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "مشترك",
                                    style: GoogleFonts.tajawal(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ScheduleScreen(),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: theme.accentColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.lock,
                                    size: 12,
                                    color: theme.accentColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "غير مشترك",
                                    style: GoogleFonts.tajawal(
                                      fontSize: 10,
                                      color: theme.accentColor,
                                    ),
                                  ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: theme.accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_fire_department,
                      color: theme.accentColor,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${profile?.weeklyFocusPoints ?? 0} نقطة',
                      style: GoogleFonts.tajawal(
                        color: theme.accentColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
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

  Widget _buildTaskSection(ThemeProvider theme, String uid) {
    final taskProvider = context.watch<TaskProvider>();

    return StreamBuilder<List<String>>(
      stream: _dbService.getCompletedAdminTasks(uid),
      builder: (context, completedDocsSnap) {
        final completedAdminIds = completedDocsSnap.data ?? [];

        return StreamBuilder<List<AdminTask>>(
          stream: _dbService.getAdminTasksForUser(uid),
          builder: (context, adminTasksSnap) {
            final adminTasks = adminTasksSnap.data ?? [];

            return StreamBuilder<List<TaskModel>>(
              stream: taskProvider.tasksStream,
              builder: (context, userTasksSnap) {
                if (userTasksSnap.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: CircularProgressIndicator(color: theme.accentColor),
                    ),
                  );
                }

                final userTasks = userTasksSnap.data ?? [];

                // 1. مهام الأدمن غير مكتملة
                // 2. مهام المستخدم غير مكتملة
                // 3. مهام مكتملة (أدمن ثم مستخدم)
                List<dynamic> sortedTasks = [
                  ...adminTasks.where((t) => !completedAdminIds.contains(t.id)),
                  ...userTasks.where((t) => !t.isCompleted),
                  ...adminTasks.where((t) => completedAdminIds.contains(t.id)),
                  ...userTasks.where((t) => t.isCompleted),
                ];

                if (sortedTasks.isEmpty) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: _buildEmptyState(theme),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: sortedTasks.length,
                  itemBuilder: (context, index) {
                      final task = sortedTasks[index];
                      // Determine completion based on list check for AdminTasks
                      bool isCompleted = false;
                      if (task is AdminTask) {
                        isCompleted = completedAdminIds.contains(task.id);
                      } else {
                        isCompleted = task.isCompleted;
                      }

                      return _buildTaskRow(task, isCompleted, uid, taskProvider);
                    },
                  );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildTaskRow(dynamic task, bool isCompleted, String uid, TaskProvider taskProvider) {
    bool isAdminTask = task is AdminTask;
    String title = task.title;

    void toggleTask() {
      if (isAdminTask) {
        if (!isCompleted) {
          _dbService.completeAdminTask(uid, task);
        }
      } else {
        taskProvider.toggleTaskStatus(task);
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).cardColor == const Color(0xFF1A1A1A) ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Checkbox دائري
          GestureDetector(
            onTap: toggleTask,
            child: Container(
              width: 26, 
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                  ? const Color(0xFFC5A87C) // theme.accentColor equivalent
                  : Colors.transparent,
                border: Border.all(
                  color: isCompleted
                    ? const Color(0xFFC5A87C)
                    : const Color(0xFF444444),
                  width: 1.5)
              ),
              child: isCompleted
                ? const Center(
                    child: Text("✓",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        height: 1.1)))
                : null
            ),
          ),
          
          const SizedBox(width: 14),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // لو مهمة أدمن: badge صغيرة
                    if (isAdminTask && !isCompleted)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC5A87C).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8)),
                        child: Text("ورشة",
                          style: GoogleFonts.tajawal(
                            color: const Color(0xFFC5A87C),
                            fontSize: 10))),
                    
                    Expanded(
                      child: Text(
                        title,
                        textAlign: TextAlign.right,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.tajawal(
                          color: isCompleted
                            ? const Color(0xFF444444)
                            : Theme.of(context).textTheme.bodyLarge?.color,
                          fontSize: 15,
                          decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                          decorationColor: const Color(0xFF444444)))),
                  ]),
                
                // الوصف - يظهر بس لو مش null أو فاضي
                if (task.description != null && 
                    task.description.toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      task.description,
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.tajawal(
                        color: const Color(0xFF666666),
                        fontSize: 12))),

                // الوقت والتصنيف في Row
                if ((!isAdminTask && task.estimatedMinutes != null && task.estimatedMinutes > 0) || 
                    (!isAdminTask && task.category != null && task.category != 'other' && task.category != 'الكل') ||
                    (isAdminTask && !isCompleted))
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // التصنيف - لو موجود (للمهام الشخصية)
                        if (!isAdminTask && task.category != null && task.category != 'other' && task.category != 'الكل')
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2A2A2A) : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(6)),
                            child: Text(
                              task.category,
                              style: GoogleFonts.tajawal(
                                color: const Color(0xFF888888),
                                fontSize: 11))),
                        
                        // الوقت - لو موجود (للمهام الشخصية)
                        if (!isAdminTask && task.estimatedMinutes != null && task.estimatedMinutes > 0)
                          Row(children: [
                            Text(
                              "${task.estimatedMinutes} د",
                              style: GoogleFonts.tajawal(
                                color: const Color(0xFF888888),
                                fontSize: 11)),
                            const SizedBox(width: 3),
                            const Text("⏱️", style: TextStyle(fontSize: 11))
                          ]),

                        // النقاط - لو مهمة أدمن
                        if (isAdminTask && !isCompleted)
                          Text("+${task.points} نقطة",
                            textAlign: TextAlign.right,
                            style: GoogleFonts.tajawal(
                              color: const Color(0xFF666666),
                              fontSize: 11))
                      ]))
              ]
            )
          ),
          
          // زرار الحذف (على اليسار)
          if (!isAdminTask) ...[
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => _showDeleteConfirm(context, task, taskProvider),
              child: Container(
                width: 32, 
                height: 32,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2A2A2A) : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10)), // softer
                child: const Center(
                  child: Text("🗑",
                    style: TextStyle(fontSize: 14))))),
          ],
        ]
      )
    );
  }

  void _showDeleteConfirm(BuildContext context, dynamic task, TaskProvider taskProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8)),
        title: Text("حذف المهمة؟",
          textAlign: TextAlign.right,
          style: GoogleFonts.tajawal(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold)),
        content: Text(
          task.title,
          textAlign: TextAlign.right,
          style: GoogleFonts.tajawal(
            color: const Color(0xFF888888),
            fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("إلغاء",
              style: GoogleFonts.tajawal(
                color: const Color(0xFF666666)))),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              taskProvider.deleteTask(task.id);
            },
            child: Text("حذف",
              style: GoogleFonts.tajawal(
                color: Colors.red,
                fontWeight: FontWeight.bold)))
        ]));
  }

  Widget _buildEmptyState(ThemeProvider theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 60,
              color:
                  theme.isDarkMode
                      ? Colors.white.withOpacity(0.15)
                      : Colors.black.withOpacity(0.15),
            ),
            const SizedBox(height: 14),
            Text(
              _selectedFilter == 'المكتملة'
                  ? 'لا توجد مهام مكتملة'
                  : 'لا توجد مهام حالياً، اضغط + لإضافة مهمة',
              style: GoogleFonts.tajawal(
                color: theme.textSecondary,
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context, String uid) {
    if (uid.isEmpty) return;

    final nameController = TextEditingController();
    IconData selectedIcon = Icons.push_pin;
    Color selectedColor = theme.accentColor;
    
    final icons = [
      Icons.push_pin, Icons.menu_book, Icons.work, Icons.track_changes, Icons.fitness_center,
      Icons.palette, Icons.music_note, Icons.directions_run, Icons.apple, Icons.flight
    ];
    final colors = [
      theme.accentColor, const Color(0xFF4FC3F7),
      const Color(0xFF66BB6A), const Color(0xFFAB47BC),
      const Color(0xFFFF5252), const Color(0xFFFFD700),
    ];

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateBuilder) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Text("تصنيف جديد ✨",
            style: GoogleFonts.tajawal(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            )),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                textDirection: TextDirection.rtl,
                style: GoogleFonts.tajawal(
                  color: Colors.white),
                decoration: InputDecoration(
                  hintText: "اسم التصنيف",
                  hintStyle: GoogleFonts.tajawal(
                    color: Colors.grey),
                  fillColor: const Color(0xFF2A2A2A),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: theme.accentColor),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              Text("اختر أيقونة:",
                style: GoogleFonts.tajawal(
                  color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: icons.map((icon) =>
                  GestureDetector(
                    onTap: () => setStateBuilder(() => 
                      selectedIcon = icon),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: selectedIcon == icon
                          ? theme.accentColor.withOpacity(0.2)
                          : const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selectedIcon == icon
                            ? theme.accentColor
                            : Colors.transparent,
                        ),
                      ),
                      child: Icon(icon, color: Colors.white, size: 20),
                    ),
                  )
                ).toList(),
              ),
              
              const SizedBox(height: 16),
              
              Text("اختر لون:",
                style: GoogleFonts.tajawal(
                  color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: colors.map((color) =>
                  GestureDetector(
                    onTap: () => setStateBuilder(() => 
                      selectedColor = color),
                    child: Container(
                      width: 32,
                      height: 32,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selectedColor == color
                            ? Colors.white
                            : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                  )
                ).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("إلغاء",
                style: GoogleFonts.tajawal(
                  color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.accentColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                if (nameController.text.isEmpty) return;
                
                final newCategory = TaskCategory(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text,
                  icon: selectedIcon,
                  color: selectedColor,
                  isCustom: true,
                );

                await DatabaseService().saveCustomCategory(uid, newCategory);
                if (context.mounted) Navigator.pop(context);
              },
              child: Text("حفظ ✅",
                style: GoogleFonts.tajawal(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                )),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeHeaderWidget extends StatelessWidget {
  final String uid;

  const HomeHeaderWidget({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final profile =
        context
            .watch<
              UserModel?
            >(); // Using the unified StreamProvider from main.dart

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                ),
            child: CircleAvatar(
              radius: 26,
              backgroundColor: theme.bg,
              child:
                  profile?.photoUrl != null && profile!.photoUrl.isNotEmpty
                      ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: profile.photoUrl,
                          fit: BoxFit.cover,
                          width: 52, // 2 * radius
                          height: 52, // 2 * radius
                          memCacheWidth: 150,
                          memCacheHeight: 150,
                          placeholder:
                              (context, url) => Container(
                                color:
                                    theme.isDarkMode
                                        ? Colors.white12
                                        : Colors.black12,
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.grey,
                                ),
                              ),
                          errorWidget:
                              (context, url, error) => Container(
                                color:
                                    theme.isDarkMode
                                        ? Colors.white12
                                        : Colors.black12,
                                child: const Icon(
                                  Icons.error,
                                  color: Colors.red,
                                ),
                              ),
                        ),
                      )
                      : Icon(
                        Icons.person,
                        size: 30,
                        color:
                            theme.isDarkMode ? Colors.white54 : Colors.black54,
                      ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'أهلاً،',
                  style: GoogleFonts.tajawal(
                    color: theme.textSecondary,
                    fontSize: 14,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      profile?.name ?? '...',
                      style: GoogleFonts.tajawal(
                        color: theme.primaryText,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (uid.isNotEmpty)
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData || snapshot.data?.data() == null) {
                            return const SizedBox.shrink();
                          }
                          
                          final data = snapshot.data!.data() as Map<String, dynamic>;
                          final isPremium = data['isPremium'] == true;
                          final isAdmin = data['isAdmin'] == true;

                          if (isAdmin) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.accentColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.admin_panel_settings, size: 12, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text(
                                    "مشرف",
                                    style: GoogleFonts.tajawal(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          } else if (isPremium) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD700),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star, size: 12, color: Colors.black),
                                  const SizedBox(width: 4),
                                  Text(
                                    "مشترك",
                                    style: GoogleFonts.tajawal(
                                      color: Colors.black,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            return GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(context, '/schedule');
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  border: Border.all(color: theme.accentColor),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.info_outline, size: 12, color: theme.accentColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      "غير مشترك",
                                      style: GoogleFonts.tajawal(
                                        color: theme.accentColor,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Points Badges
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                // تم زيادة الحشوة من اليسار (left: 14) لمنع حرف "ي" من التداخل مع الإطار
                padding: const EdgeInsets.only(right: 10, left: 14, top: 6, bottom: 6),
                decoration: BoxDecoration(
                  color: theme.accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.accentColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("🔥", style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 6),
                    Text(
                      '${profile?.monthlyPoints ?? 0} شهري',
                      style: GoogleFonts.tajawal(
                        color: theme.accentColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.only(right: 10, left: 14, top: 6, bottom: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFFD700)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("⭐", style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 6),
                    Text(
                      '${profile?.totalPoints ?? 0} إجمالي',
                      style: GoogleFonts.tajawal(
                        color: const Color(0xFFFFD700),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PomodoroCardWidget extends StatelessWidget {
  const PomodoroCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final pomodoro = context.watch<PomodoroProvider>();
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color:
                theme.isDarkMode
                    ? Colors.white.withOpacity(0.03)
                    : Colors.black.withOpacity(0.02), // Glassmorphism base softer
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color:
                  theme.isDarkMode
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.05),
            ),
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
                      Text(
                        pomodoro.isRestMode ? '☕ استراحة' : '⏱ جلسة تركيز',
                        style: GoogleFonts.tajawal(
                          color:
                              pomodoro.isRestMode
                                  ? Colors.cyan
                                  : theme.textSecondary,
                          fontSize: 13,
                          fontWeight:
                              pomodoro.isRestMode
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        pomodoro.timeDisplay,
                        style: GoogleFonts.tajawal(
                          color: theme.primaryText,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3,
                          shadows: [
                            Shadow(
                              color: theme.primaryText.withOpacity(0.5),
                              blurRadius: 10,
                            ),
                          ], // Neon timer
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Progress bar inside card
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pomodoro.progress,
                          backgroundColor:
                              theme.isDarkMode
                                  ? Colors.white.withOpacity(0.15)
                                  : Colors.black.withOpacity(0.1),
                          color:
                              pomodoro.isRestMode
                                  ? Colors.cyan
                                  : theme.accentColor,
                          minHeight: 4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () {
                          final authUrl = context.read<AuthService>().currentUser?.uid ?? '';
                          // We need the user's name. In PomodoroCard it's hard to get without provider.
                          // But we can get it inside the sheet if we pass uid.
                          StudyRoomHelper.showEntrySheet(context, theme, authUrl);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: theme.accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: theme.accentColor.withOpacity(0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.people, color: theme.accentColor, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'ادرس مع صديق 👥',
                                style: GoogleFonts.tajawal(
                                  color: theme.accentColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Vertical divider
                Container(
                  width: 1,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  color:
                      theme.isDarkMode
                          ? Colors.white.withOpacity(0.15)
                          : Colors.black.withOpacity(0.1),
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
                        } else if (pomodoro.progress < 1.0) {
                          // Has been paused
                          pomodoro.startTimer();
                        } else {
                          HomePomodoroHelper.showOptions(
                            context,
                            theme,
                            pomodoro,
                          );
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          
                        ),
                        child: Icon(
                          pomodoro.isRunning
                              ? Icons.pause_circle_filled_rounded
                              : Icons.play_circle_fill_rounded,
                          size: 56,
                          color: theme.accentColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: pomodoro.resetTimer,
                      child: Icon(
                        Icons.refresh_rounded,
                        color: theme.textSecondary,
                        size: 26,
                      ),
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
}
class HomeFilterChipsWidget extends StatelessWidget {
  final String label;
  final bool selected;
  final TaskCategory? customCategory;
  final String? uid;
  final ValueChanged<String> onFilterSelected;

  const HomeFilterChipsWidget({
    super.key,
    required this.label,
    required this.selected,
    required this.onFilterSelected,
    this.customCategory,
    this.uid,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return GestureDetector(
      onTap: () => onFilterSelected(label),
      onLongPress:
          customCategory != null && uid != null
              ? () {
                showDialog(
                  context: context,
                  builder:
                      (ctx) => AlertDialog(
                        backgroundColor: theme.card,
                        title: Text(
                          'حذف التصنيف؟',
                          style: GoogleFonts.tajawal(
                            color: theme.primaryText,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        content: Text(
                          'هل تريد حذف تصنيف \'$label\'؟\nسيتم إزالته من جميع المهام',
                          style: GoogleFonts.tajawal(color: theme.textSecondary),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(
                              'إلغاء',
                              style: GoogleFonts.tajawal(color: Colors.grey),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(ctx);
                              await DatabaseService().deleteCustomCategory(
                                uid!,
                                customCategory!.id,
                              );
                              onFilterSelected('الكل');
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'تم حذف التصنيف وتحديث المهام',
                                      style: GoogleFonts.tajawal(),
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF5252),
                            ),
                            child: Text(
                              'حذف',
                              style: GoogleFonts.tajawal(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                );
              }
              : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? theme.accentColor : theme.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                selected
                    ? theme.accentColor
                    : (theme.isDarkMode ? Colors.white12 : Colors.black12),
          ),
          
        ),
        child: Text(
          label,
          style: GoogleFonts.tajawal(
            color: selected ? Colors.white : theme.textSecondary,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class TaskCardWidget extends StatelessWidget {
  final TaskModel task;
  final List<TaskCategory> allCategories;

  const TaskCardWidget({
    super.key,
    required this.task,
    required this.allCategories,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final taskProvider = context.read<TaskProvider>();

    final catColor =
        allCategories
            .firstWhere(
              (c) => c.id == task.category,
              orElse: () => taskCategories.last,
            )
            .color;
    final catIcon =
        allCategories
            .firstWhere(
              (c) => c.id == task.category,
              orElse: () => taskCategories.last,
            )
            .icon;
    final barColor =
        task.isCompleted ? Colors.grey.withOpacity(0.25) : catColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: IntrinsicHeight(
        child: Container(
          decoration: BoxDecoration(
            color: theme.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: barColor.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Removed accent bar for a cleaner border-based approach

                // ── Card content ──
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        // Checkbox
                        SizedBox(
                          width: 26,
                          height: 26,
                          child: Checkbox(
                            value: task.isCompleted,
                            activeColor: theme.accentColor,
                            checkColor: Colors.white,
                            side: BorderSide(
                              color: Colors.grey[600]!,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            onChanged:
                                (_) => taskProvider.toggleTaskStatus(task),
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
                                      child: Icon(
                                        catIcon,
                                        size: 16,
                                        color:
                                            task.isCompleted
                                                ? Colors.grey
                                                : catColor,
                                      ),
                                    ),
                                  Expanded(
                                    child: Text(
                                      task.title,
                                      textAlign: TextAlign.right,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                      style: GoogleFonts.tajawal(
                                        color:
                                            task.isCompleted
                                                ? Colors.grey[600]
                                                : theme.primaryText,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        decoration:
                                            task.isCompleted
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
                                  style: GoogleFonts.tajawal(
                                    color: theme.textSecondary,
                                    fontSize: 12,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              if (task.estimatedMinutes > 0) ...[
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        task.isCompleted
                                            ? Colors.grey.withOpacity(0.1)
                                            : theme.accentColor.withOpacity(
                                              0.15,
                                            ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 12,
                                        color:
                                            task.isCompleted
                                                ? Colors.grey
                                                : theme.accentColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${task.estimatedMinutes} دقيقة',
                                        style: GoogleFonts.tajawal(
                                          color:
                                              task.isCompleted
                                                  ? Colors.grey
                                                  : theme.accentColor,
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
                          child: Icon(
                            Icons.delete_outline_rounded,
                            color:
                                theme.isDarkMode
                                    ? Colors.white.withOpacity(0.22)
                                    : Colors.black.withOpacity(0.4),
                            size: 20,
                          ),
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

class HomePomodoroHelper {
  static Future<void> showOptions(BuildContext context, ThemeProvider theme, PomodoroProvider pomodoro) async {
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

            final activeColor = isFocus ? theme.accentColor : Colors.cyan;

            return Directionality(
              textDirection: TextDirection.rtl,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.bg,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'إعداد الجلسة',
                      style: GoogleFonts.tajawal(
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
                                color: isFocus ? theme.accentColor.withOpacity(0.1) : theme.card,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isFocus ? theme.accentColor : Colors.transparent),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'تركيز 🧠',
                                style: GoogleFonts.tajawal(
                                  color: isFocus ? theme.accentColor : theme.textSecondary,
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
                                style: GoogleFonts.tajawal(
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
                      style: GoogleFonts.tajawal(color: theme.primaryText),
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
                        backgroundColor: theme.accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 8,
                        shadowColor: theme.accentColor.withOpacity(0.5),
                      ),
                      child: Text('ابدأ', style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.bold)),
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
}

class StudyRoomHelper {
  static void showEntrySheet(BuildContext context, ThemeProvider theme, String uid) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.bg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'غرفة الدراسة 📚',
                  style: GoogleFonts.tajawal(
                    color: theme.primaryText,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Card 1: Create room
                GestureDetector(
                  onTap: () async {
                    Navigator.pop(ctx);
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => const Center(child: CircularProgressIndicator()),
                    );
                    
                    try {
                      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
                      final userName = doc.data()?['name'] ?? 'User';
                      final code = await DatabaseService().createStudyRoom(uid, userName);
                      
                      if (context.mounted) {
                        Navigator.pop(context); // pop loading
                        // Navigator.push to StudyRoomScreen
                        Navigator.pushNamed(context, '/study_room', arguments: {'roomCode': code, 'isHost': true});
                      }
                    } catch (e) {
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.card,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.accentColor),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.add_circle, color: theme.accentColor, size: 40),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'إنشاء غرفة جديدة\nابدأ جلسة وادعو صديقك',
                            style: GoogleFonts.tajawal(
                              color: theme.primaryText,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Card 2: Join room
                GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                    _showJoinRoomDialog(context, theme, uid);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.card,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.login, color: Colors.grey, size: 40),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'انضم لغرفة\nأدخل كود الغرفة المكون من 4 أرقام',
                            style: GoogleFonts.tajawal(
                              color: theme.primaryText,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  static void _showJoinRoomDialog(BuildContext context, ThemeProvider theme, String uid) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: theme.card,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            title: Text(
              'الانضمام لغرفة',
              style: GoogleFonts.tajawal(color: theme.primaryText, fontWeight: FontWeight.bold),
            ),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              maxLength: 4,
              style: GoogleFonts.tajawal(color: theme.primaryText, fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '----',
                hintStyle: TextStyle(color: theme.textSecondary.withOpacity(0.5)),
                counterText: '',
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.accentColor)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.accentColor, width: 2)),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('إلغاء', style: GoogleFonts.tajawal(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (controller.text.length != 4) return;
                  final code = controller.text;
                  Navigator.pop(ctx);
                  
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => const Center(child: CircularProgressIndicator()),
                  );
                  
                  try {
                    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
                    final userName = doc.data()?['name'] ?? 'User';
                    final success = await DatabaseService().joinStudyRoom(code, uid, userName);
                    
                    if (context.mounted) {
                      Navigator.pop(context); // pop loading
                      if (success) {
                        Navigator.pushNamed(context, '/study_room', arguments: {'roomCode': code, 'isHost': false});
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('كود غير صحيح أو الغرفة ممتلئة')));
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.accentColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('انضمام', style: GoogleFonts.tajawal(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }
}
