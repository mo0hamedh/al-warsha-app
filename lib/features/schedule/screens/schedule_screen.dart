import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:el_warsha/providers/theme_provider.dart';
import 'package:el_warsha/features/auth/services/auth_service.dart';
import 'package:el_warsha/services/database_service.dart';
import 'package:el_warsha/features/schedule/models/schedule_model.dart';
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

  // One-time fetch instead of a real-time listener — premium status rarely
  // changes mid-session, so there's no need for a persistent WebChannel.
  Future<DocumentSnapshot>? _premiumFuture;
  Stream<WeeklyScheduleModel?>? _scheduleStream;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  void _initStreams(String uid) {
    _premiumFuture ??= FirebaseFirestore.instance.collection('users').doc(uid).get();
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
      premiumFuture: _premiumFuture!,
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
                style: GoogleFonts.tajawal(
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
                style: GoogleFonts.tajawal(fontSize: 14, color: const Color(0xFFAAAAAA)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.accentColor, width: 1),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("📍 نظامنا في الورشة:", style: GoogleFonts.tajawal(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
                    Text("📚 حصاد سنتين من الرحلة:", style: GoogleFonts.tajawal(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      "✅ كتاب الداء والدواء كاملاً\n✅ أجزاء من كتاب الفوائد\n✅ رحلة في مدارج السالكين\n✅ دراسة في التوحيد\n✅ السيرة النبوية (مرتين)\n✅ كتاب عدة الصابرين\n✅ تفسير سورة الحشر",
                      style: GoogleFonts.tajawal(fontSize: 13, color: const Color(0xFFAAAAAA), height: 1.8),
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
                    style: GoogleFonts.tajawal(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "قليلٌ دائم خيرٌ من كثيرٍ منقطع 🌱",
                style: GoogleFonts.tajawal(fontSize: 13, color: const Color(0xFF666666), fontStyle: FontStyle.italic),
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
          Expanded(child: Text(text, style: GoogleFonts.tajawal(color: Colors.white, fontSize: 13))),
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
         borderRadius: BorderRadius.circular(24), // Premium soft border radius
         boxShadow: [
           BoxShadow(
             color: Colors.black.withValues(alpha: 0.2),
             blurRadius: 20,
             offset: const Offset(0, 8),
           ),
         ],
       ),
       child: Row(
         textDirection: TextDirection.rtl,
         children: [
           Expanded(
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text('شهر ${schedule.month} - أسبوع ${schedule.weekNumber}', style: GoogleFonts.tajawal(color: theme.textSecondary, fontSize: 16)),
                 const SizedBox(height: 8),
                 Text('جدول الورشة 📋', style: GoogleFonts.tajawal(color: theme.primaryText, fontSize: 24, fontWeight: FontWeight.bold)),
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
                   strokeWidth: 6, // Slighly thinner, more elegant
                   backgroundColor: theme.bg,
                   color: theme.accentColor,
                 ),
               ),
               Text('${rate.toStringAsFixed(0)}%', style: GoogleFonts.tajawal(color: theme.accentColor, fontSize: 22, fontWeight: FontWeight.bold, shadows: [Shadow(color: theme.accentColor.withValues(alpha: 0.5), blurRadius: 10)])),
             ],
           ),
         ],
       ),
     );
  }
}

class _PremiumGate extends StatelessWidget {
  final Future<DocumentSnapshot> premiumFuture;
  final ThemeProvider theme;
  final Widget lockedChild;
  final Widget Function() unlockedBuilder;

