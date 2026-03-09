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
  
  Stream<DocumentSnapshot>? _userStream;
  Stream<WeeklyScheduleModel?>? _scheduleStream;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  void _initStreams(String uid) {
    _userStream ??= FirebaseFirestore.instance.collection('users').doc(uid).snapshots();
    _scheduleStream ??= _dbService.getActiveSchedule();
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
    
    _initStreams(user.uid);

    return _PremiumGate(
      userStream: _userStream!,
      theme: theme,
      lockedChild: _buildLockedScreen(theme),
      unlockedBuilder: () => _ScheduleScaffold(
        theme: theme,
        tabController: _tabController,
        userId: user.uid,
        dbService: _dbService,
        scheduleStream: _scheduleStream!,
        buildHeaderCard: _buildHeaderCard,
      ),
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
                  
                  ),
                child: const Icon(Icons.lock, color: Colors.white, size: 50),
              ),
              const SizedBox(height: 24),
              Text(
                "🌿 الـ وَرشة - رحلة حياة",
                style: GoogleFonts.ibmPlexSansArabic(
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
                style: GoogleFonts.ibmPlexSansArabic(fontSize: 14, color: const Color(0xFFAAAAAA)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFF6A00), width: 1),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("📍 نظامنا في الورشة:", style: GoogleFonts.ibmPlexSansArabic(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("📚 حصاد سنتين من الرحلة:", style: GoogleFonts.ibmPlexSansArabic(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      "✅ كتاب الداء والدواء كاملاً\n✅ أجزاء من كتاب الفوائد\n✅ رحلة في مدارج السالكين\n✅ دراسة في التوحيد\n✅ السيرة النبوية (مرتين)\n✅ كتاب عدة الصابرين\n✅ تفسير سورة الحشر",
                      style: GoogleFonts.ibmPlexSansArabic(fontSize: 13, color: const Color(0xFFAAAAAA), height: 1.8),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              InkWell(
                onTap: () async {
                  final url = Uri.parse('https://forms.gle/6SwS2vwRQAtzrEeX7');
                  if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                    debugPrint('Could not launch $url');
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    
                    borderRadius: BorderRadius.circular(8),
                    ),
                  child: Text(
                    "اشترك في الورشة 🚀",
                    style: GoogleFonts.ibmPlexSansArabic(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "قليلٌ دائم خيرٌ من كثيرٍ منقطع 🌱",
                style: GoogleFonts.ibmPlexSansArabic(fontSize: 13, color: const Color(0xFF666666), fontStyle: FontStyle.italic),
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
          Expanded(child: Text(text, style: GoogleFonts.ibmPlexSansArabic(color: Colors.white, fontSize: 13))),
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
         borderRadius: BorderRadius.circular(8),
         border: Border.all(color: theme.accentOrange.withValues(alpha: 0.3)),
         
       ),
       child: Row(
         textDirection: TextDirection.rtl,
         children: [
           Expanded(
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text('شهر ${schedule.month} - أسبوع ${schedule.weekNumber}', style: GoogleFonts.ibmPlexSansArabic(color: theme.textSecondary, fontSize: 16)),
                 const SizedBox(height: 8),
                 Text('جدول الورشة 📋', style: GoogleFonts.ibmPlexSansArabic(color: theme.primaryText, fontSize: 24, fontWeight: FontWeight.bold)),
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
               Text('${rate.toStringAsFixed(0)}%', style: GoogleFonts.ibmPlexSansArabic(color: theme.accentOrange, fontSize: 22, fontWeight: FontWeight.bold, shadows: [Shadow(color: theme.accentOrange.withValues(alpha: 0.5), blurRadius: 10)])),
             ],
           ),
         ],
       ),
     );
  }
}

class _PremiumGate extends StatelessWidget {
  final Stream<DocumentSnapshot> userStream;
  final ThemeProvider theme;
  final Widget lockedChild;
  final Widget Function() unlockedBuilder;

  const _PremiumGate({
    required this.userStream,
    required this.theme,
    required this.lockedChild,
    required this.unlockedBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: userStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return Scaffold(
            backgroundColor: theme.bg,
            body: Center(child: CircularProgressIndicator(color: theme.accentOrange)),
          );
        }

        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final isPremium = data?['isPremium'] == true;

        if (!isPremium) {
          return lockedChild;
        }

        return unlockedBuilder();
      },
    );
  }
}

class _ScheduleScaffold extends StatelessWidget {
  final ThemeProvider theme;
  final TabController tabController;
  final String userId;
  final DatabaseService dbService;
  final Stream<WeeklyScheduleModel?> scheduleStream;
  final Widget Function(WeeklyScheduleModel, ScheduleProgressModel?, ThemeProvider) buildHeaderCard;

  const _ScheduleScaffold({
    required this.theme,
    required this.tabController,
    required this.userId,
    required this.dbService,
    required this.scheduleStream,
    required this.buildHeaderCard,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: theme.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'جدول الورشة 📋',
          style: GoogleFonts.ibmPlexSansArabic(color: theme.primaryText, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: tabController,
          indicatorColor: theme.accentOrange,
          labelColor: theme.accentOrange,
          unselectedLabelColor: theme.textSecondary,
          labelStyle: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold, fontSize: 16),
          tabs: const [
            Tab(text: 'جدولي'),
            Tab(text: 'المنافسة'),
            Tab(text: 'إحصائياتي'),
          ],
        ),
      ),
      body: _ScheduleBody(
        userId: userId,
        dbService: dbService,
        theme: theme,
        tabController: tabController,
        scheduleStream: scheduleStream,
        buildHeaderCard: buildHeaderCard,
      ),
    );
  }
}

