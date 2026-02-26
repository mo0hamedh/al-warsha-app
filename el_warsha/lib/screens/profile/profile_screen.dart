import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/user_model.dart';
import '../../providers/theme_provider.dart';
import '../../core/theme/app_theme.dart';

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
        body: Center(child: Text('يجب تسجيل الدخول', style: GoogleFonts.cairo(color: themeProvider.primaryText))),
      );
    }

    return Scaffold(
      backgroundColor: themeProvider.bg,
      appBar: AppBar(
        backgroundColor: themeProvider.bg,
        elevation: 0,
        iconTheme: IconThemeData(color: themeProvider.primaryText),
        title: Text('الملف الشخصي', 
          style: GoogleFonts.cairo(
            color: themeProvider.primaryText, 
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: themeProvider.primaryText.withOpacity(0.5), blurRadius: 8)],
          )),
        centerTitle: true,
        actions: [
          StreamBuilder<UserModel?>(
            stream: _dbService.getUserProfile(user.uid),
            builder: (context, snapshot) {
              int requestsCount = snapshot.data?.friendRequests.length ?? 0;
              return Row(
                children: [
                  IconButton(
                    onPressed: () => _showInboxDialog(context, user.uid, snapshot.data, themeProvider),
                    icon: Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Icon(Icons.mail_outline, color: themeProvider.primaryText),
                        if (requestsCount > 0)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: themeProvider.accentOrange,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$requestsCount',
                              style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.settings_outlined, color: themeProvider.primaryText),
                    onPressed: () => _showSettingsDialog(context, user.uid, snapshot.data, themeProvider),
                  ),
                ],
              );
            },
          )
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
                    style: GoogleFonts.cairo(color: Colors.redAccent, fontSize: 15),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: _accentOrange));
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
                      style: GoogleFonts.cairo(color: _primaryWhite, fontSize: 16),
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
                      label: Text('إنشاء الملف', style: GoogleFonts.cairo()),
                      style: ElevatedButton.styleFrom(backgroundColor: _accentOrange, foregroundColor: Colors.white),
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
          style: GoogleFonts.cairo(
            color: theme.primaryText, 
            fontSize: 22, 
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: theme.primaryText.withOpacity(0.4), blurRadius: 6)], // Neon
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(userProfile.email, style: GoogleFonts.cairo(color: theme.textSecondary, fontSize: 13)),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: userProfile.inviteCode));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('تم نسخ كود الدعوة!', style: GoogleFonts.cairo()),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: theme.card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: theme.accentOrange.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.copy, size: 14, color: theme.accentOrange),
                const SizedBox(width: 8),
                Text(
                  'كود الدعوة: ${userProfile.inviteCode}',
                  style: GoogleFonts.tajawal(color: theme.accentOrange, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatistics(UserModel userProfile, ThemeProvider theme) {
    final focusHours = (userProfile.totalFocusMinutes / 60).toStringAsFixed(1);

    return StreamBuilder<int>(
      stream: _dbService.getCompletedTasksCount(userProfile.id),
      builder: (context, snapshot) {
        final completedCount = snapshot.data ?? 0;
        return Row(
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
        );
      },
    );
  }

  Widget _buildStatCard({required String title, required String value, required IconData icon, required ThemeProvider theme}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.accentOrange, size: 26),
          const SizedBox(height: 10),
          Text(value, style: GoogleFonts.tajawal(color: theme.primaryText, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: GoogleFonts.cairo(color: theme.textSecondary, fontSize: 13)),
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
            Text('لوحة الشرف', style: GoogleFonts.cairo(color: theme.primaryText, fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: () => _showAddFriendDialog(context, userProfile.id, theme),
              icon: Icon(Icons.person_add_outlined, color: theme.accentOrange, size: 16),
              label: Text('إضافة صديق', style: GoogleFonts.cairo(color: theme.accentOrange, fontSize: 13)),
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
                    style: GoogleFonts.cairo(color: theme.textSecondary),
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
                    borderRadius: BorderRadius.circular(14),
                    border: isMe ? Border.all(color: theme.accentOrange, width: 1.5) : Border.all(color: theme.isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    leading: Text(
                      '#${index + 1}',
                      style: GoogleFonts.tajawal(
                        color: index == 0 ? Colors.amber : theme.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    title: Text(
                      isMe ? '${boardUser.name} (أنت)' : boardUser.name,
                      style: GoogleFonts.cairo(color: theme.primaryText, fontWeight: isMe ? FontWeight.bold : FontWeight.normal),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${boardUser.weeklyFocusPoints}', style: GoogleFonts.tajawal(color: theme.accentOrange, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 4),
                        Icon(Icons.local_fire_department, color: theme.accentOrange, size: 18),
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
                            style: GoogleFonts.cairo(
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
                      style: GoogleFonts.tajawal(
                          color: theme.primaryText,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4),
                      decoration: InputDecoration(
                        hintText: 'ادخل كود الدعوة (مثال: AB12CD)',
                        hintStyle:
                            GoogleFonts.cairo(color: theme.textSecondary, fontSize: 13),
                        filled: true,
                        fillColor: theme.bg,
                        contentPadding: const EdgeInsets.all(14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
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
                            style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.accentOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
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
                                  style: GoogleFonts.cairo(
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
                          borderRadius: BorderRadius.circular(14),
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
                                      style: GoogleFonts.cairo(
                                          color: theme.primaryText,
                                          fontWeight: FontWeight.bold)),
                                  Text(
                                    'كود: ${foundUser!.inviteCode}',
                                    style: GoogleFonts.tajawal(
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
                                      style: GoogleFonts.cairo(),
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
                                  Text('إضافة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
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
                        style: GoogleFonts.cairo(
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
                            style: GoogleFonts.cairo(color: theme.textSecondary),
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
                              borderRadius: BorderRadius.circular(14),
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
                                      Text(senderUser.name, style: GoogleFonts.cairo(color: theme.primaryText, fontWeight: FontWeight.bold)),
                                      Text('نقاط التركيز: ${senderUser.weeklyFocusPoints}', style: GoogleFonts.tajawal(color: theme.textSecondary, fontSize: 12)),
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
                        Text('الإعدادات', style: GoogleFonts.cairo(color: theme.primaryText, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Theme Toggle
                    Container(
                      decoration: BoxDecoration(
                        color: theme.bg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: theme.isDarkMode ? Colors.white12 : Colors.black12),
                      ),
                      child: SwitchListTile(
                        value: theme.isDarkMode,
                        onChanged: (val) => theme.toggleTheme(),
                        activeColor: theme.accentOrange,
                        title: Text('الوضع الداكن (Dark Mode)', style: GoogleFonts.cairo(color: theme.primaryText, fontWeight: FontWeight.bold)),
                        secondary: Icon(theme.isDarkMode ? Icons.dark_mode : Icons.light_mode, color: theme.accentOrange),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Edit Form
                    Text('تعديل البيانات', style: GoogleFonts.cairo(color: theme.textSecondary, fontSize: 14)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: nameCtrl,
                      style: GoogleFonts.cairo(color: theme.primaryText),
                      decoration: InputDecoration(
                        labelText: 'الاسم',
                        labelStyle: GoogleFonts.cairo(color: theme.textSecondary),
                        filled: true,
                        fillColor: theme.bg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: photoCtrl,
                      style: GoogleFonts.cairo(color: theme.primaryText),
                      decoration: InputDecoration(
                        labelText: 'رابط الصورة (Photo URL)',
                        labelStyle: GoogleFonts.cairo(color: theme.textSecondary),
                        filled: true,
                        fillColor: theme.bg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: isSaving 
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text('حفظ التعديلات', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
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
}