  const _PremiumGate({
    required this.premiumFuture,
    required this.theme,
    required this.lockedChild,
    required this.unlockedBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: premiumFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: theme.bg,
            body: Center(child: CircularProgressIndicator(color: theme.accentColor)),
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
          style: GoogleFonts.tajawal(color: theme.primaryText, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: tabController,
          indicatorColor: theme.accentColor,
          labelColor: theme.accentColor,
          unselectedLabelColor: theme.textSecondary,
          labelStyle: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 16),
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

// ---------------------------------------------------------------------------
// Static in-memory cache: survives widget rebuilds and tab switches.
// ---------------------------------------------------------------------------
WeeklyScheduleModel? _cachedSchedule;
ScheduleProgressModel? _cachedProgress;

class _ScheduleBodyState extends State<_ScheduleBody> {
  Stream<ScheduleProgressModel?>? _progressStream;
  String? _lastWeekId;

  // 300 ms delay guard — only show skeleton if loading takes > 300 ms
  bool _showSkeleton = false;

  @override
  void initState() {
    super.initState();
    // If we have no cache yet, arm a 300 ms timer to show the skeleton.
    if (_cachedSchedule == null) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && _cachedSchedule == null) {
          setState(() => _showSkeleton = true);
        }
      });
    }
  }

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
        // Update cache whenever new data arrives
        if (scheduleSnap.hasData) {
          _cachedSchedule = scheduleSnap.data;
        }

        final bool scheduleLoading =
            scheduleSnap.connectionState == ConnectionState.waiting && _cachedSchedule == null;

        // --- Show skeleton while waiting (only after 300 ms guard) ----------
        if (scheduleLoading) {
          if (_showSkeleton) {
            return _ScheduleSkeletonLoader(theme: widget.theme);
          }
          // 300 ms hasn't elapsed yet — show nothing (transparent placeholder)
          return const SizedBox.shrink();
        }

        // Once we have data, dismiss the skeleton flag
        if (_showSkeleton) _showSkeleton = false;

        final activeSchedule = _cachedSchedule;
        if (activeSchedule == null) {
          return Center(
            child: Text(
              'لا يوجد جدول نشط حالياً',
              style: GoogleFonts.tajawal(color: widget.theme.textSecondary, fontSize: 18),
            ),
          );
        }

        _initProgressStream(activeSchedule.id);

        return StreamBuilder<ScheduleProgressModel?>(
          stream: _progressStream,
          builder: (ctx2, progressSnap) {
            // Update progress cache
            if (progressSnap.hasData) {
              _cachedProgress = progressSnap.data;
            }

            final progress = _cachedProgress;

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

// ---------------------------------------------------------------------------
// Skeleton loading widget — mirrors the layout of the actual schedule screen.
// Uses a gentle opacity pulse. No external packages required.
// ---------------------------------------------------------------------------
class _ScheduleSkeletonLoader extends StatefulWidget {
  final ThemeProvider theme;
  const _ScheduleSkeletonLoader({required this.theme});

  @override
  State<_ScheduleSkeletonLoader> createState() => _ScheduleSkeletonLoaderState();
}

class _ScheduleSkeletonLoaderState extends State<_ScheduleSkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _opacity = Tween<double>(begin: 0.35, end: 0.75).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (_, __) => Opacity(
        opacity: _opacity.value,
        child: _buildSkeletonContent(),
      ),
    );
  }

  Widget _buildSkeletonContent() {
    return Column(
      children: [
        // ── Header card skeleton ──────────────────────────────────────────
        _SkeletonContainer(
          margin: const EdgeInsets.all(16),
          height: 110,
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _SkeletonBox(width: 140, height: 14),
                    const SizedBox(height: 12),
                    _SkeletonBox(width: 200, height: 22),
                  ],
                ),
              ),
              // circular progress placeholder
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFC5A87C).withOpacity(0.25),
                    width: 6,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Day navigation row skeleton ───────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SkeletonBox(width: 36, height: 36, radius: 10),
              Column(
                children: [
                  _SkeletonBox(width: 80, height: 18),
                  const SizedBox(height: 6),
                  _SkeletonBox(width: 60, height: 12),
                ],
              ),
              _SkeletonBox(width: 36, height: 36, radius: 10),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── Habit rows skeleton ───────────────────────────────────────────
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 7,
            separatorBuilder: (_, __) => const Divider(
              color: Color(0xFF1E1E1E),
              height: 1,
              indent: 48,
            ),
            itemBuilder: (_, index) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  // checkbox circle
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF444444), width: 2),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // icon placeholder
                  _SkeletonBox(width: 22, height: 22, radius: 4),
                  const SizedBox(width: 10),
                  // name placeholder — vary widths for realism
                  _SkeletonBox(width: 120.0 + (index % 3) * 30, height: 14),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Reusable skeleton building block ─────────────────────────────────────────

class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const _SkeletonBox({required this.width, required this.height, this.radius = 6});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF333333),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _SkeletonContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? margin;
  final double? height;

  const _SkeletonContainer({required this.child, this.margin, this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}
