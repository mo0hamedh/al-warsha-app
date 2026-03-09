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

  int _getDaysRemaining() {
    final now = DateTime.now();
    final lastDayThisMonth = DateTime(now.year, now.month + 1, 0);
    return lastDayThisMonth.day - now.day;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

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
          'متصدرو التطبيق 🏆',
          style: GoogleFonts.ibmPlexSansArabic(
            color: theme.primaryText,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: theme.accentOrange.withOpacity(0.5), blurRadius: 10)],
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.accentOrange,
          labelColor: theme.accentOrange,
          unselectedLabelColor: theme.textSecondary,
          labelStyle: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold, fontSize: 16),
          tabs: const [
            Tab(text: 'شهري 🔥'),
            Tab(text: 'إجمالي ⭐'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLeaderboardTab(theme, 'monthlyPoints'),
          _buildLeaderboardTab(theme, 'totalPoints'),
        ],
      ),
    );
  }

  Widget _buildLeaderboardTab(ThemeProvider theme, String field) {
    return Column(
      children: [
        if (field == 'monthlyPoints')
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: theme.card,
            child: Text(
              'يتجدد الترتيب بعد ${_getDaysRemaining()} يوم',
              textAlign: TextAlign.center,
              style: GoogleFonts.ibmPlexSansArabic(
                color: theme.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        Expanded(
          child: StreamBuilder<List<UserModel>>(
            stream: _dbService.getTopUsersByField(field),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(color: theme.accentOrange));
              }

              final topUsers = snapshot.data ?? [];

              if (topUsers.isEmpty) {
                return Center(
                  child: Text(
                    'لا يوجد متصدرين حتى الآن.\nكن أول مبادر! 💪',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.ibmPlexSansArabic(color: theme.textSecondary, fontSize: 16),
                  ),
                );
              }

              return Stack(
                children: [
                   ListView(
                     padding: const EdgeInsets.all(16).copyWith(bottom: 100),
                     children: [
                       _buildTop3Section(topUsers, theme, field),
                       const SizedBox(height: 20),
                       _buildRestOfTop10(topUsers, theme, field),
                     ],
                   ),
                   Positioned(
                     bottom: 0, left: 0, right: 0,
                     child: _buildCurrentUserBanner(topUsers, theme, field),
                   ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTop3Section(List<UserModel> users, ThemeProvider theme, String field) {
     if (users.isEmpty) return const SizedBox.shrink();

     final firstPlace = users.isNotEmpty ? users[0] : null;
     final secondPlace = users.length > 1 ? users[1] : null;
     final thirdPlace = users.length > 2 ? users[2] : null;

     return Row(
       crossAxisAlignment: CrossAxisAlignment.end,
       mainAxisAlignment: MainAxisAlignment.center,
       children: [
         if (secondPlace != null) Expanded(child: _buildPodiumCard(secondPlace, 2, theme, field)),
         if (firstPlace != null) Expanded(flex: 1, child: _buildPodiumCard(firstPlace, 1, theme, field)),
         if (thirdPlace != null) Expanded(child: _buildPodiumCard(thirdPlace, 3, theme, field)),
       ],
     );
  }

  Widget _buildPodiumCard(UserModel user, int rank, ThemeProvider theme, String field) {
    final bool isFirst = rank == 1;
    
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
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: EdgeInsets.symmetric(horizontal: 4, vertical: isFirst ? 20 : 12),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: glowColor.withOpacity(0.5), width: isFirst ? 2 : 1),
        
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(crownIcon, style: TextStyle(fontSize: isFirst ? 28 : 20)),
          const SizedBox(height: 4),
          CircleAvatar(
            radius: isFirst ? 24 : 18,
            backgroundColor: theme.bg,
            backgroundImage: user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
            child: user.photoUrl.isEmpty ? Icon(Icons.person, color: theme.textSecondary, size: isFirst ? 24 : 18) : null,
          ),
          const SizedBox(height: 8),
          Text(
            user.name,
            style: GoogleFonts.ibmPlexSansArabic(color: theme.primaryText, fontSize: isFirst ? 14 : 12, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          ShaderMask(
             shaderCallback: (bounds) => gradient.createShader(bounds),
             child: Text(
               '${field == 'monthlyPoints' ? user.monthlyPoints : user.totalPoints} نقطة',
               style: GoogleFonts.ibmPlexSansArabic(color: Colors.white, fontSize: isFirst ? 16 : 14, fontWeight: FontWeight.w900),
             ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestOfTop10(List<UserModel> users, ThemeProvider theme, String field) {
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
            border: Border.all(color: theme.isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
               SizedBox(
                 width: 30,
                 child: Text('#$rank', style: GoogleFonts.ibmPlexSansArabic(color: theme.textSecondary, fontSize: 16, fontWeight: FontWeight.bold)),
               ),
               CircleAvatar(
                 radius: 18,
                 backgroundColor: theme.bg,
                 backgroundImage: user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
                 child: user.photoUrl.isEmpty ? Icon(Icons.person, color: theme.textSecondary, size: 18) : null,
               ),
               const SizedBox(width: 12),
               Expanded(
                 child: Text(
                   user.name,
                   style: GoogleFonts.ibmPlexSansArabic(color: theme.primaryText, fontSize: 15),
                   maxLines: 1,
                   overflow: TextOverflow.ellipsis,
                 ),
               ),
               Text(
                 '${field == 'monthlyPoints' ? user.monthlyPoints : user.totalPoints} pt',
                 style: GoogleFonts.ibmPlexSansArabic(color: theme.accentOrange, fontSize: 16, fontWeight: FontWeight.bold),
                 textDirection: TextDirection.ltr,
               ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCurrentUserBanner(List<UserModel> topUsers, ThemeProvider theme, String field) {
    final authService = context.watch<AuthService>();
    final currentUser = authService.currentUser;
    if (currentUser == null) return const SizedBox.shrink();

    return StreamBuilder<UserModel?>(
      stream: _dbService.getUserProfile(currentUser.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) return const SizedBox.shrink();
        final me = snapshot.data!;

        int myRank = -1;
        for (int i = 0; i < topUsers.length; i++) {
          if (topUsers[i].id == me.id) {
            myRank = i + 1;
            break;
          }
        }

        String message;
        Color bannerColor = theme.accentOrange;
        int points = field == 'monthlyPoints' ? me.monthlyPoints : me.totalPoints;

        if (myRank != -1) {
          message = '🔥 أنت من أفضل المتصدرين! (المركز $myRank) استمر!';
        } else {
          int pointsNeeded = 1; 
          if (topUsers.isNotEmpty) {
             final lowestTop10Score = field == 'monthlyPoints' ? topUsers.last.monthlyPoints : topUsers.last.totalPoints;
             pointsNeeded = lowestTop10Score - points + 1;
             if (pointsNeeded <= 0) pointsNeeded = 1;
          }
           message = '💪 $points نقطة. تحتاج إلى $pointsNeeded نقطة إضافية لدخول الـ Top 10!';
           bannerColor = theme.card;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
             color: theme.bg, 
             
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: bannerColor == theme.accentOrange ? theme.accentOrange.withOpacity(0.1) : theme.card,
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
                    style: GoogleFonts.ibmPlexSansArabic(
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
}
