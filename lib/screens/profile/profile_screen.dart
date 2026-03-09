import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:url_launcher/url_launcher.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/user_model.dart';
import '../../providers/theme_provider.dart';
import '../../core/theme/app_theme.dart';
import '../admin/admin_schedule_panel.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final DatabaseService _dbService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    
    // Get current user from auth (no need for Provider here)
    final authService = AuthService();
    final user = authService.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: themeProvider.bg,
        body: Center(child: Text('يجب تسجيل الدخول', style: GoogleFonts.ibmPlexSansArabic(color: themeProvider.primaryText))),
      );
    }

    return Scaffold(
      backgroundColor: themeProvider.bg,
      appBar: AppBar(
        backgroundColor: themeProvider.bg,
        elevation: 0,
        iconTheme: IconThemeData(color: themeProvider.primaryText),
        title: Text('الملف الشخصي', 
          style: GoogleFonts.ibmPlexSansArabic(
            color: themeProvider.primaryText, 
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: themeProvider.primaryText.withOpacity(0.5), blurRadius: 8)],
          )),
        centerTitle: true,
        actions: [
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .get(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();
              final data = snapshot.data!.data() as Map<String, dynamic>?;
              if (data == null) return const SizedBox();
              
              final isAdmin = data['isAdmin'] == true;
              if (!isAdmin) return const SizedBox();
              return IconButton(
                icon: const Icon(
                  Icons.admin_panel_settings,
                  color: Color(0xFFFF6A00),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminSchedulePanel()
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: StreamBuilder<UserModel?>(
          stream: _dbService.getUserProfile(user.uid),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'خطأ في جلب البيانات:\n${snapshot.error}\n\nتحقق من Firestore Rules.',
                    style: GoogleFonts.ibmPlexSansArabic(color: Colors.redAccent, fontSize: 15),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: themeProvider.accentOrange));
            }

            final userProfile = snapshot.data;
            if (userProfile == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      'لم يتم العثور على بيانات المستخدم',
                      style: GoogleFonts.ibmPlexSansArabic(color: themeProvider.primaryText, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await _dbService.createUserDocument(
                          uid: user.uid,
                          email: user.email ?? '',
                          name: user.displayName ?? 'مستخدم جديد',
                          photoUrl: user.photoURL,
                        );
                      },
                      icon: const Icon(Icons.refresh),
                      label: Text('إنشاء الملف', style: GoogleFonts.ibmPlexSansArabic()),
                      style: ElevatedButton.styleFrom(backgroundColor: themeProvider.accentOrange, foregroundColor: Colors.white),
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(userProfile, context, themeProvider),
                  if (userProfile.isPremium) ...[
                    const SizedBox(height: 20),
                    _buildPremiumCard(userProfile, context, themeProvider),
                  ],
                  const SizedBox(height: 28),
                  _buildStatistics(userProfile, themeProvider),
                  const SizedBox(height: 28),
                  _buildLeaderboard(userProfile, themeProvider),
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(UserModel userProfile, BuildContext context, ThemeProvider theme) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 52,
              backgroundColor: theme.card,
              backgroundImage: userProfile.photoUrl.isNotEmpty ? NetworkImage(userProfile.photoUrl) : null,
              child: userProfile.photoUrl.isEmpty
                  ? Icon(Icons.person, size: 52, color: theme.isDarkMode ? Colors.white54 : Colors.black54)
                  : null,
            ),
            Container(
              decoration: BoxDecoration(color: theme.accentOrange, shape: BoxShape.circle),
              child: IconButton(
                icon: const Icon(Icons.edit, size: 18, color: Colors.white),
                onPressed: () => _showSettingsDialog(context, userProfile.id, userProfile, theme),
                constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          userProfile.name,
          style: GoogleFonts.ibmPlexSansArabic(
            color: theme.primaryText, 
            fontSize: 22, 
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: theme.primaryText.withOpacity(0.4), blurRadius: 6)], // Neon
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(userProfile.email, style: GoogleFonts.ibmPlexSansArabic(color: theme.textSecondary, fontSize: 13)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: theme.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.accentOrange.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'كود الدعوة: ${userProfile.inviteCode}',
                style: GoogleFonts.ibmPlexSansArabic(color: theme.accentOrange, fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(width: 12),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.copy, size: 18),
                color: theme.accentOrange,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: userProfile.inviteCode));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تم النسخ ✅', style: GoogleFonts.ibmPlexSansArabic()),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.edit, size: 18),
                color: theme.accentOrange,
                onPressed: () => _showEditInviteCodeDialog(context, userProfile, theme),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumCard(UserModel user, BuildContext context, ThemeProvider theme) {
    final expiry = user.premiumEndDate;
    final daysLeft = expiry != null ? expiry.difference(DateTime.now()).inDays : 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD700)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              
            ),
            child: const Icon(Icons.workspace_premium, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "اشتراكك المميز ⭐",
                  style: GoogleFonts.ibmPlexSansArabic(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                if (expiry != null)
                  Text(
                    "ينتهي في: ${DateFormat('dd/MM/yyyy').format(expiry)}",
                    style: GoogleFonts.ibmPlexSansArabic(color: Colors.grey, fontSize: 12),
                  ),
                Text(
                  daysLeft > 0 ? "متبقي $daysLeft يوم 🕐" : "⚠️ انتهى اشتراكك",
                  style: GoogleFonts.ibmPlexSansArabic(
                    color: daysLeft > 7
                        ? const Color(0xFF66BB6A)
                        : daysLeft > 0
                            ? const Color(0xFFFFD700)
                            : const Color(0xFFFF5252),
                    fontSize: 12,
                  ),
                ),
                if (daysLeft <= 3) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => launchUrl(Uri.parse('https://forms.gle/6SwS2vwRQAtzrEeX7')),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "جدد اشتراكك 🚀",
                        style: GoogleFonts.ibmPlexSansArabic(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics(UserModel userProfile, ThemeProvider theme) {
    final focusHours = (userProfile.totalFocusMinutes / 60).toStringAsFixed(1);

    return StreamBuilder<int>(
      stream: _dbService.getCompletedTasksCount(userProfile.id),
      builder: (context, snapshot) {
        final completedCount = snapshot.data ?? 0;
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'المهام المنجزة',
                    value: '$completedCount',
                    icon: Icons.check_circle_outline,
                    theme: theme,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildStatCard(
                    title: 'ساعات التركيز',
                    value: focusHours,
                    icon: Icons.timer_outlined,
                    theme: theme,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildPointsCard(
                    title: 'نقاط الشهر',
                    value: '${userProfile.monthlyPoints}',
                    subtitle: 'تتصفر أول كل شهر',
                    emoji: '🔥',
                    color: const Color(0xFFFF6A00),
                    theme: theme,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildPointsCard(
                    title: 'إجمالي النقاط',
                    value: '${userProfile.totalPoints}',
                    subtitle: 'مجموع كل نقاطك',
                    emoji: '⭐',
                    color: const Color(0xFFFFD700),
                    theme: theme,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({required String title, required String value, required IconData icon, required ThemeProvider theme}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(8),
        
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.accentOrange, size: 26),
          const SizedBox(height: 10),
          Text(value, style: GoogleFonts.ibmPlexSansArabic(color: theme.primaryText, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: GoogleFonts.ibmPlexSansArabic(color: theme.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildPointsCard({required String title, required String value, required String subtitle, required String emoji, required Color color, required ThemeProvider theme}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(8),
        
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const Spacer(),
              Text(value, style: GoogleFonts.ibmPlexSansArabic(color: theme.primaryText, fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: GoogleFonts.ibmPlexSansArabic(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtitle, style: GoogleFonts.ibmPlexSansArabic(color: theme.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildLeaderboard(UserModel userProfile, ThemeProvider theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text('لوحة الشرف', style: GoogleFonts.ibmPlexSansArabic(color: theme.primaryText, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.people_alt, color: Colors.blueAccent, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        '${userProfile.friends.length}',
                        style: GoogleFonts.ibmPlexSansArabic(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Row(
              children: [
                if (userProfile.friendRequests.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: TextButton.icon(
                      onPressed: () => _showFriendRequestsDialog(context, userProfile, theme),
                      icon: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(Icons.notifications_active, color: Colors.amber, size: 16),
                          Positioned(
                            right: -4, top: -4,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                              child: Text(
                                '${userProfile.friendRequests.length}',
                                style: GoogleFonts.ibmPlexSansArabic(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                      label: Text('طلبات الصداقة', style: GoogleFonts.ibmPlexSansArabic(color: Colors.amber, fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ),
                TextButton.icon(
                  onPressed: () => _showAddFriendDialog(context, userProfile.id, theme),
                  icon: Icon(Icons.person_add_outlined, color: theme.accentOrange, size: 16),
                  label: Text('إضافة صديق', style: GoogleFonts.ibmPlexSansArabic(color: theme.accentOrange, fontSize: 13)),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<UserModel>>(
          stream: _dbService.getLeaderboard([...userProfile.friends, userProfile.id]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: theme.accentOrange));
            }

            final users = snapshot.data ?? [];
            if (users.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'لا يوجد أصدقاء بعد. قم بدعوة أصدقائك!',
                    style: GoogleFonts.ibmPlexSansArabic(color: theme.textSecondary),
                  ),
                ),
              );
            }

            return Column(
              children: users.asMap().entries.map((entry) {
                final index = entry.key;
                final boardUser = entry.value;
                final isMe = boardUser.id == userProfile.id;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: isMe ? theme.accentOrange.withOpacity(0.1) : theme.card,
                    borderRadius: BorderRadius.circular(8),
                    border: isMe ? Border.all(color: theme.accentOrange, width: 1.5) : Border.all(color: theme.isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    leading: Text(
                      '#${index + 1}',
                      style: GoogleFonts.ibmPlexSansArabic(
                        color: index == 0 ? Colors.amber : theme.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    title: Text(
                      isMe ? '${boardUser.name} (أنت)' : boardUser.name,
                      style: GoogleFonts.ibmPlexSansArabic(color: theme.primaryText, fontWeight: isMe ? FontWeight.bold : FontWeight.normal),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${boardUser.weeklyFocusPoints}', style: GoogleFonts.ibmPlexSansArabic(color: theme.accentOrange, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 4),
                        Icon(Icons.local_fire_department, color: theme.accentOrange, size: 18),
                        if (!isMe) ...[
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: theme.card,
                                  title: Text('إزالة صديق؟', style: GoogleFonts.ibmPlexSansArabic(color: theme.primaryText, fontWeight: FontWeight.bold)),
                                  content: Text(
                                    'هل تريد إزالة \'${boardUser.name}\'\nمن قائمة أصدقائك؟',
                                    style: GoogleFonts.ibmPlexSansArabic(color: theme.textSecondary),
                                  ),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: Text('إلغاء', style: GoogleFonts.ibmPlexSansArabic(color: Colors.grey)),
                                    ),
                                    ElevatedButton(
                                      onPressed: () async {
                                        Navigator.pop(ctx);
                                        await _dbService.removeFriend(userProfile.id, boardUser.id);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('تم إزالة الصديق', style: GoogleFonts.ibmPlexSansArabic()),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5252)),
                                      child: Text('إزالة', style: GoogleFonts.ibmPlexSansArabic(color: Colors.white)),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: const Icon(Icons.person_remove, color: Color(0xFFFF5252), size: 20),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  /// ── حوار إضافة صديق بكود الدعوة ──────────────────────────────────────
  void _showFriendRequestsDialog(BuildContext context, UserModel userProfile, ThemeProvider theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.bg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
                    Text('طلبات الصداقة الموجهة إليك', style: GoogleFonts.ibmPlexSansArabic(color: theme.primaryText, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Expanded(
                      child: StreamBuilder<List<UserModel>>(
                        stream: _dbService.getPendingRequests(userProfile.id),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator(color: theme.accentOrange));
                          }
                          final requests = snapshot.data ?? [];
                          if (requests.isEmpty) {
                             return Center(child: Text('لا توجد طلبات صداقة معلقة', style: GoogleFonts.ibmPlexSansArabic(color: theme.textSecondary)));
                          }
                          return ListView.builder(
                            controller: controller,
                            itemCount: requests.length,
                            itemBuilder: (context, index) {
                              final reqUser = requests[index];
                              return Card(
                                color: theme.card,
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: theme.bg,
                                    backgroundImage: reqUser.photoUrl.isNotEmpty ? NetworkImage(reqUser.photoUrl) : null,
                                    child: reqUser.photoUrl.isEmpty ? Icon(Icons.person, color: theme.isDarkMode ? Colors.white54 : Colors.black54) : null,
                                  ),
                                  title: Text(reqUser.name, style: GoogleFonts.ibmPlexSansArabic(color: theme.primaryText, fontWeight: FontWeight.bold)),
                                  subtitle: Text('يريد إضافتك كصديق', style: GoogleFonts.ibmPlexSansArabic(color: theme.textSecondary, fontSize: 12)),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.check_circle, color: Colors.green),
                                        onPressed: () async {
                                          await _dbService.acceptFriendRequest(userProfile.id, reqUser.id);
                                          if (ctx.mounted) Navigator.pop(ctx);
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.cancel, color: Colors.red),
                                        onPressed: () async {
                                          await _dbService.declineFriendRequest(userProfile.id, reqUser.id);
                                          if (ctx.mounted) Navigator.pop(ctx);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        }
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

  void _showAddFriendDialog(BuildContext context, String currentUid, ThemeProvider theme) {
    final TextEditingController codeCtrl = TextEditingController();
    UserModel? foundUser;
    String? errorMsg;
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Padding(
                padding: EdgeInsets.only(
                  top: 28,
                  left: 24,
                  right: 24,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Title ──
                    Row(
                      children: [
                        Icon(Icons.person_add_alt_1, color: theme.accentOrange),
                        const SizedBox(width: 10),
                        Text('إضافة صديق',
                            style: GoogleFonts.ibmPlexSansArabic(
                                color: theme.primaryText,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── Input ──
                    TextField(
                      controller: codeCtrl,
                      textCapitalization: TextCapitalization.characters,
                      style: GoogleFonts.ibmPlexSansArabic(
                          color: theme.primaryText,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4),
                      decoration: InputDecoration(
                        hintText: 'ادخل كود الدعوة (مثال: AB12CD)',
                        hintStyle:
                            GoogleFonts.ibmPlexSansArabic(color: theme.textSecondary, fontSize: 13),
                        filled: true,
                        fillColor: theme.bg,
                        contentPadding: const EdgeInsets.all(14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: theme.accentOrange, width: 1.5),
                        ),
                      ),
                      onChanged: (_) {
                        if (foundUser != null || errorMsg != null) {
                          setModalState(() {
                            foundUser = null;
                            errorMsg = null;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 14),

                    // ── Search button ──
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isLoading
                            ? null
                            : () async {
                                final code = codeCtrl.text.trim();
                                if (code.isEmpty) return;
                                setModalState(() {
                                  isLoading = true;
                                  foundUser = null;
                                  errorMsg = null;
                                });

                                final result =
                                    await _dbService.searchByInviteCode(code);
                                setModalState(() {
                                  isLoading = false;
                                  if (result == null) {
                                    errorMsg = 'لم يتم العثور على مستخدم بهذا الكود.';
                                  } else {
                                    foundUser = result;
                                  }
                                });
                              },
                        icon: isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.search, size: 18),
                        label: Text('بحث',
                            style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.accentOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),

                    // ── Error ──
                    if (errorMsg != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: Colors.redAccent, size: 16),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(errorMsg!,
                                  style: GoogleFonts.ibmPlexSansArabic(
                                      color: Colors.redAccent, fontSize: 13)),
                            ),
                          ],
                        ),
                      ),

                    // ── Found user card ──
                    if (foundUser != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: theme.accentOrange.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: theme.accentOrange.withOpacity(0.4)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: theme.bg,
                              backgroundImage:
                                  foundUser!.photoUrl.isNotEmpty
                                      ? NetworkImage(foundUser!.photoUrl)
                                      : null,
                              child: foundUser!.photoUrl.isEmpty
                                  ? Icon(Icons.person,
                                      color: theme.isDarkMode ? Colors.white54 : Colors.black54)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(foundUser!.name,
                                      style: GoogleFonts.ibmPlexSansArabic(
                                          color: theme.primaryText,
                                          fontWeight: FontWeight.bold)),
                                  Text(
                                    'كود: ${foundUser!.inviteCode}',
                                    style: GoogleFonts.ibmPlexSansArabic(
                                        color: theme.accentOrange, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            // Add button
                            ElevatedButton(
                              onPressed: () async {
                                final err = await _dbService.sendFriendRequest(
                                    currentUid, foundUser!.id);
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      err ?? 'تم إرسال طلب الصداقة إلى ${foundUser!.name}! 📨',
                                      style: GoogleFonts.ibmPlexSansArabic(),
                                    ),
                                    backgroundColor:
                                        err == null ? Colors.green : Colors.redAccent,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.accentOrange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                              child:
                                  Text('إضافة', style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// ── حوار الطلبات المعلقة (Inbox) ──────────────────────────────────────
  void _showInboxDialog(BuildContext context, String currentUid, UserModel? currentUserProfile, ThemeProvider theme) {
    if (currentUserProfile == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.move_to_inbox, color: theme.accentOrange),
                    const SizedBox(width: 10),
                    Text('طلبات الصداقة',
                        style: GoogleFonts.ibmPlexSansArabic(
                            color: theme.primaryText,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: StreamBuilder<List<UserModel>>(
                    stream: _dbService.getPendingRequests(currentUid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator(color: theme.accentOrange));
                      }
                      
                      final users = snapshot.data ?? [];
                      if (users.isEmpty) {
                        return Center(
                          child: Text(
                            'لا توجد طلبات صداقة حالياً.',
                            style: GoogleFonts.ibmPlexSansArabic(color: theme.textSecondary),
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: users.length,
                        shrinkWrap: true,
                        itemBuilder: (context, index) {
                          final senderUser = users[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.bg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: theme.isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: theme.card,
                                  backgroundImage: senderUser.photoUrl.isNotEmpty ? NetworkImage(senderUser.photoUrl) : null,
                                  child: senderUser.photoUrl.isEmpty ? Icon(Icons.person, color: theme.isDarkMode ? Colors.white54 : Colors.black54) : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(senderUser.name, style: GoogleFonts.ibmPlexSansArabic(color: theme.primaryText, fontWeight: FontWeight.bold)),
                                      Text('نقاط التركيز: ${senderUser.weeklyFocusPoints}', style: GoogleFonts.ibmPlexSansArabic(color: theme.textSecondary, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.check_circle, color: Colors.green),
                                      onPressed: () => _dbService.acceptFriendRequest(currentUid, senderUser.id),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.cancel, color: Colors.redAccent),
                                      onPressed: () => _dbService.declineFriendRequest(currentUid, senderUser.id),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
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
  }

  /// ── حوار إعدادات الملف وتغيير الثيم ──────────────────────────────────
  void _showSettingsDialog(BuildContext context, String currentUid, UserModel? userProfile, ThemeProvider theme) {
    if (userProfile == null) return;

    final nameCtrl = TextEditingController(text: userProfile.name);
    final photoCtrl = TextEditingController(text: userProfile.photoUrl);
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Padding(
                padding: EdgeInsets.only(
                  top: 28, left: 24, right: 24,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.settings, color: theme.accentOrange),
                        const SizedBox(width: 10),
                        Text('الإعدادات', style: GoogleFonts.ibmPlexSansArabic(color: theme.primaryText, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Theme Toggle
                    Container(
                      decoration: BoxDecoration(
                        color: theme.bg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: theme.isDarkMode ? Colors.white12 : Colors.black12),
                      ),
                      child: SwitchListTile(
                        value: theme.isDarkMode,
                        onChanged: (val) => theme.toggleTheme(),
                        activeColor: theme.accentOrange,
                        title: Text('الوضع الداكن (Dark Mode)', style: GoogleFonts.ibmPlexSansArabic(color: theme.primaryText, fontWeight: FontWeight.bold)),
                        secondary: Icon(theme.isDarkMode ? Icons.dark_mode : Icons.light_mode, color: theme.accentOrange),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Edit Form
                    Text('تعديل البيانات', style: GoogleFonts.ibmPlexSansArabic(color: theme.textSecondary, fontSize: 14)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: nameCtrl,
                      style: GoogleFonts.ibmPlexSansArabic(color: theme.primaryText),
                      decoration: InputDecoration(
                        labelText: 'الاسم',
                        labelStyle: GoogleFonts.ibmPlexSansArabic(color: theme.textSecondary),
                        filled: true,
                        fillColor: theme.bg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: photoCtrl,
                      style: GoogleFonts.ibmPlexSansArabic(color: theme.primaryText),
                      decoration: InputDecoration(
                        labelText: 'رابط الصورة (Photo URL)',
                        labelStyle: GoogleFonts.ibmPlexSansArabic(color: theme.textSecondary),
                        filled: true,
                        fillColor: theme.bg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : () async {
                          setModalState(() => isSaving = true);
                          final err = await _dbService.updateUserProfile(
                            uid: currentUid,
                            name: nameCtrl.text,
                            photoUrl: photoCtrl.text,
                          );
                          setModalState(() => isSaving = false);
                          if (err != null) {
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: Colors.red));
                            }
                          } else {
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.accentOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: isSaving 
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text('حفظ التعديلات', style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold)),
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

  void _showEditInviteCodeDialog(BuildContext context, UserModel userProfile, ThemeProvider theme) {
    final controller = TextEditingController(text: userProfile.inviteCode);
    String? errorMsg;
    bool isChecking = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: theme.card,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            title: Text("تغيير كود الدعوة",
              style: GoogleFonts.ibmPlexSansArabic(color: theme.primaryText, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "الكود يجب أن يكون 6 أحرف/أرقام إنجليزية كبيرة",
                  style: GoogleFonts.ibmPlexSansArabic(color: theme.textSecondary, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 12),
                
                TextField(
                  controller: controller,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.ltr,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 6,
                  style: GoogleFonts.ibmPlexSansArabic(
                    color: theme.primaryText,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                  decoration: InputDecoration(
                    counterText: "",
                    fillColor: theme.bg,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: errorMsg != null ? const Color(0xFFFF5252) : theme.accentOrange,
                      ),
                    ),
                  ),
                  onChanged: (val) {
                    setState(() {
                      controller.text = val.toUpperCase();
                      controller.selection = TextSelection.fromPosition(
                          TextPosition(offset: controller.text.length));
                      errorMsg = null;
                    });
                  },
                ),
                
                if (errorMsg != null) ...[
                  const SizedBox(height: 8),
                  Text(errorMsg!,
                    style: GoogleFonts.ibmPlexSansArabic(color: const Color(0xFFFF5252), fontSize: 12)),
                ],
                
                if (isChecking) ...[
                  const SizedBox(height: 16),
                  Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: theme.accentOrange,
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("إلغاء", style: GoogleFonts.ibmPlexSansArabic(color: theme.textSecondary)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.accentOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: isChecking ? null : () async {
                  final newCode = controller.text.trim().toUpperCase();
                  
                  if (newCode.length != 6) {
                    setState(() => errorMsg = "الكود لازم يكون 6 أحرف بالظبط");
                    return;
                  }
                  
                  if (!RegExp(r'^[A-Z0-9]+$').hasMatch(newCode)) {
                    setState(() => errorMsg = "أحرف إنجليزية كبيرة وأرقام فقط");
                    return;
                  }
                  
                  if (newCode == userProfile.inviteCode) {
                    setState(() => errorMsg = "الكود ده هو نفس الكود الحالي");
                    return;
                  }
                  
                  setState(() => isChecking = true);
                  
                  final isAvailable = await _dbService.isInviteCodeAvailable(newCode);
                  
                  if (!isAvailable) {
                    setState(() {
                      isChecking = false;
                      errorMsg = "الكود ده مستخدم بالفعل ❌";
                    });
                    return;
                  }
                  
                  await _dbService.updateInviteCode(userProfile.id, newCode);
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("تم تغيير الكود إلى $newCode ✅", style: GoogleFonts.ibmPlexSansArabic()),
                        backgroundColor: const Color(0xFF66BB6A),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                child: Text("حفظ", style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