class _ScheduleBody extends StatefulWidget {
  final String userId;
  final DatabaseService dbService;
  final ThemeProvider theme;
  final TabController tabController;
  final Stream<WeeklyScheduleModel?> scheduleStream;
  final Widget Function(WeeklyScheduleModel, ScheduleProgressModel?, ThemeProvider) buildHeaderCard;

  const _ScheduleBody({
    required this.userId,
    required this.dbService,
    required this.theme,
    required this.tabController,
    required this.scheduleStream,
    required this.buildHeaderCard,
  });

  @override
  State<_ScheduleBody> createState() => _ScheduleBodyState();
}

class _ScheduleBodyState extends State<_ScheduleBody> {
  Stream<ScheduleProgressModel?>? _progressStream;
  String? _lastWeekId;

  void _initProgressStream(String weekId) {
    if (_lastWeekId != weekId) {
      _lastWeekId = weekId;
      _progressStream = widget.dbService.getUserProgress(widget.userId, weekId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<WeeklyScheduleModel?>(
      stream: widget.scheduleStream,
      builder: (ctx, scheduleSnap) {
        if (scheduleSnap.connectionState == ConnectionState.waiting && !scheduleSnap.hasData) {
          return Center(child: CircularProgressIndicator(color: widget.theme.accentOrange));
        }

        final activeSchedule = scheduleSnap.data;
        if (activeSchedule == null) {
          return Center(
            child: Text(
              'لا يوجد جدول نشط حالياً',
              style: GoogleFonts.ibmPlexSansArabic(color: widget.theme.textSecondary, fontSize: 18),
            ),
          );
        }

        _initProgressStream(activeSchedule.id);

        return StreamBuilder<ScheduleProgressModel?>(
          stream: _progressStream,
          builder: (ctx2, progressSnap) {
            if (progressSnap.connectionState == ConnectionState.waiting && !progressSnap.hasData) {
               return Center(child: CircularProgressIndicator(color: widget.theme.accentOrange));
            }
            
            final progress = progressSnap.data;

            return Column(
              children: [
                widget.buildHeaderCard(activeSchedule, progress, widget.theme),
                Expanded(
                  child: TabBarView(
                    controller: widget.tabController,
                    children: [
                      ScheduleGridTab(schedule: activeSchedule, progress: progress, userId: widget.userId),
                      ScheduleLeaderboardTab(weekId: activeSchedule.id),
                      ScheduleStatsTab(userId: widget.userId, schedule: activeSchedule, progress: progress),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
