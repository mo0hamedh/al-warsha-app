import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/theme_provider.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../models/user_model.dart';

class MonthlyLeaderboardScreen extends StatefulWidget {
  const MonthlyLeaderboardScreen({super.key});

  @override
  State<MonthlyLeaderboardScreen> createState() => _MonthlyLeaderboardScreenState();
}

class _MonthlyLeaderboardScreenState extends State<MonthlyLeaderboardScreen> with SingleTickerProviderStateMixin {
  final DatabaseService _dbService = DatabaseService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getCurrentMonthKey() {
    final now = DateTime.now();
    final monthStr = now.month.toString().padLeft(2, '0');
    return '${now.year}-$monthStr';
  }

  int _getDaysRemaining() {
    final now = DateTime.now();
    // Get the first day of next month, then subtract 1 day to get the last day of this month
    final lastDayThisMonth = DateTime(now.year, now.month + 1, 0);
    return lastDayThisMonth.day - now.day;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final currentMonthKey = _getCurrentMonthKey();

    return Scaffold(
      backgroundColor: theme.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: theme.primaryText, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'متصدرو الشهر 🏆',
          style: GoogleFonts.cairo(
            color: theme.primaryText,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: theme.accentOrange.withValues(alpha: 0.5), blurRadius: 10)],
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.accentOrange,
          labelColor: theme.accentOrange,
          unselectedLabelColor: theme.textSecondary,
          labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
          tabs: const [
            Tab(text: 'الشهر الحالي'),
            Tab(text: 'الأرشيف'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCurrentMonthTab(theme, currentMonthKey),
          _buildArchiveTab(theme),
        ],
      ),
    );
  }

  // ── التبويب الأول: الشهر الحالي ───────────────────────────────────────────
  Widget _buildCurrentMonthTab(ThemeProvider theme, String monthKey) {
    return Column(
      children: [
        // Countdown Banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          color: theme.card,
          child: Text(
            'يتجدد الترتيب بعد ${_getDaysRemaining()} يوم',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              color: theme.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _dbService.getMonthlyLeaderboard(monthKey),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(color: theme.accentOrange));
              }

              final topUsers = snapshot.data ?? [];

              if (topUsers.isEmpty) {
                return Center(
                  child: Text(
                    'لا يوجد מתصدرين هذا الشهر حتى الآن.\nكن أول مبادر! 💪',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(color: theme.textSecondary, fontSize: 16),
                  ),
                );
              }

              return Stack(
                children: [
                   ListView(
                     padding: const EdgeInsets.all(16).copyWith(bottom: 100), // padding for current user banner
                     children: [
                       _buildTop3Section(topUsers, theme),
                       const SizedBox(height: 20),
                       _buildRestOfTop10(topUsers, theme),
                     ],
                   ),
                   // Current User Sticky Banner
                   Positioned(
                     bottom: 0, left: 0, right: 0,
                     child: _buildCurrentUserBanner(topUsers, theme),
                   ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTop3Section(List<Map<String, dynamic>> users, ThemeProvider theme) {
     if (users.isEmpty) return const SizedBox.shrink();

     final firstPlace = users.isNotEmpty ? users[0] : null;
     final secondPlace = users.length > 1 ? users[1] : null;
     final thirdPlace = users.length > 2 ? users[2] : null;

     return Row(
       crossAxisAlignment: CrossAxisAlignment.end,
       mainAxisAlignment: MainAxisAlignment.center,
       children: [
         if (secondPlace != null) Expanded(child: _buildPodiumCard(secondPlace, 2, theme)),
         if (firstPlace != null) Expanded(flex: 1, child: _buildPodiumCard(firstPlace, 1, theme)),
         if (thirdPlace != null) Expanded(child: _buildPodiumCard(thirdPlace, 3, theme)),
       ],
     );
  }

  Widget _buildPodiumCard(Map<String, dynamic> user, int rank, ThemeProvider theme) {
    final bool isFirst = rank == 1;
    final double height = isFirst ? 160 : 130;
    
    // Gradients
    final goldGradient = const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)], begin: Alignment.topLeft, end: Alignment.bottomRight);
    final silverGradient = const LinearGradient(colors: [Color(0xFFE0E0E0), Color(0xFF9E9E9E)], begin: Alignment.topLeft, end: Alignment.bottomRight);
    final bronzeGradient = const LinearGradient(colors: [Color(0xFFCD7F32), Color(0xFF8B4513)], begin: Alignment.topLeft, end: Alignment.bottomRight);

    LinearGradient gradient;
    Color glowColor;
    String crownIcon;

    if (rank == 1) { gradient = goldGradient; glowColor = const Color(0xFFFFD700); crownIcon = '👑'; }
    else if (rank == 2) { gradient = silverGradient; glowColor = const Color(0xFFE0E0E0); crownIcon = '🥈'; }
    else { gradient = bronzeGradient; glowColor = const Color(0xFFCD7F32); crownIcon = '🥉'; }

    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: glowColor.withValues(alpha: 0.5), width: isFirst ? 2 : 1),
        boxShadow: isFirst ? [BoxShadow(color: glowColor.withValues(alpha: 0.3), blurRadius: 15, spreadRadius: 2)] : [],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(crownIcon, style: TextStyle(fontSize: isFirst ? 28 : 20)),
          const SizedBox(height: 4),
          CircleAvatar(
            radius: isFirst ? 24 : 18,
            backgroundColor: theme.bg,
            backgroundImage: user['avatarUrl'].toString().isNotEmpty ? NetworkImage(user['avatarUrl']) : null,
            child: user['avatarUrl'].toString().isEmpty ? Icon(Icons.person, color: theme.textSecondary, size: isFirst ? 24 : 18) : null,
          ),
          const SizedBox(height: 8),
          Text(
            user['displayName'].toString(),
            style: GoogleFonts.cairo(color: theme.primaryText, fontSize: isFirst ? 14 : 12, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          ShaderMask(
             shaderCallback: (bounds) => gradient.createShader(bounds),
             child: Text(
               '${user['totalPoints']} نقطة',
               style: GoogleFonts.tajawal(color: Colors.white, fontSize: isFirst ? 16 : 14, fontWeight: FontWeight.w900),
             ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestOfTop10(List<Map<String, dynamic>> users, ThemeProvider theme) {
    if (users.length <= 3) return const SizedBox.shrink();
    
    final restUsers = users.sublist(3);
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: restUsers.length,
      itemBuilder: (context, index) {
        final user = restUsers[index];
        final rank = index + 4;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
               SizedBox(
                 width: 30,
                 child: Text('#$rank', style: GoogleFonts.tajawal(color: theme.textSecondary, fontSize: 16, fontWeight: FontWeight.bold)),
               ),
               CircleAvatar(
                 radius: 18,
                 backgroundColor: theme.bg,
                 backgroundImage: user['avatarUrl'].toString().isNotEmpty ? NetworkImage(user['avatarUrl']) : null,
                 child: user['avatarUrl'].toString().isEmpty ? Icon(Icons.person, color: theme.textSecondary, size: 18) : null,
               ),
               const SizedBox(width: 12),
               Expanded(
                 child: Text(
                   user['displayName'].toString(),
                   style: GoogleFonts.cairo(color: theme.primaryText, fontSize: 15),
                   maxLines: 1,
                   overflow: TextOverflow.ellipsis,
                 ),
               ),
               Text(
                 '${user['totalPoints']} pt',
                 style: GoogleFonts.tajawal(color: theme.accentOrange, fontSize: 16, fontWeight: FontWeight.bold),
                 textDirection: TextDirection.ltr,
               ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCurrentUserBanner(List<Map<String, dynamic>> topUsers, ThemeProvider theme) {
    final authService = context.watch<AuthService>();
    final currentUser = authService.currentUser;
    if (currentUser == null) return const SizedBox.shrink();

    return StreamBuilder<UserModel?>(
      stream: _dbService.getUserProfile(currentUser.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) return const SizedBox.shrink();
        final me = snapshot.data!;

        // 1. Check if I'm in the top 10
        int myRank = -1;
        for (int i = 0; i < topUsers.length; i++) {
          if (topUsers[i]['userId'] == me.id) {
            myRank = i + 1;
            break;
          }
        }

        String message;
        Color bannerColor = theme.accentOrange;

        if (myRank != -1) {
          message = '🔥 أنت من أفضل المتصدرين! (المركز $myRank) استمر!';
        } else {
          // Find points to reach top 10. If top 10 is full, points of the 10th person.
          int pointsNeeded = 1; // Default
          if (topUsers.isNotEmpty) {
             final lowestTop10Score = topUsers.last['totalPoints'] as int;
             pointsNeeded = lowestTop10Score - me.monthlyPoints + 1;
             if (pointsNeeded <= 0) pointsNeeded = 1;
          }
           message = '💪 ${me.monthlyPoints} نقطة. تحتاج إلى $pointsNeeded نقطة إضافية لدخول الـ Top 10!';
           bannerColor = theme.card;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
             color: theme.bg, // Backdrop
             boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), offset: const Offset(0, -4), blurRadius: 10)],
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: bannerColor == theme.accentOrange ? theme.accentOrange.withValues(alpha: 0.1) : theme.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: bannerColor, width: 1.5),
            ),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Icon(Icons.emoji_events, color: bannerColor == theme.card ? theme.textSecondary : theme.accentOrange),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: GoogleFonts.cairo(
                      color: bannerColor == theme.card ? theme.primaryText : theme.accentOrange,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── التبويب الثاني: الأرشيف ──────────────────────────────────────────────
  Widget _buildArchiveTab(ThemeProvider theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.archive_outlined, size: 64, color: theme.textSecondary.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'لم يمر شهر على إطلاق التطبيق بعد.\nسيتم تفعيل الأرشيف قريباً!',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              color: theme.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
