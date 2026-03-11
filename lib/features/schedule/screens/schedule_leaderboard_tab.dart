import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:el_warsha/providers/theme_provider.dart';
import 'package:el_warsha/services/database_service.dart';
import 'package:el_warsha/features/auth/services/auth_service.dart';

class ScheduleLeaderboardTab extends StatelessWidget {
  final String weekId;
  const ScheduleLeaderboardTab({super.key, required this.weekId});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final dbService = DatabaseService();
    final authService = context.watch<AuthService>();
    final currentUser = authService.currentUser;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: dbService.getWeeklyLeaderboard(weekId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
           return Center(child: CircularProgressIndicator(color: theme.accentColor));
        }

        final rankings = snapshot.data ?? [];
        if (rankings.isEmpty) {
           return Center(
             child: Text('لا توجد بيانات لهذا الأسبوع بعد', style: GoogleFonts.tajawal(color: theme.textSecondary, fontSize: 16)),
           );
        }

        return Scaffold(
          backgroundColor: theme.bg,
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: rankings.length + 1, // +1 for the header title
              itemBuilder: (context, index) {
                if (index == 0) {
                   return Padding(
                     padding: const EdgeInsets.only(bottom: 16.0),
                     child: Text('🏆 أكثر الملتزمين هذا الأسبوع', style: GoogleFonts.tajawal(color: Colors.amber, fontSize: 22, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.amber.withValues(alpha: 0.5), blurRadius: 10)])),
                   );
                }

                final userRank = rankings[index - 1];
                final isMe = userRank['userId'] == currentUser?.uid;
                final double rate = userRank['completionRate'] ?? 0.0;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: theme.card,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isMe ? theme.accentColor : Colors.transparent, width: isMe ? 2 : 1),
                    
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.bg,
                      backgroundImage: userRank['photoUrl'] != null && userRank['photoUrl'].toString().isNotEmpty 
                          ? NetworkImage(userRank['photoUrl']) 
                          : null,
                      child: userRank['photoUrl'] == null || userRank['photoUrl'].toString().isEmpty 
                          ? Text('$index', style: GoogleFonts.tajawal(color: theme.primaryText, fontWeight: FontWeight.bold)) : null,
                    ),
                    title: Text(isMe ? 'أنت' : userRank['name'], style: GoogleFonts.tajawal(color: theme.primaryText, fontWeight: isMe ? FontWeight.bold : FontWeight.normal)),
                    trailing: SizedBox(
                      width: 100,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('${(rate * 100).toStringAsFixed(0)}%', style: GoogleFonts.tajawal(color: theme.accentColor, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: rate,
                            backgroundColor: theme.bg,
                            color: theme.accentColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
