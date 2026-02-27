import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/theme_provider.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/user_model.dart';
import '../../models/schedule_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'schedule_grid_tab.dart';
import 'schedule_leaderboard_tab.dart';
import 'schedule_stats_tab.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> with SingleTickerProviderStateMixin {
  final DatabaseService _dbService = DatabaseService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final authService = context.watch<AuthService>();
    final user = authService.currentUser;

    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
         if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: theme.accentOrange));
         
         final data = snapshot.data?.data() as Map<String, dynamic>?;
         final isPremium = data?['isPremium'] == true;

         if (!isPremium) {
            return _buildLockedScreen(theme);
         }

         return Scaffold(
           backgroundColor: theme.bg,
           appBar: AppBar(
             backgroundColor: Colors.transparent,
             elevation: 0,
             centerTitle: true,
             title: Text(
               'جدول الورشة 📋',
               style: GoogleFonts.cairo(color: theme.primaryText, fontSize: 22, fontWeight: FontWeight.bold),
             ),
             bottom: TabBar(
               controller: _tabController,
               indicatorColor: theme.accentOrange,
               labelColor: theme.accentOrange,
               unselectedLabelColor: theme.textSecondary,
               labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
               tabs: const [
                 Tab(text: 'جدولي'),
                 Tab(text: 'المنافسة'),
                 Tab(text: 'إحصائياتي'),
               ],
             ),
           ),
           body: StreamBuilder<WeeklyScheduleModel?>(
             stream: _dbService.getActiveSchedule(),
             builder: (ctx, scheduleSnap) {
                if (scheduleSnap.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: theme.accentOrange));
                
                final activeSchedule = scheduleSnap.data;
                if (activeSchedule == null) {
                   return Center(child: Text('لا يوجد جدول نشط حالياً', style: GoogleFonts.cairo(color: theme.textSecondary, fontSize: 18)));
                }

                return StreamBuilder<ScheduleProgressModel?>(
                  stream: _dbService.getUserProgress(user.uid, activeSchedule.id),
                  builder: (ctx2, progressSnap) {
                     final progress = progressSnap.data;
                     
                     return Column(
                       children: [
                         _buildHeaderCard(activeSchedule, progress, theme),
                         Expanded(
                           child: TabBarView(
                             controller: _tabController,
                             children: [
                               ScheduleGridTab(schedule: activeSchedule, progress: progress, userId: user.uid),
                               ScheduleLeaderboardTab(weekId: activeSchedule.id),
                               ScheduleStatsTab(userId: user.uid, schedule: activeSchedule, progress: progress),
                             ],
                           ),
                         ),
                       ],
                     );
                  }
                );
             },
           ),
         );
      }
    );
  }

  Widget _buildLockedScreen(ThemeProvider theme) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFF6A00)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6A00).withValues(alpha: 0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    )
                  ]
                ),
                child: const Icon(Icons.lock, color: Colors.white, size: 50),
              ),
              const SizedBox(height: 24),
              Text(
                "🌿 الـ وَرشة - رحلة حياة",
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.white.withValues(alpha: 0.5), blurRadius: 10)]
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                "الورشة مش مجرد دروس بنسمعها وخلاص،\nهي رحلة إيمانية يومية هدفها إننا نعيش\nبالدين بجد، ونفضل فاكرين ربنا وسط\nزحمة الحياة 🌿\n\nإحنا مع بعض بقالنا سنتين،\nوبندعوك تشاركنا الطريق ده",
                style: GoogleFonts.cairo(fontSize: 14, color: const Color(0xFFAAAAAA)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFF6A00), width: 1),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("📍 نظامنا في الورشة:", style: GoogleFonts.cairo(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildFeatureRow("بثوث يومية: تذكرة إيمانية متجددة"),
                    _buildFeatureRow("مرونة كاملة: البث مسجل في أي وقت"),
                    _buildFeatureRow("متابعة وتشجيع لكسر حاجز الكسل"),
                    _buildFeatureRow("تحفيز ومسابقات شهرية 🏆"),
                    _buildFeatureRow("أكثر من 300 بث مسجل 📺"),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("📚 حصاد سنتين من الرحلة:", style: GoogleFonts.cairo(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      "✅ كتاب الداء والدواء كاملاً\n✅ أجزاء من كتاب الفوائد\n✅ رحلة في مدارج السالكين\n✅ دراسة في التوحيد\n✅ السيرة النبوية (مرتين)\n✅ كتاب عدة الصابرين\n✅ تفسير سورة الحشر",
                      style: GoogleFonts.cairo(fontSize: 13, color: const Color(0xFFAAAAAA), height: 1.8),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              InkWell(
                onTap: () async {
                  final url = Uri.parse('https://forms.gle/6SwS2vwRQAtzrEeX7');
                  if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                    debugPrint('Could not launch \$url');
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6A00), Color(0xFFFF4500)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6A00).withValues(alpha: 0.4),
                        blurRadius: 15,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      )
                    ]
                  ),
                  child: Text(
                    "اشترك في الورشة 🚀",
                    style: GoogleFonts.cairo(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "قليلٌ دائم خيرٌ من كثيرٍ منقطع 🌱",
                style: GoogleFonts.cairo(fontSize: 13, color: const Color(0xFF666666), fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
            ]
          )
        )
      )
    );
  }

  Widget _buildFeatureRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF66BB6A), size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: GoogleFonts.cairo(color: Colors.white, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(WeeklyScheduleModel schedule, ScheduleProgressModel? progress, ThemeProvider theme) {
     final rate = (progress?.completionRate ?? 0.0) * 100;

     return Container(
       margin: const EdgeInsets.all(16),
       padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
       decoration: BoxDecoration(
         color: theme.card,
         borderRadius: BorderRadius.circular(20),
         border: Border.all(color: theme.accentOrange.withValues(alpha: 0.3)),
         boxShadow: [BoxShadow(color: theme.accentOrange.withValues(alpha: 0.1), blurRadius: 20)],
       ),
       child: Row(
         textDirection: TextDirection.rtl,
         children: [
           Expanded(
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text('شهر ${schedule.month} - أسبوع ${schedule.weekNumber}', style: GoogleFonts.cairo(color: theme.textSecondary, fontSize: 16)),
                 const SizedBox(height: 8),
                 Text('جدول الورشة 📋', style: GoogleFonts.cairo(color: theme.primaryText, fontSize: 24, fontWeight: FontWeight.bold)),
               ],
             ),
           ),
           Stack(
             alignment: Alignment.center,
             children: [
               SizedBox(
                 width: 80, height: 80,
                 child: CircularProgressIndicator(
                   value: progress?.completionRate ?? 0.0,
                   strokeWidth: 8,
                   backgroundColor: theme.bg,
                   color: theme.accentOrange,
                 ),
               ),
               Text('${rate.toStringAsFixed(0)}%', style: GoogleFonts.cairo(color: theme.accentOrange, fontSize: 22, fontWeight: FontWeight.bold, shadows: [Shadow(color: theme.accentOrange.withValues(alpha: 0.5), blurRadius: 10)])),
             ],
           ),
         ],
       ),
     );
  }
}
